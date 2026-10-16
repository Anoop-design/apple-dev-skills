# Source provenance

This collection was assembled on October 16, 2026 from 23 custom skills in the owner's installed skill collection. The originals remain unchanged. [source-manifest.json](source-manifest.json) records each included skill's original relative filenames and SHA-256 hashes, allowing changes in the release copy to be compared with the source snapshot.

The original folders did not contain per-skill license files. On October 16, 2026, the owner selected the MIT license for this custom collection. The release includes a [root license](../LICENSE), a copy in every skill folder, and `license: MIT` in each skill's metadata. The source manifest records original file identity and release-copy changes; it does not relicense any excluded third-party material.

## Included changes

The release copy was technically reviewed and edited for independent distribution. Changes include corrected SDK signatures and availability, camera and model-session concurrency, HealthKit authorization, CloudKit encryption, transaction handling, animation and rendering guidance, tool discovery, and task-specific activation.

Long entrypoints now route to bundled references. Foundation Models owns its model-session material; overlapping copies in the system-AI and ML skills were removed. Personal project examples were generalized, and numeric typography guidance preserves tabular digits, stable widths, and the chosen font's letterforms.

The [release audit](RELEASE-AUDIT.md) records verification and runtime limits. The manifest distinguishes changed, added, and removed files relative to the original snapshot. None of these edits were applied to the owner's installed originals.

## Deliberately excluded

| Installed skill | Reason |
| --- | --- |
| `swift-components` | Requires a private component catalog and private repository access. |
| `figma:figma-swiftui` | Belongs to the installed Figma plugin and depends on its tools and companion skills. |
| `swift-render:app-launch-video` | Belongs to a separate SwiftRender plugin and depends on its rendering package, starter assets, and helpers. Review separately if it should be distributed here. |
| `element-studio` | A general web/3D artifact workflow with personal local paths and project assets; not specifically an Apple development skill. |

Apple's skills mentioned in the Xcode guide are not included. Readers should obtain them through their own Xcode installation. The separate plugin skills were inspected for scope, not copied or relicensed.
