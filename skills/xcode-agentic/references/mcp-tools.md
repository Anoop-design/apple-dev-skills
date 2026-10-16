# Discover and use Xcode tools

Checked 2026-10-16 against Xcode 27.0 (27A266a), Swift 6.4, and the iOS 27 SDK. Availability below is per API, not the skill name.

Use the connected server's advertised tool names, parameter schemas, descriptions, and permission boundaries. Names below are examples from Xcode integrations, not a promise that every server exposes them.

1. Enumerate the available tools using the client's supported discovery mechanism.
2. Use the window/workspace listing capability (often `XcodeListWindows`) and match the actual project path. A process ID does not itself identify a unique workspace or tab.
3. Supply the returned tab/window identifier where the selected tool requires it. Read the active scheme and destination when the operation depends on them.
4. Execute the scoped operation and inspect the structured result, diagnostics, and relevant logs. Tool success is not automatically build/test success.

| Need | Capability to discover |
|---|---|
| Files | Read, search, edit, and project membership operations |
| Build | Build and diagnostic log retrieval (for example `BuildProject`, `GetBuildLog`) |
| Tests | Test inventory, selected-test or full-test execution |
| Previews | Render a preview and inspect the returned artifact |
| Diagnostics | Navigator issues or per-file diagnostics |
| Documentation | Search Apple documentation available to the tool |
| Run/debug/device | Only operations actually advertised by the connected release |

Prefer IDE-aware operations when they preserve project membership or use live build state needed for the task. Ordinary source-file edits and headless builds can use normal filesystem/CLI tools. Don't force unavailable MCP operations or claim raw CLI results are invalid.

Never assume preview tools support arbitrary appearance, orientation, widget timeline, or Dynamic Type overrides. Read the exact schema; use existing preview definitions or supported inputs to express a variant. A rendered image must be inspected before it counts as visual evidence.

For schemes, build settings, entitlements, localization, Organizer reports, debugger access, simulator input, or Instruments, discover current support. Earlier versions expose different subsets. Absence from an old catalog does not establish that a capability is permanently unavailable.

Official sources: [Giving external agents access to Xcode](https://developer.apple.com/documentation/xcode/giving-external-agents-access-to-xcode), [Xcode 27 release notes](https://developer.apple.com/documentation/xcode-release-notes/xcode-27-release-notes).
