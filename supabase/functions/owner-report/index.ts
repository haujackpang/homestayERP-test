import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") || "";
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") || "";
const SUPABASE_SERVICE_KEY =
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ||
  Deno.env.get("SUPABASE_SERVICE_KEY") ||
  "";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const MONTH_LABELS: Record<string, string> = {
  "01": "Jan",
  "02": "Feb",
  "03": "Mar",
  "04": "Apr",
  "05": "May",
  "06": "Jun",
  "07": "Jul",
  "08": "Aug",
  "09": "Sep",
  "10": "Oct",
  "11": "Nov",
  "12": "Dec",
};

function json(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function moneyNumber(value: unknown) {
  const n = Number(value || 0);
  return Number.isFinite(n) ? n : 0;
}

function reportChargeBucket(unitName: unknown, chargedTo: unknown) {
  const value = String(chargedTo || "");
  if (value === "Owner" || value === "Operator" || value === "Both") return value;
  if (String(unitName || "") === "MP Office") return "";
  return "Both";
}

function monthLabel(period: string) {
  const mm = period.slice(5, 7);
  return `${MONTH_LABELS[mm] || mm} ${period.slice(0, 4)}`;
}

function nextMonthStart(period: string) {
  const year = Number(period.slice(0, 4));
  const month = Number(period.slice(5, 7));
  const next = new Date(Date.UTC(year, month, 1));
  return `${next.getUTCFullYear()}-${String(next.getUTCMonth() + 1).padStart(2, "0")}-01`;
}

function splitAttachmentRefs(value: unknown) {
  return String(value || "").split(",").map((v) => String(v || "").trim()).filter(Boolean);
}

function ownerClaimRow(row: Record<string, unknown>) {
  return {
    category: String(row.category || "Other"),
    desc: String(row.description || ""),
    amount: moneyNumber(row.amount),
    receiptRefs: splitAttachmentRefs(row.receipt_refs).join(","),
  };
}

function unique(values: string[]) {
  const seen = new Set<string>();
  const out: string[] = [];
  for (const value of values) {
    if (!value || seen.has(value)) continue;
    seen.add(value);
    out.push(value);
  }
  return out;
}

function unitAliases(unit: string, unitRows: Array<Record<string, unknown>>) {
  const out = [unit];
  const match = unit.match(/^[A-Za-z]{2,3}\s+(.+)$/);
  const bare = match?.[1]?.trim() || unit;
  if (bare) out.push(bare);
  for (const row of unitRows) {
    if (row.active === false || row.source !== "hostplatform") continue;
    const mapped = String(row.mapped_unit_name || "").trim();
    const hpName = String(row.name || "").trim();
    const raw = String(row.property_short || "").trim() ? `${String(row.property_short).trim()} ${hpName}` : hpName;
    if ((mapped && mapped === bare) || (hpName && hpName === bare)) out.push(raw);
  }
  return unique(out);
}

async function authOwner(req: Request) {
  const authHeader = req.headers.get("Authorization") || "";
  const userClient = createClient(SUPABASE_URL, SUPABASE_ANON_KEY || SUPABASE_SERVICE_KEY, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: userData, error: userError } = await userClient.auth.getUser();
  if (userError || !userData.user) throw new Error("Unauthorized");

  const admin = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
  const { data: profile, error } = await admin
    .from("profiles")
    .select("id, full_name, role, active")
    .eq("id", userData.user.id)
    .single();
  if (error || !profile || profile.active === false) throw new Error("Profile not active");
  if (profile.role !== "owner") throw new Error("Only owner accounts can use this report");
  return { admin, ownerId: userData.user.id, profile };
}

async function ownerUnits(admin: ReturnType<typeof createClient>, ownerId: string) {
  const { data, error } = await admin
    .from("owner_unit_access")
    .select("unit_name")
    .eq("owner_id", ownerId)
    .order("unit_name");
  if (error) throw error;
  return (data || []).map((row) => String(row.unit_name || "").trim()).filter(Boolean);
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "POST required" }, 405);

  try {
    if (!SUPABASE_URL || !SUPABASE_SERVICE_KEY) return json({ error: "Supabase env not configured" }, 500);
    const { admin, ownerId } = await authOwner(req);
    const body = await req.json();
    const action = String(body.action || "init");
    const units = await ownerUnits(admin, ownerId);

    if (action === "init") return json({ ok: true, units });

    if (action !== "report") return json({ error: "Unknown action" }, 400);

    const unit = String(body.unit || "").trim();
    const period = String(body.period || "").trim();
    if (!unit || !units.includes(unit)) return json({ error: "Unit is not available for this owner" }, 403);
    if (!/^\d{4}-\d{2}$/.test(period)) return json({ error: "Period must be YYYY-MM" }, 400);

    const { data: cfgRows } = await admin
      .from("unit_config")
      .select("owner_name, service_fee_pct, cleaning_fee, laundry_fee")
      .eq("unit_name", unit)
      .limit(1);
    const cfg = (cfgRows && cfgRows[0]) || {};
    const { data: unitRows } = await admin
      .from("units")
      .select("name, source, active, property_short, mapped_unit_name, hp_unit_id");
    const aliases = unitAliases(unit, unitRows || []);
    const hpIds = (unitRows || [])
      .filter((row) => row.active !== false && row.source === "hostplatform" && aliases.includes(String(row.property_short || "").trim() ? `${String(row.property_short).trim()} ${String(row.name || "").trim()}` : String(row.name || "").trim()) && row.hp_unit_id)
      .map((row) => String(row.hp_unit_id || ""));

    const approvedStatuses = ["Approved", "Claimed", "Auto-Approved", "Company-Paid"];
    const { data: claimRows, error: claimError } = await admin
      .from("claims")
      .select("unit, category, description, amount, expense_month, date, charged_to, status, receipt_refs")
      .eq("unit", unit)
      .eq("expense_month", period)
      .in("status", approvedStatuses)
      .order("date");
    if (claimError) throw claimError;

    const shared = (claimRows || []).filter((c) => reportChargeBucket(c.unit, c.charged_to) === "Both");
    const owner = (claimRows || []).filter((c) => reportChargeBucket(c.unit, c.charged_to) === "Owner");

    const { data: reservations, error: reservationError } = await admin
      .from("reservations")
      .select("start_date, end_date, nights, rental, extra_guest, booking_type, booking_status, unit_name, hp_unit_id")
      .gte("end_date", `${period}-01`)
      .lt("end_date", nextMonthStart(period))
      .order("end_date");
    if (reservationError) throw reservationError;

    const activeReservations = (reservations || []).filter((r) => {
      const status = String(r.booking_status || "");
      const unitMatch = aliases.includes(String(r.unit_name || "")) || hpIds.includes(String(r.hp_unit_id || ""));
      return unitMatch && r.booking_type !== 6 && !status.includes("Cancel") && String(r.end_date || "").slice(0, 7) === period;
    });
    const bookingSales = activeReservations.reduce((sum, r) => sum + moneyNumber(r.rental) + moneyNumber(r.extra_guest), 0);
    const cleaningTotal = activeReservations.length * (moneyNumber(cfg.cleaning_fee) + moneyNumber(cfg.laundry_fee));
    const expenses = shared.map(ownerClaimRow);
    if (cleaningTotal > 0) {
      expenses.push({
        category: "Cleaning fee",
        desc: "Booking-based cleaning and laundry",
        amount: cleaningTotal,
        receiptRefs: "",
      });
    }
    const sharedTotal = shared.reduce((sum, c) => sum + moneyNumber(c.amount), 0) + cleaningTotal;
    const homestayProfit = bookingSales - sharedTotal;
    const managementFee = homestayProfit * moneyNumber(cfg.service_fee_pct) / 100;
    const ownerExpenseTotal = owner.reduce((sum, c) => sum + moneyNumber(c.amount), 0);

    return json({
      ok: true,
      report: {
        unit,
        period,
        monthLabel: monthLabel(period),
        ownerName: String(cfg.owner_name || ""),
        booking: {
          count: activeReservations.length,
          sales: bookingSales,
        },
        expenses,
        ownerExpenses: owner.map(ownerClaimRow),
        summary: {
          homestayProfit,
          managementFee,
          ownerExpenses: ownerExpenseTotal,
          ownerProfit: homestayProfit - managementFee - ownerExpenseTotal,
        },
      },
    });
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    const status = msg === "Unauthorized" ? 401 : msg.includes("Only owner") || msg.includes("not active") ? 403 : 500;
    return json({ ok: false, error: msg }, status);
  }
});
