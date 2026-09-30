# VisiCLI — Agent Continuation Guide

This is the operational, historical, technical, and product-philosophy brief for the next coding agent. Read it before changing behavior. It records what VisiCLI is, why it took its current shape, what is actually implemented, what was deliberately removed, what has only been tested synthetically, and the boundaries future work must preserve.

Related documents:

- [README.md](README.md): user-facing installation, invocation, controls, and current feature claims.
- [docs/ARCHITECTURE_AUDIT.md](docs/ARCHITECTURE_AUDIT.md): current subsystem map and audit status.
- [docs/IMPLEMENTATION_PLAN.md](docs/IMPLEMENTATION_PLAN.md): delivered project-explorer scope and follow-up opportunities.

When documents conflict, inspect the source and tests first. Do not promote a design intention or demo behavior into a capability claim unless the implementation and validation support it.

---

## 1. Product identity and purpose

**VisiCLI** is a Linux-friendly, terminal-native, hand-controlled visual explorer for Python source projects.

Its core idea is to make a codebase feel like a world that can be inspected spatially:

1. A developer supplies a Python project directory with `-p`.
2. VisiCLI reads eligible Python source as text and parses it with Python's AST.
3. The static structure is represented by project-owned nodes and edges.
4. The terminal renders a bounded geometric view of that structure.
5. Hand poses or keyboard controls navigate and reconfigure actions.

The project's name describes the product direction: **Visi**on plus a **CLI**. Vision supplies a human input channel; the command-line terminal is both the operating surface and the visual medium. This is not a claim that the tool understands every semantic or runtime behavior in an arbitrary program.

### Product principles

- **The source project is data, not an executable dependency.** Inspection must not run the code being analyzed.
- **The terminal is a first-class display.** Layout should respect available cells and avoid output that scrolls or wraps during redraw.
- **Hand gestures are input events.** Detection/classification, stabilization, intent, and application behavior remain separate responsibilities.
- **The visualization must be honest.** A static AST relation is not a runtime-confirmed call path; unresolvable/ambiguous evidence should remain unlinked or explicitly qualified.
- **Camera diagnostics must remain available.** Keep the live view clean, but do not silently discard warnings or errors.
- **The product is a navigable project explorer, not a restored gear demo.**

---

## 2. Product history and decisions

This section is intentionally retained so future agents do not repeat abandoned implementations.

### Earlier hand/gear prototype

The project originally started as an MVP in which webcam hand poses drove a terminal-rendered gear simulation. That version established the camera, MediaPipe, finger-state, gesture, terminal-rendering, and reusable 3D foundations. It is not the current product.

### Gear-scene retirement and hand dashboard

At the user's request, gear-specific world/simulation functionality and its active UI were removed. The primary screen became a responsive hand-tracking dashboard. Generic 3D math and rasterization code was initially left isolated, then removed during commit preparation at the user's direction; the active product contains no 3D scene or renderer.

### Hand illustration

An original bold pixel-style ASCII hand was implemented. It is generated from the five detected finger booleans rather than a static third-party picture. The desired experience keeps this hand on the left side of the terminal.

The project view replaces the old right-hand status box. Keep the original pose-driven ASCII hand visible at the left, and do not restore the old status-box layout. Historical remnants in unreferenced experimental code/tests may exist; preserve only what remains useful and do not let them dictate the active design.

### Project exploration direction

The current explorer uses a direct-navigation 2D hierarchy:

- Python package/file/class/function structure.
- Conservative import and call edges.
- Responsive terminal-cell cards for immediate children at each hierarchy level, with breadcrumbs.
- Direct single-hand navigation: fist returns one parent level, index advances, and thumb+index enters.
- The pose-driven ASCII hand is shown beside the project map.
- Five-finger open palm is intentionally unbound and serves as an idle pose.
- Keyboard fallbacks; no startup menu or Set Action flow.

It is **not** a full source-code semantic engine, a 3D scene renderer, or an execution tracer. Be explicit about that distinction.

### Rename and relocation

The internal Python package, distribution, entry point, cache folder, menus, and active product docs were renamed from the former EYEhand identity to `visicli` / VisiCLI. The user explicitly requested that the old root remain unchanged while they move/rename it themselves.

The project was subsequently copied/moved to:

```text
/home/adolf/Documents/VisiCLI
```

The new root already contained a Git repository, a LICENSE, and a short README. The destination `.git` and LICENSE were preserved; project source, docs, tests, packaging files, and the full README were placed there. `localLearn/`, `.venv/`, pytest/bytecode caches, and egg-info were intentionally excluded. Future work belongs at `/home/adolf/Documents/VisiCLI`, not the old root.

The new root does not inherit the old `.venv`; install the destination environment when needed. The `install.sh` installer has not been run against the user's machine as part of its validation; it has been tested using mocked installer dependencies.

---

## 3. Current implementation map

### Active runtime flow

```text
                     ┌─ Camera -> MediaPipe -> up to two HandObservations ─┐
Keyboard demo poses ─┘                                                     │
                                                                          v
                                                            FingerAnalyzer
                                                                  |
                                                            GestureRecognizer
                                                                  |
                                                per-hand GestureStabilizers
                                                                  |
                                              ExplorerController / actions
                                                                  |
                                  CameraPreview: mirrored popup, landmarks, red track box
                                                                  |
Python directory -> bounded AST ProjectAnalyzer -> ProjectGraph -> ProjectViewport
                                                                  |
                                       TerminalDashboard: hand left, project right
```

### Important modules

- `src/visicli/app.py`
  - CLI parsing and validation.
  - Camera/demo selection and main loop.
  - Keyboard event handling.
  - Per-hand stabilizers and calls to the explorer state machine.
  - Terminal redraw and resource cleanup.
- `src/visicli/project/analyzer.py`
  - Deterministic Python file scan.
  - Bounded AST parsing and file/symbol limits.
  - Package/file/class/function nodes.
  - Containment/import/call edges.
  - Does not import or execute scanned source.
- `src/visicli/project/model.py`
  - Immutable `ProjectNode`, `ProjectEdge`, and `ProjectGraph` records.
- `src/visicli/project/explorer.py`
  - Direct `RUN` navigation with a parent stack, selection restoration, page navigation, function visibility, and default gesture bindings.
- `src/visicli/terminal/project_view.py`
  - Responsive 2D cards for packages/files/symbols at the active hierarchy level.
  - Breadcrumbs, bounded pages, selection metadata, and adaptive terminal-cell sizing.
- `src/visicli/terminal/dashboard.py`
  - Pose-driven ASCII hand, hand-left/project-right composition, compact fallbacks, and redraw lifecycle.
- `src/visicli/vision/camera_preview.py`
  - Mirrored OpenCV live popup with hand landmarks, red square tracker, and independent popup close control.
- `src/visicli/terminal/log_capture.py`
  - Routes fd-level stderr from native libraries to a log file during live UI operation.
- `src/visicli/vision/detector.py`
  - MediaPipe Tasks adapter, up to two hand observations, image/world landmark metadata, and palm-relative 3D finger geometry analysis.
- `src/visicli/gesture/recognizer.py`
  - Recognition of supported finger-state combinations.
- `src/visicli/gesture/stabilizer.py`
  - Time-based temporal stabilization and repeated event suppression.
- `src/visicli/camera/camera.py`
  - OpenCV capture adapter and camera errors.
- `src/visicli/terminal/input.py`
  - Raw-mode lifecycle for single-keystroke controls.
- `src/visicli/download_model.py`
  - Download of the MediaPipe task asset with a pinned checksum.
- `install.sh`
  - User-level Linux install helper. It creates a dedicated venv, installs the project via pip, links the executable into a user bin directory, adds that directory to common shell configuration files, and downloads the model unless `--no-model` is given.

---

## 4. Static project analysis: actual semantics and boundaries

### What the analyzer currently models

`ProjectAnalyzer` creates:

- **Package nodes** for directories containing `__init__.py`.
- **File nodes** for Python files.
- **Class nodes** for `ast.ClassDef`.
- **Function nodes** for `ast.FunctionDef` and `ast.AsyncFunctionDef`, including methods/nested definitions.
- **Containment edges** from package to file and enclosing scope to definitions.
- **Import edges** when import syntax resolves to a scanned module in the selected directory.
- **Call edges** only if the called name matches exactly one collected definition name. This is deliberately conservative but is not scope-aware semantic binding.

Every project edge must be read as static evidence. The graph does not prove that an edge executes, that a call resolves to the displayed target at runtime, or that no unshown edge exists.

### Explicit safety invariant

Never use any of the following against a scanned project:

- `importlib`, `runpy`, `exec`, `eval`, subprocess execution, or dynamic module loading.
- Installing the scanned project to inspect it.
- Running its tests/build scripts as part of analysis.
- Executing setup/build metadata.

Only read source bytes and parse syntax. Tests must retain a sentinel regression proving a scanned side-effect expression is not executed.

### Determinism, exclusions, and limits

Current defaults in `analyzer.py`:

- 10,000 Python files considered.
- 2 MiB maximum source size per file.
- 64 MiB total parsed source bytes.
- 20,000 definitions per file.
- 100,000 definitions total.

Common ignored directories include `.git`, `.venv`, `venv`, `__pycache__`, `build`, `dist`, test/type/lint caches, `node_modules`, and `site-packages`. Hidden directories are skipped. Symlinked Python files are skipped and directory walking does not follow symlinked directories.

When changing limits or exclusions:

1. Keep scan order deterministic.
2. Keep limits observable and testable.
3. Do not silently report partial results as complete.
4. Ensure parse/read/limit issues can be surfaced in the UI and tests.
5. Consider denial-of-service cases: huge file counts, large files, excessive AST depth/definitions, permission failures, and malformed encoding.

Current limitations worth revisiting:

- The file list is collected before the file-count slice is applied; a hostile tree with millions of filenames can still cost memory/time during traversal. Improve with bounded traversal if this becomes a threat or performance issue, while preserving deterministic selection.
- `os.walk` errors are raised, but permission failures are whole-scan errors rather than per-directory partial reports.
- Package recognition is based on `__init__.py`; namespace packages are not modeled as package nodes.
- Relative/absolute module resolution is static and may not match arbitrary import roots.
- Call edges use simple names/attributes and unique global name candidates; aliases, lexical scope, decorators, dynamic dispatch, descriptors, and runtime imports are not resolved.
- Source locations are primarily definition locations; there is no code-body preview/editor yet.

---

## 5. Hand interaction and UX

### Recognized shapes and default actions

Default navigation bindings:

| Number | Finger pose | Default action |
|---:|---|---|
| 0 | Fist | Return one level to the parent; stay at project root |
| 1 | Index | Next item at the current level |
| 2 | Thumb + index | Enter selected package/file/class with children |
| 3 | Index + middle + ring | Toggle function visibility |
| 4 | Four non-thumb fingers | Next page at the current level |
| 5 | Open palm | Idle pose; no action is bound |

Other combinations map to `UNKNOWN` and must not accidentally trigger an action.

### Direct navigation

- The app starts at the project root; entering packages, files, and classes shows their immediate children.
- Fist returns exactly one level and restores the previous selection and page. At the root it stays in place.
- Leaf items report that they have no nested items instead of showing stale content from another level.
- The first MediaPipe result drives navigation; the other detected hand does not confirm actions.
- The keyboard demo maps digits `0`–`4` to navigation/filter actions; `5` displays an unbound open-palm idle pose. `Enter`/`c` enters, `m`/`b` backs out, and `q` quits.
- Keyboard interaction also works when the camera is active.

### Main UI constraints

- Retain the bold ASCII hand on the **left** of the wide layout.
- The hierarchy-card map replaces the former right status panel; the ASCII hand remains visible at left.
- Fit by terminal rows/columns, not guessed font pixel sizes.
- Keep every output line within the available width; avoid last-column wrapping.
- Small terminals may need compact/stacked layout; test extremely small dimensions as well as ordinary 80x24 and wide terminals.
- Redraw in place on TTYs; finite non-TTY runs should print one useful snapshot.
- Make selection and resulting action/status visibly distinguishable.
- Do not let logs leak into the redraw or swallow user keystrokes.

### Hand art policy

The current pixel hand is original and generated from the five `FingerState` booleans. It should depict only observed/synthetic-demo state; do not invent a detected pose when no landmarks exist. A historical user-provided ASCII image from a website was not to be reproduced; keep the shipped design original.

---

## 6. Installer and distribution

`install.sh` is designed for current-user installation across mainstream Linux distributions, using pip wheels rather than distro-specific package-manager commands.

### Intended behavior

- Require Linux, Python 3.10+, and `venv` support.
- Create an isolated environment under `${XDG_DATA_HOME:-$HOME/.local/share}/visicli/venv`.
- Install the project from the script's own directory.
- Link `visicli` into `${VISICLI_BIN_DIR:-$HOME/.local/bin}`.
- Add that bin directory idempotently to `.profile`, existing Bash/Zsh files, and Fish config if Fish exists.
- Download and checksum-verify the hand model unless `--no-model` is set.
- Support `VISICLI_INSTALL_DIR`, `VISICLI_BIN_DIR`, and `PYTHON` overrides.
- Preserve an unrelated existing executable; fail rather than overwrite it.
- Do not use `sudo`, apt, pacman, dnf, or modify system Python.

### Honesty about portability

No shell script can guarantee the Python binary wheels for every distro, architecture, or Python minor release. If `venv`/`ensurepip` is a distro-split package, the user must install it using that distro's package manager. OpenCV/MediaPipe wheel availability can also vary. The installer must report actionable failures without claiming every Linux configuration is guaranteed.

### Installer test policy

`tests/test_installer.py` currently checks shell syntax, help, invalid arguments, user-link creation, idempotent PATH blocks, and model command invocation using mocked Python executables. This does **not** constitute a full network/package installation test. Do not run the real installer in the user's home as a test without explicit authorization; it changes persistent shell configuration and downloads a multi-megabyte model.

---

## 7. Naming, cache paths, and workspace policy

- Product/display/command name: **VisiCLI** / `visicli`.
- Python package: `visicli`.
- Distribution: `visicli`.
- CLI entry point: `visicli = "visicli.app:main"`.
- Default model cache: `~/.cache/visicli/hand_landmarker.task`.
- Default runtime log: `~/.cache/visicli/runtime.log`.
- Old model cache is recognized as a fallback so an existing download need not be downloaded again.
- The current workspace root is `/home/adolf/Documents/VisiCLI`; the user handled renaming/moving the root directory.
- Do not refer to the old root or make changes there; all ongoing work must target this workspace.
- The destination is a Git repository. Inspect status before edits, preserve user changes, and never overwrite its existing LICENSE or `.git`.
- The research corpus `localLearn/` was excluded from the relocated project. Do not reintroduce it into product files or scan it as test input unless explicitly requested.
- Keep generated `.venv`, `__pycache__`, `.pytest_cache`, `*.egg-info`, build, dist, and camera/model artifacts out of version control.

The one legacy model-path fallback and tests may mention the former identity for migration compatibility. Do not rebrand that compatibility path away unless migration is intentionally removed with clear user impact.

---

## 8. Dependencies and architecture rules

Declared dependencies in `pyproject.toml`:

- Python `>=3.10`.
- NumPy.
- OpenCV Python package.
- MediaPipe.
- Pytest as a test extra.

Maintain boundaries:

1. `camera` / MediaPipe adapters isolate hardware and third-party APIs.
2. Project-owned contracts flow across subsystem boundaries.
3. Vision does not import terminal/project rendering.
4. Gesture recognition/stabilization do not import terminal rendering.
5. The project analyzer does not import or execute project code and should remain independent of camera/vision.
6. The explorer controller owns state and actions; terminal view code presents that state.
7. Keep the active project view focused on bounded terminal cards rather than reintroducing a separate scene renderer.
8. Error handling must be explicit. Avoid blanket catches, silent success fallbacks, or swallowed scan/camera/logging failures.

Architecture regression checks are in `tests/test_architecture_boundaries.py`; adjust those checks when architecture changes intentionally.

---

## 9. Current validation record and what it does not prove

Record the latest validation for this workspace here; historical counts from earlier rename/installer milestones are intentionally not treated as current results.

Latest local validation (Python 3.14.4, after removing the legacy 3D renderer and its tests):

```bash
PYTHONPATH=src python3 -m pytest -q
python3 -m compileall -q src tests
bash -n install.sh
PYTHONPATH=src python3 -m visicli.app --help
PYTHONPATH=src python3 -m visicli.app --demo --frames 1 -p src
```

- **217 tests passed.**
- Compile, installer shell syntax, CLI help, and finite demo smoke run passed.
- `pip check` was also attempted against the shared system Python and reported unrelated missing/conflicting packages; this repository has no project-local `.venv`, and no dependency installation was run.
- Camera-popup drawing, square bounds, landmark rendering, close behavior, and `--no-camera-view` parsing have synthetic tests. The CLI/demo smoke run verifies the terminal view, not physical camera behavior.

Validation caveats:

- Synthetic hand landmarks and mocked MediaPipe results do not validate real-world pose accuracy, two-hand ordering, ergonomics, lighting, or camera performance.
- The camera preview requires a graphical OpenCV backend and a working display; `--no-camera-view` supports headless camera operation.
- MediaPipe may emit non-fatal `NORM_RECT` / image-dimension and feedback-tensor diagnostics. They are routed to the log, not fixed in the upstream graph.
- Python 3.10 is declared but local validation uses Python 3.14; run the minimum-version matrix before claiming it is verified.
- Installer tests do not verify distribution-specific Python packages, all wheel architectures, actual camera permissions, or network downloads. Do not run the real installer in the user's home as a test.

Re-run validation after changes. Prefer targeted tests first, then the complete suite:

```bash
cd /home/adolf/Documents/VisiCLI
PYTHONPATH=src python3 -m pytest tests/project tests/terminal tests/test_app.py tests/test_installer.py -q
PYTHONPATH=src python3 -m pytest -q
python3 -m compileall -q src tests
bash -n install.sh
PYTHONPATH=src python3 -m visicli.app --help
```

When there is no `.venv` at the root, do not assume it exists. The installer itself should be syntax/mock-tested first; ask before executing an install that changes persistent state.

---

## 10. Recommended next work

Prioritize correctness and usability over expanding headline scope:

1. **Terminal UX:** review actual screenshots/TTY dimensions, keep the hierarchy legible, expose current selection/action status, and verify the hand stays left with the project view immediately right.
2. **Graph usability:** inspect exact node ordering and relationships, make paging and zoom reversible/intuitive, and test large projects without building an unbounded in-memory canvas.
3. **Gesture reliability:** collect reproducible observations before tuning thresholds; expose honest confidence/unknown states. Add explicit hand tracking/selection policy if handedness is used.
4. **Analyzer robustness:** bound traversal itself, improve namespace/relative-import resolution conservatively, and make edge provenance inspectable. Continue proving source is never run.
5. **Installer robustness:** test existing-command collisions, spaces in paths, custom XDG locations, shell startup-file behavior, model-download failure recovery, and Python versions/platforms. Avoid destructive/uninstall behavior unless requested.
6. **Minimum-runtime CI:** test Python 3.10 and supported Linux architectures/wheel combinations before broad compatibility claims.
7. **Diagnostics:** investigate the MediaPipe graph warning rather than suppressing it. Keep the output routed and retained until a tested upstream fix is known.

Do not add non-Python parsing, arbitrary runtime execution, automatic project installation, telemetry, persistent gesture configuration, or a gear-world revival without an explicit product decision.

---

## 11. Agent execution checklist

Before changing code:

1. Confirm current root with `pwd`; it must be `/home/adolf/Documents/VisiCLI`.
2. Read Git status and preserve pre-existing user edits.
3. Read the directly relevant source and tests.
4. Identify whether the request changes product semantics, safety, UX, or installation behavior.
5. If ambiguity materially changes the design, ask one focused question rather than guessing.

While implementing:

1. Make a precise, complete, scoped change; update relevant docs.
2. Reuse existing types and boundaries.
3. Add regression tests for the actual user-visible behavior.
4. Keep README claims aligned with what runs.
5. Never run or import the target Python project as part of static analysis.
6. Avoid executing persistent install/cleanup operations without the user's request.

Before finishing:

1. Run focused tests, then the full applicable suite.
2. Compile/type-check/lint as available.
3. Test the exact CLI or installer behavior requested.
4. State what changed, what was verified, and hardware/platform caveats without overstating results.
