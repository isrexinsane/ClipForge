# Epic 10 — Performance Optimization

**Status:** ⬜ Not Started

## Scope

Optimize for speed, memory, and battery efficiency. Goal: end-to-end flow (paste link → trim → export GIF) under 30 seconds on network + under 5 seconds encoding on device.

- **Video download:** Streaming with progress UI, background URLSession
- **GIF encoding:** Background task (ProcessInfo.processInfo.beginActivity)
- **Memory:** Video frame cache limits, GIF palette optimization
- **Battery:** Reduce AVPlayerItem frame rate during preview, disable animated preview during trim
- **Profiling:** Instruments (Time Profiler, Allocations, Core Animation)

## Dependencies

- All previous epics (3–8) complete before optimization

## Wikilinks

- [[Architecture_Spec]] — Performance architecture
- [[Epic_Breakdown]] — Full plan
- [[Dashboard]] — Sprint tracking

## Notes

Leave for late-stage optimization. Focus on correctness first, speed second.
