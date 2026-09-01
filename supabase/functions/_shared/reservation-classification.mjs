/**
 * HostPlatform booking type 5 is an internal maintenance/block period, not a
 * guest stay. Keep it in reservations for availability history, but exclude it
 * from guest-booking reports and financial calculations.
 */
export function isBillableGuestReservation(reservation) {
  const bookingType = Number(reservation?.booking_type);
  const bookingStatus = String(reservation?.booking_status || "");
  return bookingType !== 5 && bookingType !== 6 && !/Cancel/i.test(bookingStatus);
}
