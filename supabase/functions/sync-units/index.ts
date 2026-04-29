import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// ── Config ──────────────────────────────────────────────────────
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") || "https://afcifzghlkxvnpulahub.supabase.co";
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";
const RESERVATION_EMAIL = Deno.env.get("RESERVATION_EMAIL") || "";
const RESERVATION_PASSWORD = Deno.env.get("RESERVATION_PASSWORD") || "";
const RESERVATION_API_BASE = Deno.env.get("RESERVATION_API_BASE") || "https://nebulapi-asg.hostplatform.com/v1";

const PAGE_SIZE = 20;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

function requireSyncEnv() {
  const missing = [
    !SUPABASE_SERVICE_KEY ? "SUPABASE_SERVICE_ROLE_KEY" : "",
    !RESERVATION_EMAIL ? "RESERVATION_EMAIL" : "",
    !RESERVATION_PASSWORD ? "RESERVATION_PASSWORD" : "",
    !RESERVATION_API_BASE ? "RESERVATION_API_BASE" : "",
  ].filter(Boolean);

  if (missing.length) {
    throw new Error(`Missing required env: ${missing.join(", ")}`);
  }
}

// ── Main ──────────────────────────────────────────────────────

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const sb = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

  try {
    requireSyncEnv();

    // 1. Login to HP API
    const loginResp = await fetch(`${RESERVATION_API_BASE}/auth/session-login`, {
      method: "POST",
      headers: { "Content-Type": "application/json;charset=UTF-8" },
      body: JSON.stringify({
        email: RESERVATION_EMAIL,
        password: RESERVATION_PASSWORD,
        deviceInfo: { userAgent: "HomestayExpenseSync/1.0" },
      }),
    });

    if (!loginResp.ok) {
      throw new Error(`Login failed: ${loginResp.status} ${await loginResp.text()}`);
    }

    const loginData = await loginResp.json();
    const token = loginData.token as string;
    if (!token) throw new Error("No token in login response");

    // 2. Fetch all units via paginated endpoint (propertyName is only populated here)
    const allHpUnits: Record<string, unknown>[] = [];
    let currentPage = 1;
    let totalCount = 0;

    do {
      const pagination = JSON.stringify({ limit: PAGE_SIZE, currentPage });
      const encoded = encodeURIComponent(encodeURIComponent(pagination));
      const url = `${RESERVATION_API_BASE}/unit/paginated?pagination=${encoded}`;

      const resp = await fetch(url, {
        headers: {
          Authorization: token,
          Accept: "application/json, text/plain, */*",
          Referer: "https://system.hostplatform.com/",
          Origin: "https://system.hostplatform.com",
        },
      });

      if (!resp.ok) {
        throw new Error(`Unit page ${currentPage} failed: ${resp.status}`);
      }

      const pageData = await resp.json();
      totalCount = pageData.totalCount || 0;
      const units: Record<string, unknown>[] = pageData.units || [];
      allHpUnits.push(...units);
      currentPage++;
    } while ((currentPage - 1) * PAGE_SIZE < totalCount);

    console.log(`Fetched ${allHpUnits.length} units from HP (totalCount=${totalCount})`);

    // Abort if fetch returned 0 units (safety guard — don't mass-deactivate on API error)
    if (allHpUnits.length === 0) {
      throw new Error("HP returned 0 units — aborting to prevent accidental mass-deactivation");
    }

    // 3. Get existing HP units from DB to detect name changes
    const { data: existingUnits, error: existingUnitsError } = await sb
      .from("units")
      .select("hp_unit_id, name, property_name")
      .eq("source", "hostplatform");
    if (existingUnitsError) {
      throw new Error(`Failed to load existing HostPlatform units: ${existingUnitsError.message}`);
    }
    const writeErrors: string[] = [];

    const existingMap: Record<string, { name: string; property_name: string }> = {};
    if (existingUnits) {
      for (const u of existingUnits) {
        if (u.hp_unit_id) {
          existingMap[u.hp_unit_id] = { name: u.name, property_name: u.property_name };
        }
      }
    }

    // 4. Upsert each HP unit
    const seenHpIds: string[] = [];
    const nameChanges: Array<{ hp_unit_id: string; newName: string }> = [];
    const syncedAt = new Date().toISOString();

    for (const u of allHpUnits) {
      const hpId = u._id as string;
      if (!hpId) continue;

      // HostPlatform UI typically shows `unitName`, while `name` can be an internal label/code.
      // Prefer `unitName` for display consistency, but fall back to `name` when missing.
      const unitName = (u.unitName as string) || (u.name as string) || "";
      const propertyName = (u.propertyName as string) || "";
      const roomType = u.roomType as Record<string, unknown> | undefined;
      const propObj = roomType?.property as Record<string, unknown> | undefined;
      const hpPropertyId = (propObj?._id as string) || "";

      seenHpIds.push(hpId);

      // Detect name changes for downstream claims.unit update
      const existing = existingMap[hpId];
      if (existing && existing.name !== unitName && unitName !== "") {
        nameChanges.push({ hp_unit_id: hpId, newName: unitName });
      }

      const payload = {
        hp_unit_id: hpId,
        name: unitName,
        property_name: propertyName,
        hp_property_id: hpPropertyId,
        source: "hostplatform",
        active: true,
        synced_at: syncedAt,
      };
      const writeQuery = existing
        ? sb.from("units").update(payload).eq("hp_unit_id", hpId)
        : sb.from("units").insert(payload);
      const { error } = await writeQuery;

      if (error) {
        console.error(`Upsert unit ${hpId} (${unitName}):`, error);
        writeErrors.push(`upsert ${unitName || hpId}: ${error.message}`);
      }
    }

    if (writeErrors.length) {
      throw new Error(`Failed to write ${writeErrors.length} HostPlatform unit row(s). First error: ${writeErrors[0]}`);
    }

    // 5. Update claims.unit display name where unit name changed
    for (const change of nameChanges) {
      const { error } = await sb
        .from("claims")
        .update({ unit: change.newName })
        .eq("hp_unit_id", change.hp_unit_id);
      if (error) {
        console.error(`Update claims for unit ${change.hp_unit_id}:`, error);
        writeErrors.push(`claims update ${change.hp_unit_id}: ${error.message}`);
      }
    }

    if (writeErrors.length) {
      throw new Error(`Sync write follow-up failed. First error: ${writeErrors[0]}`);
    }

    // 6. Deactivate HP units no longer returned by the API
    //    Query all hostplatform units from DB, then deactivate those not in seenHpIds
    const { data: allHpDbUnits, error: allHpDbUnitsError } = await sb
      .from("units")
      .select("hp_unit_id")
      .eq("source", "hostplatform");
    if (allHpDbUnitsError) {
      throw new Error(`Failed to load current HostPlatform units: ${allHpDbUnitsError.message}`);
    }

    if (allHpDbUnits && allHpDbUnits.length > 0) {
      const seenSet = new Set(seenHpIds);
      const toDeactivate = allHpDbUnits
        .filter((u) => u.hp_unit_id && !seenSet.has(u.hp_unit_id))
        .map((u) => u.hp_unit_id);

      if (toDeactivate.length > 0) {
        const { error } = await sb
          .from("units")
          .update({ active: false })
          .in("hp_unit_id", toDeactivate);
        if (error) {
          console.error("Deactivate missing units:", error);
          throw new Error(`Failed to deactivate missing HP units: ${error.message}`);
        } else {
          console.log(`Deactivated ${toDeactivate.length} units no longer in HP`);
        }
      }
    }

    return new Response(
      JSON.stringify({
        ok: true,
        synced: allHpUnits.length,
        nameChanges: nameChanges.length,
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    console.error("sync-units error:", msg);

    try {
      await sb.from("error_logs").insert({
        level: "error",
        source: "sync-units",
        message: msg.substring(0, 500),
        details: {},
      });
    } catch { /* ignore */ }

    return new Response(
      JSON.stringify({ ok: false, error: msg }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
