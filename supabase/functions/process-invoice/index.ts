import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") || "";
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") || "";
const SUPABASE_SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";
const AI_RECEIPT_SCAN_ENABLED = Deno.env.get("AI_RECEIPT_SCAN_ENABLED") === "true";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

function json(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function expenseMonth(date: string) {
  return /^\d{4}-\d{2}-\d{2}$/.test(date) ? date.slice(0, 7) : new Date().toISOString().slice(0, 7);
}

const BILL_PREFIX: Record<string, string> = {
  "Water Bill": "WB",
  "Electricity Bill": "EB",
  "Internet Bill": "INT",
};

const MONTH_LABELS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

function validMonth(value: unknown) {
  const text = String(value || "").trim();
  return /^\d{4}-\d{2}$/.test(text) ? text : "";
}

function previousMonth(date: string) {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) return "";
  const d = new Date(Number(date.slice(0, 4)), Number(date.slice(5, 7)) - 2, 1);
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}`;
}

function normalizedExpenseMonth(ai: Record<string, unknown>) {
  const category = String(ai.category || "");
  const date = String(ai.date || "");
  const explicit = validMonth(ai.expense_month) || validMonth(ai.bill_period_month);
  if (explicit) return explicit;
  if (BILL_PREFIX[category] && date) return previousMonth(date);
  return expenseMonth(date);
}

function monthLabel(month: string) {
  if (!/^\d{4}-\d{2}$/.test(month)) return "";
  const idx = Number(month.slice(5, 7)) - 1;
  if (idx < 0 || idx > 11) return "";
  return `${MONTH_LABELS[idx]} ${month.slice(2, 4)}`;
}

function cleanText(value: unknown) {
  return String(value || "").replace(/\s+/g, " ").trim();
}

function itemNames(items: Array<{ name?: unknown }>) {
  const seen = new Set<string>();
  const names: string[] = [];
  for (const item of items) {
    const name = cleanText(item?.name);
    if (!name) continue;
    const key = name.toLowerCase();
    if (seen.has(key)) continue;
    seen.add(key);
    names.push(name);
    if (names.length >= 3) break;
  }
  return names;
}

function normalizedDescription(ai: Record<string, unknown>, unit: string, month: string) {
  const category = String(ai.category || "");
  const prefix = BILL_PREFIX[category];
  if (!prefix) {
    const merchant = cleanText(ai.merchant_name);
    const invoiceNumber = cleanText(ai.invoice_number || ai.reference_number);
    const summary = cleanText(ai.summary || ai.description || merchant || category || "Receipt");
    const items = Array.isArray(ai.items) ? ai.items as Array<{ name?: unknown }> : [];
    const parts = [summary];
    if (invoiceNumber) parts.push(`Invoice ${invoiceNumber}`);
    const names = itemNames(items);
    if (names.length) parts.push(`Items: ${names.join(", ")}`);
    return parts.join(" | ");
  }
  const parts = [`[${prefix}]`];
  if (unit) parts.push(unit);
  const label = monthLabel(month);
  if (label) parts.push(label);
  return parts.join(" ");
}

async function ensureReceiptsBucket(admin: ReturnType<typeof createClient>) {
  const { data } = await admin.storage.getBucket("receipts");
  if (data) return;
  const { error } = await admin.storage.createBucket("receipts", {
    public: false,
    fileSizeLimit: 10 * 1024 * 1024,
  });
  if (error && !String(error.message || "").toLowerCase().includes("already exists")) {
    throw error;
  }
}

function safeStorageName(value: unknown) {
  const name = String(value || "receipt-scan.jpg")
    .replace(/[^a-zA-Z0-9._-]+/g, "_")
    .replace(/^_+|_+$/g, "");
  return name || "receipt-scan.jpg";
}

function attachmentFolder(type: unknown) {
  const value = String(type || "").trim().toLowerCase();
  return value === "payment-slip" ? "payment-slips" : "receipts";
}

function attachmentPath(userId: string, claimId: unknown, attachmentType: unknown, fileName: unknown) {
  const safeName = safeStorageName(fileName);
  const claimKey = String(claimId || "draft").replace(/[^a-zA-Z0-9._-]+/g, "_") || "draft";
  return `claims/${userId}/${claimKey}/${attachmentFolder(attachmentType)}/${Date.now()}_${safeName}`;
}

function splitAttachmentRefs(value: unknown) {
  return String(value || "").split(",").map((v) => String(v || "").trim()).filter(Boolean);
}

function attachmentStoragePath(ref: unknown) {
  const raw = String(ref || "").trim();
  if (!raw) return "";
  if (!/^https?:\/\//i.test(raw)) return raw;
  try {
    const url = new URL(raw);
    const match = url.pathname.match(/\/storage\/v1\/object\/(?:public|sign|authenticated)\/receipts\/(.+)$/i);
    return match?.[1] ? decodeURIComponent(match[1]) : "";
  } catch {
    return "";
  }
}

function reportChargeBucket(unitName: unknown, chargedTo: unknown) {
  const value = String(chargedTo || "");
  if (value === "Owner" || value === "Operator" || value === "Both") return value;
  if (String(unitName || "") === "MP Office") return "";
  return "Both";
}

async function ownerAccessibleUnits(admin: ReturnType<typeof createClient>, ownerId: string) {
  const { data, error } = await admin
    .from("owner_unit_access")
    .select("unit_name")
    .eq("owner_id", ownerId);
  if (error) throw error;
  return (data || []).map((row) => String(row.unit_name || "").trim()).filter(Boolean);
}

async function ownerAllowedReceiptPaths(admin: ReturnType<typeof createClient>, ownerId: string, requestedPaths: string[]) {
  if (!requestedPaths.length) return true;
  const requested = new Set(requestedPaths);
  const units = await ownerAccessibleUnits(admin, ownerId);
  if (!units.length) return false;
  const { data: claims, error } = await admin
    .from("claims")
    .select("unit, charged_to, status, receipt_refs")
    .in("unit", units)
    .in("status", ["Approved", "Claimed", "Auto-Approved", "Company-Paid"]);
  if (error) throw error;
  const allowed = new Set<string>();
  (claims || []).forEach((claim) => {
    if (reportChargeBucket(claim.unit, claim.charged_to) === "Operator") return;
    splitAttachmentRefs(claim.receipt_refs).forEach((ref) => {
      const path = attachmentStoragePath(ref);
      if (path) allowed.add(path);
    });
  });
  for (const path of requested) {
    if (!allowed.has(path)) return false;
  }
  return true;
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "POST required" }, 405);

  try {
    const authHeader = req.headers.get("Authorization") || "";
    const userClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY || SUPABASE_SERVICE_KEY, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: userData, error: userError } = await userClient.auth.getUser();
    if (userError || !userData.user) return json({ error: "Unauthorized" }, 401);

    const admin = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
    const { data: profile } = await admin
      .from("profiles")
      .select("full_name, role, active")
      .eq("id", userData.user.id)
      .single();
    if (!profile || profile.active === false) return json({ error: "Profile not active" }, 403);

    const body = await req.json();
    const role = String(profile.role || "");
    if (role === "owner" && body.action !== "create-claim-attachment-read-urls") {
      return json({ ok: false, error: "Owner accounts can only read report attachments" }, 403);
    }
    if (body.action === "create-ai-scan-upload") {
      if (!AI_RECEIPT_SCAN_ENABLED) return json({ ok: false, error: "AI receipt scan is currently disabled" }, 403);
      await ensureReceiptsBucket(admin);
      const safeName = safeStorageName(body.fileName);
      const path = `ai-scan/${userData.user.id}/${Date.now()}_${safeName}`;
      const { data, error } = await admin.storage.from("receipts").createSignedUploadUrl(path);
      if (error || !data) return json({ ok: false, error: error?.message || "Failed to prepare AI scan upload" }, 500);
      return json({
        ok: true,
        bucket: "receipts",
        path,
        token: data.token,
        signedUrl: data.signedUrl,
      });
    }

    if (body.action === "create-claim-attachment-upload") {
      await ensureReceiptsBucket(admin);
      const path = attachmentPath(userData.user.id, body.claimId, body.attachmentType, body.fileName);
      const { data, error } = await admin.storage.from("receipts").createSignedUploadUrl(path);
      if (error || !data) {
        return json({ ok: false, error: error?.message || "Failed to prepare claim attachment upload" }, 500);
      }
      return json({
        ok: true,
        bucket: "receipts",
        path,
        token: data.token,
        signedUrl: data.signedUrl,
      });
    }

    if (body.action === "create-claim-attachment-read-urls") {
      await ensureReceiptsBucket(admin);
      const input = Array.isArray(body.paths) ? body.paths : [];
      const paths = input.map((rawPath) => attachmentStoragePath(rawPath)).filter(Boolean);
      if (role === "owner") {
        const ok = await ownerAllowedReceiptPaths(admin, userData.user.id, paths);
        if (!ok) return json({ ok: false, error: "Attachment is not available for this owner report" }, 403);
      }
      const items: Array<{ path: string; signedUrl: string }> = [];
      for (const path of paths) {
        if (!path) continue;
        const { data, error } = await admin.storage.from("receipts").createSignedUrl(path, 3600);
        if (error || !data?.signedUrl) {
          return json({ ok: false, error: error?.message || `Failed to read attachment ${path}` }, 500);
        }
        items.push({ path, signedUrl: data.signedUrl });
      }
      return json({ ok: true, items });
    }

    let fileUrl = body.fileUrl;
    if (!AI_RECEIPT_SCAN_ENABLED) return json({ ok: false, error: "AI receipt scan is currently disabled" }, 403);
    if (body.storagePath) {
      await ensureReceiptsBucket(admin);
      const { data, error } = await admin.storage
        .from("receipts")
        .createSignedUrl(String(body.storagePath), 300);
      if (error || !data?.signedUrl) return json({ ok: false, error: error?.message || "Failed to read AI scan upload" }, 500);
      fileUrl = data.signedUrl;
    }

    const analyzeResp = await fetch(`${SUPABASE_URL}/functions/v1/analyze-receipt`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: authHeader,
        apikey: SUPABASE_ANON_KEY || SUPABASE_SERVICE_KEY,
      },
      body: JSON.stringify({
        base64Data: body.base64Data,
        fileUrl,
        mimeType: body.mimeType,
        unit: body.unit || "",
      }),
    });

    const ai = await analyzeResp.json();
    if (!analyzeResp.ok) return json(ai, analyzeResp.status);

    const selectedUnit = String(body.unit || "").trim();
    const month = normalizedExpenseMonth(ai);
    const descriptionUnit = selectedUnit || String(ai.unit_hint || "").trim();
    ai.expense_month = month;
    ai.description = normalizedDescription(ai, descriptionUnit, month);
    const aiUnitHint = String(ai.unit_hint || "").trim();

    const { data: duplicates } = await admin.rpc("find_possible_duplicate_claims", {
      p_invoice_number: ai.invoice_number || ai.reference_number || "",
      p_merchant_name: ai.merchant_name || "",
      p_amount: Number(ai.total) || 0,
      p_expense_month: month,
      p_emp: profile.full_name || "",
      p_unit: String(body.unit || ""),
    });

    let unitMatch = null;
    const hint = descriptionUnit.toLowerCase();
    if (hint) {
      const { data: units } = await admin
        .from("units")
        .select("id, name, hp_unit_id, property_short, property_name")
        .eq("active", true);
      unitMatch = (units || []).find((u) => {
        const display = `${u.property_short ? `${u.property_short} ` : ""}${u.name}`.toLowerCase();
        return display === hint || String(u.name || "").toLowerCase() === hint || String(u.hp_unit_id || "").toLowerCase() === hint;
      }) || null;
    }

    return json({
      ok: true,
      ai,
      duplicate_claims: duplicates || [],
      suggested: {
        expense_month: month,
        description: ai.description,
        unit: unitMatch
          ? `${unitMatch.property_short ? `${unitMatch.property_short} ` : ""}${unitMatch.name}`
          : descriptionUnit,
        hp_unit_id: unitMatch?.hp_unit_id || null,
        source_type: "ai_scan",
        unit_warning: selectedUnit && aiUnitHint && selectedUnit.toLowerCase() !== aiUnitHint.toLowerCase()
          ? `AI detected unit "${aiUnitHint}" while the form is set to "${selectedUnit}". Please confirm before submit.`
          : "",
      },
    });
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    return json({ ok: false, error: msg }, 500);
  }
});
