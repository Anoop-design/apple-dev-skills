# Connection and agent configuration

Checked 2026-10-16 against Xcode 27.0 (27A266a), Swift 6.4, and the iOS 27 SDK. Availability below is per API, not the skill name.

## Establish the actual environment

Check `xcode-select -p` and `xcodebuild -version`. Use `DEVELOPER_DIR` for a command-scoped toolchain override when needed rather than changing the machine's global selection without reason. Platform requirements vary by Xcode release; read the installed app/release notes instead of treating beta minimums as permanent. Xcode 27 requires Apple silicon.

`mcpbridge` connects to a running Xcode tool service. Enable external-agent access in Xcode's Intelligence settings and open the intended project/workspace. UI labels can vary across versions. A denied or absent connection is not fixed by repeatedly launching agent processes.

```sh
xcrun mcpbridge --help
```

The checked CLI accepts `MCP_XCODE_PID` to target an Xcode process and optional `MCP_XCODE_SESSION_ID` for a tool session. Its default follows the Xcode selected by `xcode-select`; don't assume it chooses the frontmost editor window. Resolve the target window/workspace after connecting.

For a standard MCP client, configure a stdio server with command `xcrun` and args `["mcpbridge"]`. Use that client's documented registration command or existing project configuration. Read current settings first, preserve unrelated servers, and only change the requested scope. Don't print credentials into logs or configuration examples.

Connection requires the host's normal consent and permissions. Discover available tools after connection; an empty list can indicate disabled access, a stale connection, the wrong Xcode, or another setup problem. Do not claim one particular empty-list cause without evidence.

## Built-in agents and providers

Xcode's built-in agent/provider options are configured through its Intelligence settings and change with releases. Inspect the installed choices, account requirements, and current product documentation. Do not prescribe a model lineup, price, config directory, or third-party API contract from an old beta article.

MCP exposes tools. Agent Client Protocol integrates compatible agents into an editor; it is not simply a synonym for a permissions layer. Respect whichever access controls the configured client and Xcode expose.

Data transmission depends on the selected provider and tools. On-device predictive completion differs from a cloud coding agent. Explain the actual requested configuration; don't enable an external service or assert “source never leaves the Mac” for an entire agent workflow.

Official sources: [Giving external agents access to Xcode](https://developer.apple.com/documentation/xcode/giving-external-agents-access-to-xcode), [Xcode release notes](https://developer.apple.com/documentation/xcode-release-notes/xcode-27-release-notes), [Xcode Intelligence](https://developer.apple.com/xcode/).
