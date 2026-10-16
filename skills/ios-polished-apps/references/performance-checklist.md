# Performance review

Use the smallest repeatable set of interactions that covers the requested feature’s risks. Measure a Profile/Release build on a representative physical device, record configuration, and compare the same workload after a fix. Simulator results can aid diagnosis but do not establish device performance or battery use.

## Launch and responsiveness

Measure cold/warm launch and main-thread work. A universal 400 ms launch cutoff is not a release rule. Defer nonessential initialization and avoid synchronous network or heavy I/O in the interactive path. `Task`, `.task` and `async` do not automatically move CPU work off the main actor; select an explicit actor/execution strategy where needed and preserve cancellation.

A 60 Hz display has roughly 16.7 ms per frame, a 120 Hz display 8.3 ms, with only part available to app updates. Check actual frame deadlines and hitch durations rather than declaring every app “60 fps ready.” Source: [Improving app responsiveness](https://developer.apple.com/documentation/xcode/improving-app-responsiveness).

## Scrolling and rendering

Use lazy containers for content that benefits, stable identity and appropriately sized image resources. GeometryReader is valid in scrolling content when sizing/dependencies are controlled; look for feedback loops or unnecessary updates rather than banning it. Profile repeated sorting/filtering and cache only with correct initialization and invalidation.

For example, a cached count initialized to zero must also be computed for initial content. On iOS 17+, `.onChange(of: items, initial: true)` can refresh an Equatable data-derived value; older systems need an initial computation too. Prefer a model-owned derived value when this avoids view lifecycle duplication. Display counts with tabular digits and reserve their supported width.

`AsyncImage` provides asynchronous remote-image loading, but does not itself promise the application’s desired memory/disk cache policy. Choose a loader/cache when reuse, downsampling or request coalescing is part of the requirement. Source: [AsyncImage](https://developer.apple.com/documentation/swiftui/asyncimage).

## Resources and storage

Inspect sustained growth, retain cycles, task/timer lifetimes and bounded caches. A disappearing view should cancel work owned only by that view; a shared transfer or save may intentionally outlive it. Check network caching, offline behavior and bounded retries for idempotent requests. Pause unnecessary visual/timer/location work when inactive.

Put regenerable or redownloadable data in Caches, temporary data in temporary storage, and irreplaceable user/app data in an appropriate durable directory. File size alone does not determine the directory. Do not relocate user data to a purgeable cache for a performance cleanup. Source: [File system programming guide](https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/FileSystemOverview/FileSystemOverview.html).

Choose Instruments by the measured symptom: Time Profiler, SwiftUI, Animation Hitches, Allocations, Leaks, networking or power tools available in the active toolchain. Record residual gaps, including physical-device tests not run.
