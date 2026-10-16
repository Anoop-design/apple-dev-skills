# Apple Intelligence system UI

Checked 2026-10-16 against Xcode 27.0 (27A266a), Swift 6.4, and the iOS 27 SDK. Availability below is per API, not the skill name.

## Image Playground

Use the SwiftUI environment's `supportsImagePlayground` or UIKit's `ImagePlaygroundViewController.isAvailable`. API availability alone doesn't establish that image generation is usable on the current device.

The sheet exists from iOS 18.1/macOS 15.1, while generation-style selection starts at iOS 18.4/macOS 15.4. There is no `style:` argument on `imagePlaygroundSheet`. The completion URL is temporary: copy the file to app-owned storage before retaining it. Report a failed copy instead of keeping a broken URL.

```swift
import SwiftUI
import ImagePlayground

@available(iOS 18.4, macOS 15.4, *)
struct ImageCreationButton: View {
    @Environment(\.supportsImagePlayground) private var supported
    @State private var presented = false
    let saveImage: (URL) -> Void // Copy the temporary file; surface errors in the host UI.

    var body: some View {
        Button("Create image") { presented = true }
            .disabled(!supported)
            .imagePlaygroundSheet(
                isPresented: $presented,
                concepts: [.text("A mountain sunset")],
                onCompletion: saveImage)
            .imagePlaygroundGenerationStyle(.illustration)
    }
}
```

UIKit uses `ImagePlaygroundViewController.Delegate`, with `imagePlaygroundViewController(_:didCreateImageAt:)` and the optional cancellation callback. A separate `ImagePlaygroundViewControllerDelegate` protocol is not the Swift API. Verify style/options properties in the current SDK before configuring a controller.

`ImageCreator` was introduced in iOS 18.4/macOS 15.4 and is **deprecated in version 27** in favor of the controller or sheet. Preserve compatible existing integrations when appropriate; don't introduce it as the default new implementation. Use the available style list instead of assuming a particular style is always supported.

## Writing Tools

Standard supported text controls integrate with Writing Tools. For a SwiftUI text editor, configure `writingToolsBehavior(_:)` where needed; UIKit has `UITextView.writingToolsBehavior`. Use `.complete` only with compatible text-system behavior and `.limited` for the appropriate panel experience. Disable the feature only when required by the field's semantics.

The UIKit format property is **`allowedWritingToolsResultOptions`**, not `writingToolsAllowedInputOptions`. Its options describe allowed output forms. `UITextView` does not support the `.table` result option; the SDK header warns that setting it raises an exception. `textViewWritingToolsWillBegin` and `textViewWritingToolsDidEnd` help coordinate concurrent app edits; `isWritingToolsActive` indicates an active operation. Don't mutate the text storage in a way that races with the system's editing transaction. There is no universal prohibition on persisting text while Writing Tools is active: choose an autosave/sync strategy that preserves undo, selection, and the final result.

Implement ignored ranges only for content that must stay protected, using `textView(_:writingToolsIgnoredRangesIn:)` and valid ranges in the current attributed string. Test cancellation and undo as well as accepting a result.

## Genmoji / adaptive image glyphs

Preserve attributed content, not just `textView.text`. Genmoji is represented by `NSAdaptiveImageGlyph` in attributed strings; converting to plain text loses its image content. UIKit text views can enable `supportsAdaptiveImageGlyph` with rich-text editing; AppKit uses its corresponding attributed-text support.

Enumerate `.adaptiveImageGlyph` attributes and retain `imageContent`, `contentIdentifier`, and `contentDescription` as appropriate to the storage format. Keep a meaningful accessibility description. Confirm round-trip behavior with the actual serializer, pasteboard, editor, and sync format; don't assume a plain string or arbitrary HTML path preserves it.

Official sources: [Image Playground](https://developer.apple.com/documentation/imageplayground), [Writing Tools](https://developer.apple.com/documentation/uikit/writing-tools), [NSAdaptiveImageGlyph](https://developer.apple.com/documentation/uikit/nsadaptiveimageglyph).
