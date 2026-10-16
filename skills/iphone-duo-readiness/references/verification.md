# Duo verification and evidence

This checklist is a practical test strategy, informed by the Apple sources in
[Apple guidelines](apple-guidelines.md). It is not an Apple certification process.
Select representative high-risk journeys rather than taking every possible
combination of every setting.

## Record the environment

Record Xcode version/build, SDK, runtime/build, app configuration, deployment
target, device identifier and active display. For each capture, record actual
window dimensions in points, display scale and the tested pose. Read simulator
display IDs from the current device; never hard-code IDs from another machine.

Use the installed tool's help to discover supported commands. Prefer a
per-command `DEVELOPER_DIR` to changing the user's global Xcode selection. Reuse
one suitable simulator and coordinate UI work. A test runner and another agent
must not drive the same session concurrently.

## Runtime coverage

| Configuration or transition | Evidence to collect |
| --- | --- |
| Outer display, portrait and supported landscape | Visible/tappable controls, correct margins, native bar layout and overflow. |
| Inner display, portrait and landscape | Actual inner-display capture, useful content width, coherent hierarchy, no covered actions. |
| Outer → inner → outer during a task | Same selection, draft, navigation destination, modal and custom-control values. |
| Partially folded book pose | Discrete controls stay usable, related content stays together, continuous scrolling remains coherent. |
| Tabletop pose | Content and actions stay reachable; optional custom arrangement preserves functionality. |
| Split View, both left and right | Per-edge margins and toolbar placement remain correct; no mirrored-inset assumption. |
| Reduced available height, keyboard or PiP where applicable | Focused field and completion actions remain reachable; intentional scrolling has no covered endpoint. |
| Resize/fold during an active drag or animation | Gesture state settles coherently without a stuck offset, runaway animation or loss of the selected value. |
| Accessibility and appearance | Large text, VoiceOver, Reduce Motion and live system appearance remain usable across the affected layouts. |

For native share sheets, inspect presentation and dismissal without completing
an external share unless the user requested it. For edits, use isolated test
data. Verify both visual placement and accessibility actions; “exists” and
“hittable” assertions alone can miss overlapping labels.

## Useful app journeys

- Begin on a selected list/grid item, open its detail, change size, return.
- Enter an unsaved draft, show the keyboard, fold/open, finish or cancel.
- Change a calculator/ruler value, cross a year boundary, resize, reopen its
  date/number editor and verify the same result.
- Select share format/personalization, change display, present native sharing.
- Scroll a long card to its last line while fixed actions remain visible.
- Follow a first-run flow through text entry and confirmation at short height.

These are examples; choose the app's actual critical interactions rather than
adding unrelated features to meet the list.

## What does not count as a pass

- A successful build proves compilation, not layout or fold behavior.
- An orientation command with unchanged measured geometry proves no resize.
- An inactive black inner-display screenshot proves no usable inner layout.
- A synthetic wide canvas or generic resize is not an actual fold transition.
- An outer-display UI test does not establish inner-display or hinge coverage.
- An SDK declaration confirms an API exists, not how it behaves in this app.
- A historical test result is not a fresh run against a changed implementation.

## Device Hub and command limits

Apple describes Device Hub controls for opening, closing, rotating and folding
Duo. Use those controls or another documented interface that genuinely performs
the transition. If a UI connection times out, record the precise failed step;
complete independent code/build work and request only the manual action needed
to unlock the remaining check.

The inspected `devicectl device appResize start` command starts a temporary
session on a Resizable display; `set` adjusts that session and `observe` reports
its status. The session ends when the start process exits. This is not a
documented fold/open command. Confirm it actually starts and changes geometry,
then end the session. An “unavailable” response is a tooling limitation, not a
passing test or necessarily an app defect.

The 27.1 RC notes checked 2026-10-16 still limit most extension execution in the Duo simulator and lack
StandBy there. Test affected targets on supported environments and label any
device-specific gap. Recheck current release notes before assuming the same
limits apply to a newer beta.

## Deliverable

Record each result as **passed**, **failed**, or **not run/blocked**, with the
configuration and evidence path. Explain whether a failure is in the app, test
selector, simulator, or still unknown. After changing code, repeat the affected
checks; broaden only for a demonstrated risk. Report compatibility by the scope
actually verified instead of declaring unconditional readiness.
