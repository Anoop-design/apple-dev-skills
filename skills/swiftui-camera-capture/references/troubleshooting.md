# Camera diagnosis and verification

Inspect the observed failure before changing architecture. Distinguish a device capability limit, permission failure, lifecycle race, session-graph problem, and UI presentation defect.

| Symptom | Evidence to inspect | Likely corrective action |
| --- | --- | --- |
| Termination at first access | Built Info.plist and crash message | Add the required camera/microphone purpose string for the requested access. |
| Black view | Authorization, discovered device, session input/output graph, running/interrupted state, preview bounds/connection | Fix the failing stage; a black preview alone does not identify the cause. |
| UI stalls when entering capture | Main-thread trace around configuration/start | Move blocking session work to its serialized owner. |
| Crash during begin/commit | Concurrent start/stop or an `await` inside configuration | Serialize graph mutation and start/stop; commit before starting. |
| Starts after navigation away | Permission request and task cancellation/lifecycle ordering | Recheck the current requested state after suspension; reject stale work. |
| Duplicate inputs after returning | Configuration state and error rollback | Make setup idempotent; restore a valid graph after failure. |
| Stretched or clipped preview | Layout bounds, video gravity, layer frame updates | Update actual preview geometry; preserve intended crop behavior. |
| Wrong orientation or focus | Active device, rotation coordinator, preview crop and coordinate conversion | Use the initiating preview/device instead of global window or portrait assumptions. |
| Second shot crashes | Settings identity, supported flash/dimensions/quality | Create fresh compatible settings and check current capabilities. |
| Two completions or stuck shutter | Processing-error and terminal callbacks; retained request map | Complete exactly once at the terminal stage and clear state on every path. |
| Capture fails after switching cameras | Output dimensions, formats, rotation, stale device references | Reconfigure controls and capabilities for the new input. |
| Preview fails after interruption | Interruption reason, runtime error, running state, current feature ownership | Recover only when capture remains requested and permitted. |
| Growing memory | Allocations, processor map, observers, large buffers, retained closures | Release completed requests/tokens/resources and fix demonstrated cycles. |
| Thermal interruption | KVO of `systemPressureState`, format/frame-rate cost | Reduce supported workload; do not treat subject-area notifications as pressure updates. |

Use mocks or fixture images for UI states on Simulator. A Simulator placeholder cannot verify physical camera output, rotation, focus, deferred processing, or photo quality. Do not alter view identity to hide a broken session lifecycle.

Choose device checks that cover the feature: first authorization, denial/restriction, rapid entry/exit, backgrounding, interruptions, supported rotations, camera switching, repeated captures, processing failure, and save failure. Record device/OS and which paths actually ran. Inspect actual preview/captured pixels and exported metadata. Physical-device and Photos runtime checks remain necessary even when Swift typechecking passes.

Source: [AVCam](https://developer.apple.com/documentation/avfoundation/avcam-building-a-camera-app) and the [AVFoundation capture APIs](https://developer.apple.com/documentation/avfoundation/capture-setup).
