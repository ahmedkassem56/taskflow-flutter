/// Poll tick decision (DESIGN.md §5.2): a 5s tick is skipped when ANY of the
/// following holds — page not visible, a fetch already in flight, a modal
/// dialog/sheet is open, a reorder drag is active, a pointer is down on the
/// list, or an optimistic mutation is in flight.
///
/// Pure so both polling controllers (Items + Share) share one implementation
/// and it can be unit-tested directly.
bool shouldSkipPoll({
  required bool visible,
  required bool inFlight,
  required bool dialogOpen,
  required bool rearrangeActive,
  required bool pointerDown,
  required int mutating,
}) {
  if (!visible) return true;
  if (inFlight) return true;
  if (dialogOpen) return true;
  if (rearrangeActive) return true;
  if (pointerDown) return true;
  if (mutating > 0) return true;
  return false;
}
