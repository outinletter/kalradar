# Korean Air official published timetable responses

The compressed JSON archive preserves original public responses, exact request URLs,
collection time, the departure-airport list and the route graph used for collection.
The current route graph describes the next 30 days; it is not an all-season route list.
Queries cover 2026-10-28 (winter) and 2027-07-01 (summer) for that graph.
These are verified published schedule snapshots, **not complete seasonal originals**.
Past summer 2026 data and routes absent from the current graph are not covered.
A `DX.39360` response means the official service reported no flight for that query;
other service errors are not treated as an empty schedule.

Source UI: https://www.koreanair.com/flight-status?hl=ko
Route UI: https://www.koreanair.com/booking/reservation-guide/route-map?hl=ko

The importer retains explicit validity periods and only direct KE-marketed flights
operated by Korean Air (or with no different operator specified by the source).
It excludes connections and other airlines' codeshares, deduplicates flight/route
within each validity period, and does not infer ADS-B callsigns or aircraft positions.
Original times and operating days remain in the archive; the app's compact list
uses flight number, origin and destination only.

From the KALRadar root, rebuild the bundled catalogue with:

```
node Web/scripts/import-official-schedules.mjs Web/sources/korean-air/2026-10-28.json.gz
node Scripts/generate-project.js
node Web/scripts/build.mjs
```

Keep user-imported seasons and independently acquired complete seasonal originals.
Regenerate and verify both platforms before publishing. Never label this archive
as a complete summer/winter timetable.
