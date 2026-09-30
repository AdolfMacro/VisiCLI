# VisiCLI Architecture Audit

## Active runtime

```text
OpenCV Camera -> MediaPipe HandDetector -> HandObservation / 21 landmarks
-> FingerAnalyzer -> GestureRecognizer -> GestureStabilizer
-> ExplorerController (hierarchical navigation stack)
-> CameraPreview (mirrored live popup, landmarks, red square tracker)

Python project directory -> bounded AST ProjectAnalyzer -> ProjectGraph
-> ProjectViewport (responsive cards for the current level with breadcrumbs)
-> TerminalDashboard (pose-driven ASCII hand at left, project view at right)
```

The keyboard demo supplies the default navigation poses without requiring camera hardware. The five-finger open palm is intentionally unbound and shown as an idle pose. Finger analysis prefers MediaPipe world landmarks, falling back to aspect-corrected image landmarks, and uses palm-relative projection plus joint alignment without depending on palm-vs-back orientation. Degenerate hand geometry is ignored, not classified as a fist. The scanned project is never imported or executed. Cards and graph edges are source-derived static views, not runtime call/dependency traces.

## Implementation status

| Area | Status | Evidence / limitation |
|---|---|---|
| CLI / project path | Implemented | `-p` / `--project` validates an existing directory; `--demo` supports keyboard testing. |
| Python source analysis | Implemented, bounded | AST parsing; excludes common generated/vendor dirs; caps 10,000 files, 2 MiB/file, 64 MiB total, 20,000 definitions/file, and 100,000 total definitions. |
| Project model | Implemented | Package, file, class, and function nodes; containment, in-project import, and unambiguous name-based call edges. |
| Project safety | Implemented | Source is read and parsed, never imported or executed. Parse/read/limit issues are explicit in graph/panel state. |
| 2D terminal visualization | Implemented | Responsive cards show packages, files, classes, and functions one hierarchy level at a time, with breadcrumbs and summaries. |
| Hand tracking | Implemented; hardware dependent | MediaPipe Tasks requests up to two hands; image and world landmarks are retained; the first detected hand drives navigation. |
| Camera tracker popup | Implemented; GUI dependent | Mirrored live view draws landmarks and a red square around each tracked hand; `--no-camera-view` disables it and popup `q`/`Esc` closes only the preview. |
| Camera tracker popup | Implemented; GUI dependent | Mirrored live camera view draws hand landmarks and a red square around each tracked hand; `--no-camera-view` disables it and popup `q`/`Esc` closes only the preview. |
| Gesture recognition | Implemented heuristic | Thumb+index enters; open palm is an unbound idle pose; unsupported combinations do not trigger actions. |
| Startup/menu flow | Removed | The project map opens directly; no Run/Set Action menu or second-hand confirmation. |
| Default navigation | Implemented | 0 parent/back, 1 next, 2 thumb+index enter, 3 toggle functions, 4 next page, 5 unbound idle open palm. |
| Hand/dashboard composition | Implemented | Pose-driven ASCII hand stays in the left column; hierarchy cards fill the right panel and adapt to terminal cells. |
| Diagnostics | Implemented | Camera/native stderr is written to `--log-file` (default `~/.cache/visicli/runtime.log`) rather than corrupting the live TUI; raised errors remain explicit. |

## Analysis semantics

`ProjectAnalyzer` collects files in deterministic path order, ignores symlinks and common generated/vendor directories, and uses AST source locations. Relative/absolute imports are linked only when they resolve to scanned project modules. Calls are linked only when a name matches exactly one scanned definition; ambiguous names remain unlinked. Dynamic imports, runtime dispatch, aliases, and arbitrary attribute resolution are outside this static graph.

Malformed, unreadable, oversized, over-budget, or overly complex files are reported rather than silently executed or substituted. File/package nodes may remain visible even when their source could not be parsed; the panel reports parse issues/skips.

## Interaction and UX

Navigation begins at the project root. Entering a package/file/class shows its immediate children; fist returns one level and restores the previous item/page. At the root, fist stays in place. Demo digits `0`-`4` simulate the navigation actions; `5` is an unbound idle open-palm pose. `Enter`/`c` enters, `m`/`b` backs out, and `q` exits.

## Boundaries

1. The project analyzer is a pure static reader and has no vision/camera dependency.
2. Camera/MediaPipe dependencies remain behind `Camera` and `HandDetector`.
3. Gesture recognition and stabilization do not draw or depend on the project graph.
4. `ExplorerController` owns navigation and session bindings; terminal rendering reads its state.
5. Hierarchy-card composition uses terminal cells and bounds line widths. TTY redraws erase to end-of-line and end-of-screen so shortened rows, resized layouts, and transitions cannot leave stale text behind.
6. Native diagnostics are retained in a local file, not printed into a live redraw. Model/camera exceptions remain visible to the caller.

Architecture checks remain in `tests/test_architecture_boundaries.py`; add tests when introducing new imports or responsibilities.

## Verification scope and limitations

- Project tests use temporary Python trees, malformed sources, ignored directories, and a sentinel proving scanned project code is not executed.
- Detector tests use fake MediaPipe results and synthetic spatial rotations/reflections; they validate geometry and conversion, not real-world recognition accuracy.
- Camera smoke testing is hardware-dependent. A previous smoke run had no hand in view, so successful real-hand recognition is not established.
- MediaPipe's `NORM_RECT` / image-dimension warning is retained in the diagnostic log; this work routes it away from the TUI but does not repair the upstream graph.
- The declared Python minimum is 3.10; validate that exact runtime before asserting compatibility.
