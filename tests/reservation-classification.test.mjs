import assert from "node:assert/strict";
import test from "node:test";
import { isBillableGuestReservation } from "../supabase/functions/_shared/reservation-classification.mjs";

test("excludes HostPlatform maintenance blocks from guest reservations", () => {
  assert.equal(isBillableGuestReservation({ booking_type: 5, booking_status: "" }), false);
});

test("keeps guest stays but excludes cancelled and existing type-6 records", () => {
  assert.equal(isBillableGuestReservation({ booking_type: 3, booking_status: "Confirmed" }), true);
  assert.equal(isBillableGuestReservation({ booking_type: 3, booking_status: "Cancelled" }), false);
  assert.equal(isBillableGuestReservation({ booking_type: 6, booking_status: "" }), false);
});
