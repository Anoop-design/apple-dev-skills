# Apple Dev Skills

Practical agent skills for building, debugging, and refining apps on Apple platforms. This collection grew out of real app work and packages that guidance as reusable `SKILL.md` folders.

**23 skills for SwiftUI, UIKit, Apple frameworks, and Xcode**, available under the [MIT license](LICENSE). Use them with a coding agent that supports the `SKILL.md` format. Each folder is independently installable and includes its references and license.

The release has been reviewed against Apple documentation and the Xcode 27 SDK, with representative Swift examples typechecked using Swift 6. See the [release audit](docs/RELEASE-AUDIT.md) for the corrections, evidence, and runtime testing limits.

## Install

Clone the collection and install only the skills you need. The installer requires Python 3.9 or later and has no third-party dependencies.

```sh
git clone https://github.com/Anoop-design/apple-dev-skills.git
cd apple-dev-skills
python3 scripts/install.py swiftui-modern ios-adaptive-layout
```

By default, this copies complete folders to `~/.agents/skills`, a [documented Codex skill location](https://learn.chatgpt.com/docs/build-skills#where-codex-loads-local-skills). Codex detects skill changes automatically; restart it if an installed skill does not appear. Avoid installing duplicate copies of a skill in multiple discovery locations.

```sh
# Browse the collection
python3 scripts/install.py --list

# Preview a complete installation without writing anything
python3 scripts/install.py --all --dry-run

# Install the full collection
python3 scripts/install.py --all

# Install into a project's skill folder, or another agent's documented location
python3 scripts/install.py swiftui-modern --dest /path/to/project/.agents/skills
```

The installer refuses to overwrite an existing skill folder. To update, review the changes and back up or move your previous copy before installing again. You can also use your agent's skill installer with a link such as [skills/swiftui-modern](https://github.com/Anoop-design/apple-dev-skills/tree/main/skills/swiftui-modern), or copy a complete folder manually.

## Choose a skill

Install the skills relevant to your work. A focused task normally needs one primary skill and only the supporting references it links to.

| Area | Skill | Use it for |
| --- | --- | --- |
| SwiftUI | [swiftui-modern](skills/swiftui-modern/SKILL.md) | State, navigation, observation, data flow, and framework adoption |
| Design | [swiftui-native-design](skills/swiftui-native-design/SKILL.md) | Native hierarchy, typography, layout, and interaction |
| Design | [liquid-glass](skills/liquid-glass/SKILL.md) | System materials and custom glass in SwiftUI and UIKit |
| Layout | [ios-adaptive-layout](skills/ios-adaptive-layout/SKILL.md) | iPhone/iPad resizing, rotation, readable columns, and continuity |
| Layout | [iphone-duo-readiness](skills/iphone-duo-readiness/SKILL.md) | Duo-specific layout, display transitions, and verification |
| Animation | [ios-animations-guide](skills/ios-animations-guide/SKILL.md) | SwiftUI springs, transitions, gestures, and sequences |
| Animation | [core-animation-uikit](skills/core-animation-uikit/SKILL.md) | CALayer, Core Animation, and UIKit animation |
| Graphics | [swiftui-shaders](skills/swiftui-shaders/SKILL.md) | SwiftUI Metal color, distortion, and layer effects |
| Performance | [swiftui-performance-profiling](skills/swiftui-performance-profiling/SKILL.md) | Instruments, view updates, identity, and measured optimization |
| Camera | [swiftui-camera-capture](skills/swiftui-camera-capture/SKILL.md) | AVFoundation capture and SwiftUI preview integration |
| Widgets | [swiftui-widgets](skills/swiftui-widgets/SKILL.md) | Timelines, configuration, shared data, widgets, and Live Activities |
| Widgets | [swiftui-widgets-ios27](skills/swiftui-widgets-ios27/SKILL.md) | Version-specific WidgetKit and Live Activity adoption |
| Apple Intelligence | [foundation-models](skills/foundation-models/SKILL.md) | Sessions, structured output, streaming, and tool calling |
| Apple Intelligence | [apple-intelligence-ios](skills/apple-intelligence-ios/SKILL.md) | Image Playground, Writing Tools, and Genmoji |
| Machine learning | [apple-intelligence-ml](skills/apple-intelligence-ml/SKILL.md) | Core ML, Vision, Natural Language, and Speech |
| System integration | [app-intents-siri](skills/app-intents-siri/SKILL.md) | App Intents, entities, Shortcuts, and Siri |
| Data | [cloudkit](skills/cloudkit/SKILL.md) | iCloud sync, sharing, records, and persistence integration |
| Health | [healthkit](skills/healthkit/SKILL.md) | Authorization, health data, workouts, and Watch integration |
| Maps | [mapkit-swiftui](skills/mapkit-swiftui/SKILL.md) | Maps, search, routing, places, and UIKit bridges |
| Commerce | [storekit-monetization](skills/storekit-monetization/SKILL.md) | Purchases, subscriptions, entitlements, and StoreKit testing |
| Engineering | [ios-shipping-engineer](skills/ios-shipping-engineer/SKILL.md) | Architecture and implementation tradeoffs |
| Quality | [ios-polished-apps](skills/ios-polished-apps/SKILL.md) | Requested accessibility, polish, and release-readiness reviews |
| Tooling | [xcode-agentic](skills/xcode-agentic/SKILL.md) | Xcode agent integration, build/test workflows, and tool discovery |

The collection is strongest in iOS, iPadOS, and SwiftUI. Several frameworks also apply to macOS, watchOS, tvOS, or visionOS, but this is not yet a complete guide to every Apple platform. Dedicated AppKit, macOS distribution, Swift concurrency, and spatial-computing skills are possible future additions.

## Using the collection

Each directory under `skills/` contains an entrypoint and any bundled references. Keep the whole skill folder together. Start with one primary skill, and load additional skills only when their scope matches the task.

No external Apple, Figma, or SwiftRender skill is bundled. Xcode workflows require the appropriate installed toolchain and tools; a skill cannot provide them by itself. Framework examples still need the project's deployment target, entitlements, assets, and device configuration.

Example requests:

- “Use swiftui-modern to fix the state and navigation flow in this feature.”
- “Use ios-adaptive-layout to preserve this form while the iPad window resizes.”
- “Use swiftui-performance-profiling to investigate this scrolling hitch.”
- “Use healthkit to implement workout recording with appropriate authorization.”

Preserve the app's design and platform support. Numeric UI should use tabular digits and stable field widths while retaining the chosen font for letters. Verify custom-font support for tabular figures.

## Development

Use Python 3.9 or later in an isolated environment:

```sh
python3 -m venv .venv
.venv/bin/python -m pip install -r requirements-dev.txt
.venv/bin/python scripts/validate.py
.venv/bin/python -m unittest discover -s tests -v
```

GitHub Actions runs the metadata, license, standalone-reference, and installer regression checks. On a Mac with the reviewed Xcode SDK, also run `python3 scripts/check_swift.py` to typecheck the representative probes. These probes check API signatures and Swift concurrency diagnostics; they are not complete apps or device tests. See [contribution guidance](CONTRIBUTING.md), the [release audit](docs/RELEASE-AUDIT.md), and [source provenance](docs/PROVENANCE.md).

## License

The custom collection is licensed under the [MIT License](LICENSE), copyright 2026 Anoop. Each skill includes its own license notice so the notice travels with independently installed or redistributed skill folders. The separate Figma and SwiftRender plugin skills, Apple's exported skills, and the private component-library skill are not included.

This is an independent community collection and is not affiliated with or endorsed by Apple or OpenAI.
