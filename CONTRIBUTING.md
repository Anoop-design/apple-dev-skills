# Contributing

Keep each skill useful for a concrete Apple development task. A skill should improve the agent's decisions without replacing the user's product direction, architecture, deployment target, or requested scope.

## Content

- Keep `name` and `description` accurate and selective. Put substantial examples in references and link them from the entrypoint where they become relevant.
- Bundle required reference files inside the skill so individual installation works. Other skills may be recommended when available; they should not be hidden filesystem dependencies.
- Link primary Apple documentation for API availability, platform limitations, and version-sensitive behavior. Record the SDK/build and date when verifying a version-specific claim. Separate observed behavior, documented behavior, and unverified research.
- Treat App Store rules, pricing, regional availability, and service limits as changeable. Link their current source instead of presenting a historical snapshot as current advice.
- Preserve custom visual direction and accessibility. Use tabular numeric glyphs, stable widths for changing values, and the existing font for letters; confirm custom-font tabular support.
- Keep personal paths, private repositories, credentials, customer data, and unlicensed source material out of the collection. Attribute any permitted third-party material and retain its license.

## Verification

Run `python scripts/validate.py` and `python -m unittest discover -s tests -v` with the development dependencies installed. For a technical correction, also verify the affected claim against a primary source or an installed SDK. Run `python3 scripts/check_swift.py` on a Mac with the required Xcode SDK when changing a probe. Compile representative examples when their signatures or concurrency behavior change, and record runtime checks when a claim depends on device behavior.

For a substantial routing or workflow change, evaluate a realistic task and inspect whether the skill preserves the requested scope. A metadata check alone does not establish useful behavior.

Pull requests should explain the practical problem, the changed guidance, and the evidence supporting it. Do not call a skill fully tested when only its file structure was checked.
