---
name: xcode-agentic
description: "Connect an external coding agent to Xcode through mcpbridge, discover Xcode tools, and build, test, or inspect previews. Use for Xcode agent setup, tool-driven verification, or exported Xcode skills."
license: MIT
---

# Xcode agent workflows

Use the project's selected Xcode, scheme, destination, deployment targets, and verification conventions. This skill supports Xcode agent integration; it does not require enabling a new cloud provider, editing global agent settings, or migrating the project to a newer SDK for ordinary work.

## Choose the working path

- For a running Xcode project and an available MCP connection, discover the advertised tools and their schemas. Resolve the intended window/workspace and pass its identifier to scoped calls.
- For headless work or unavailable IDE tools, use the project's normal `xcodebuild`/SwiftPM workflow. A CLI build is valid evidence; it does not prove interactive preview or UI behavior.
- For agent setup, read [connection and configuration](references/setup-and-models.md).
- Before using an unfamiliar Xcode tool, read [tool discovery](references/mcp-tools.md).
- For Apple's exported skill catalog, read [agent skills](references/agent-skills.md).
- For task-specific verification, read [workflows](references/workflows.md).
- For devices, Instruments, previews, or CI, read [surrounding tools](references/device-hub-and-instruments.md).

Validate the affected behavior proportionally: build when source changes require it, run relevant tests, and inspect previews or the actual UI when the change affects presentation/interaction. Don't force an entire build/test/preview/simulator matrix on every file edit. Stop repeated retries when a missing capability, signing asset, or environment problem prevents progress; report the exact limitation.

Discover capabilities from the installed release and current connection. A remembered tool name, beta list, or marketing feature is not a tool contract. Preserve the user's existing authorization and do not introduce a separate mandatory plan-approval step for routine authorized work.
