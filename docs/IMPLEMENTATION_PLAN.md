# VisiCLI Implementation Status

## Delivered project explorer

- `-p DIR` / `--project DIR` validates and scans a Python project.
- The AST analyzer creates package/file/class/function nodes and conservative containment/import/call edges without importing or executing target code.
- Resource limits and ignored generated/vendor directories bound the scan; parsing and limit failures are reported.
- The right-side 2D grid uses responsive hierarchy cards for packages, files, classes, and functions. The pose-driven ASCII hand remains at the left.
- The app opens directly at the project root. Thumb+index enters the selected item; fist returns one parent level and restores selection/page.
- The open-palm pose is deliberately unbound for idle hand display. Default actions navigate, toggle function visibility, and change pages; there is no startup menu or action-setup flow.
- Camera mode shows a mirrored OpenCV preview popup with the detected hand landmarks and a red square tracker; `--no-camera-view` disables the popup for headless environments.
- Camera/native stderr output is redirected to a persistent diagnostic log while live redraw is active. Raised application errors are still reported normally.

## Validation

From the project root:

```sh
.venv/bin/python -m pytest -q
.venv/bin/python -m compileall -q src tests
.venv/bin/python -m pip check
.venv/bin/python -m visicli.app --demo --frames 1 -p /path/to/python-project
```

Camera hardware and real-hand pose accuracy must be checked on the target machine. The demo verifies controls and graph behavior, not vision accuracy.

## Follow-up opportunities

1. Validate the one-hand navigation poses under the target camera, including thumb-plus-index entry.
2. If users need arbitrary finger combinations as separate actions, extend pose identity only after collecting representative tests.
3. Improve semantic resolution of aliases, attribute calls, dynamic imports, and package edge cases only with conservative tests; do not execute scanned code.
4. Investigate and fix the upstream MediaPipe `NORM_RECT` / image-dimension warning if a supported Tasks graph/API path is available. It is currently preserved in the local diagnostic log.
