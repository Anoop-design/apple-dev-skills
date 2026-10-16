# Export and use Apple-provided skills

Checked 2026-10-16 against Xcode 27.0 (27A266a), Swift 6.4, and the iOS 27 SDK. Availability below is per API, not the skill name.

Inspect the installed command before exporting:

```sh
xcrun agent skills export --help
xcrun agent skills export --output-dir ./xcode-skills
```

The checked CLI provides `--output-dir` and `--replace-existing`. Use a separate inspection directory first. `--replace-existing` can overwrite installed customizations; use it only for an intended replacement after inspecting the destination. Export may require a running Xcode service even though `--help` works without it.

The exported catalog can change with Xcode. List the files and read descriptions rather than relying on a fixed count or copying a beta-era inventory. Typical areas include SwiftUI, testing, UIKit modernization, build security, and device interaction. Some guidance is portable prose; some depends on Xcode-specific tools or execution conventions. Verify each dependency before adopting it in another agent.

An export is a snapshot. Review relevant changes after an Xcode update, then update only the intended installed copies. Do not automatically export over every user's skill directory on each build.

## Project guidance

Keep project facts such as scheme names, supported destinations, repository conventions, and relevant commands in project instructions. Keep a reusable skill narrow and task-specific; don't encode one team's architecture preference as a universal Apple rule.

A skill entrypoint uses YAML frontmatter with `name` and `description`, then instructions and optional referenced resources. Agent runtimes differ in optional metadata, tools, and configuration formats; use their documentation instead of asserting that one extension field is universally accepted or forbidden.

Apple's exported material retains its own terms. Exporting for local use does not automatically authorize copying it into this collection under MIT. This collection provides independently written guidance and links to official documentation.

Official sources: [Xcode 27 release notes](https://developer.apple.com/documentation/xcode-release-notes/xcode-27-release-notes), [What's new in Xcode](https://developer.apple.com/xcode/whats-new/), plus the installed `xcrun agent skills export --help` output.
