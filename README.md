# VisiCLI

**Explore a Python codebase from your terminal—with hand gestures or a keyboard.**

VisiCLI statically scans Python source and displays a navigable hierarchy of bordered 2D terminal cards for packages, files, classes, and functions. Each view shows one level at a time with a breadcrumb and concise child summaries. The application opens directly into the project map; there is no startup menu.

> **Safety by design:** VisiCLI reads and parses the project source. It does not import or execute the project being inspected.

Choose a language: [English](#english) · [فارسی](#فارسی) · [Հայերեն](#հայերեն)

---

## English

### What it does

- Maps Python packages, files, classes, functions, and selected in-project import and call relationships.
- Displays a clean hierarchy of package, file, class, and function cards, with immediate children shown at each level.
- Adapts the card grid and page size to terminal dimensions; long summaries are abbreviated when necessary.
- Shows a live pose-driven ASCII hand beside the project view; when no hand is detected, it explicitly shows a waiting state.
- Opens a separate mirrored camera popup with hand landmarks and a red square tracker; the popup can be disabled for headless use.
- Starts directly in project navigation. One detected hand can drive the default actions; keyboard controls are also available.
- Keeps camera and native-library diagnostics in a log instead of printing them over the live terminal interface.
- Bounds source scanning with directory exclusions and file, byte, and definition limits.

VisiCLI is a static source-structure explorer, not a Python runtime tracer or a general-purpose semantic analyzer.

### Quick start

From the VisiCLI checkout, scan a Python project with the default webcam:

```bash
cd /path/to/VisiCLI
.venv/bin/visicli --camera -p /path/to/my-python-project
```

Run without opening the camera:

```bash
.venv/bin/visicli --demo -p /path/to/my-python-project
```

The map appears immediately. Press `q` to quit. For a finite, non-interactive smoke run:

```bash
.venv/bin/visicli --demo --frames 1 -p /path/to/my-python-project
```

### Install

Requirements:

- Python **3.10 or newer**
- A terminal supporting standard ANSI cursor controls for the interactive display
- For camera mode: a working webcam, camera permissions, and the MediaPipe Hand Landmarker model

On Linux, the user-level installer creates an isolated environment, installs the application and dependencies, downloads and verifies the hand model, and exposes `visicli` in `~/.local/bin`. It does not use `sudo` or install into the system Python:

```bash
chmod +x install.sh
./install.sh
```

The installer configures common user shell startup files. Open a new terminal or reload the shell configuration to use `visicli` by name. Installation files are stored outside the source tree:

```text
~/.local/share/visicli/venv/
~/.cache/visicli/hand_landmarker.task
```

To install without downloading the model, then download it later:

```bash
./install.sh --no-model
~/.local/share/visicli/venv/bin/python -m visicli.download_model
```

The model download is checked against a pinned SHA-256 checksum. The installer requires Python 3.10+, `venv`/`ensurepip`, pip access, and compatible OpenCV and MediaPipe wheels. It does not install operating-system packages automatically.

Optional installer overrides:

```bash
VISICLI_INSTALL_DIR="$HOME/apps/visicli" \
VISICLI_BIN_DIR="$HOME/.local/bin" \
PYTHON=python3.12 \
./install.sh
```

For development, create an editable environment:

```bash
python3 -m venv .venv
.venv/bin/python -m pip install -e ".[test]"
.venv/bin/python -m visicli.download_model
```

### Actions and how navigation works

The app starts at the project root. Enter a package, file, or class to inspect its children; fist returns to exactly one parent level and restores the prior selection. No selection menu, action-setup screen, or second-hand confirmation is required.

| Gesture / demo key | Action |
|---|---|
| `0` — fist | Return to the parent level; at the project root, stay there. |
| `1` — index finger | Select the next item at the current level. |
| `2` — thumb + index | Enter the selected package, file, class, or other item with children. |
| `3` — index + middle + ring | Show or hide function nodes in the current hierarchy. Functions are visible by default. |
| `4` — four non-thumb fingers | Move to the next page at the current hierarchy level. |
| `5` — open palm | Idle pose only; displays the open hand and triggers no project action. |
| `q` | Quit. |

The same digits `0`–`5` simulate the poses in demo mode and are keyboard fallbacks in camera mode. Digit `5` displays an open hand without binding it to an action. `Enter` or `c` has the same effect as action 2. `b` or `m` goes back one level. Navigation wraps at the beginning/end of the current item list and page list.

Navigation follows the source hierarchy: project root → package → file → class/function → nested members. Each level shows its immediate children in a bounded, terminal-sized card grid, with a breadcrumb showing the current path. Entering a leaf reports that it has no nested items; it does not display unrelated previous-level contents. Returning restores the previous selection and page. Action 3 toggles function visibility, and action 4 changes the page at the current level.

### How the project map is built

1. VisiCLI walks the selected directory in deterministic path order and considers Python `*.py` files.
2. It parses eligible source with Python's `ast` module. It never imports or executes project modules.
3. It creates package, file, class, and function nodes, with source locations where available.
4. It adds containment edges, resolvable in-project import edges, and conservative call edges when a call maps to exactly one scanned definition.
5. It organizes package/file/class/function nodes into a navigable hierarchy and calculates a bounded card layout from the available terminal rows and columns.

Common generated/vendor directories—including `.git`, `.venv`, `venv`, `__pycache__`, `build`, and `dist`—are excluded. Symlinked Python files are not followed. Default limits:

| Limit | Default |
|---|---:|
| Python files considered | 10,000 |
| Source size per file | 2 MiB |
| Total source size parsed | 64 MiB |
| Definitions per file | 20,000 |
| Definitions across the scan | 100,000 |

Malformed, unreadable, oversized, or over-budget files are reported. A displayed static relationship is not proof of runtime behavior.

### Command reference

```text
visicli [--demo | --camera] [-p DIRECTORY]
        [--camera-index INDEX] [--model PATH] [--frames COUNT]
        [--debug] [--log-file PATH] [--no-camera-view] [--ascii-art]
```

| Option | Description |
|---|---|
| `-p DIR`, `--project DIR` | Existing Python project directory to scan. |
| `--camera` | Use the webcam (default mode). |
| `--demo` | Use keyboard-selected hand poses; does not open the camera. |
| `--camera-index N` | OpenCV camera device index; defaults to `0`. |
| `--model PATH` | MediaPipe task model path. |
| `--frames N` | Render a finite number of frames, useful for smoke tests. |
| `--debug` | Include frame timing in the project view. |
| `--log-file PATH` | Camera/native diagnostics destination; defaults to `~/.cache/visicli/runtime.log`. |
| `--no-camera-view` | Disable the separate live camera popup; useful on headless systems. |
| `--ascii-art` | Legacy compatibility flag; the active dashboard always shows the ASCII hand. |
| `-h`, `--help` | Print command help. |

Examples:

```bash
visicli -p ./my-python-project
visicli --camera --camera-index 1 -p ./my-python-project
visicli --demo -p ./my-python-project
visicli --demo --frames 1 -p ./my-python-project
visicli --camera -p ./my-python-project --log-file ./visicli-runtime.log
visicli --camera --no-camera-view -p ./my-python-project
```

### Architecture

```text
Python project
  -> bounded AST ProjectAnalyzer
  -> ProjectGraph (package/file/class/function nodes and static edges)
  -> ExplorerController (hierarchical selection stack, paging, default actions)
  -> ProjectViewport (responsive 2D cards and breadcrumb at the active level)
  -> TerminalDashboard (pose-driven ASCII hand at left, project map at right)

Camera -> OpenCV Camera -> MediaPipe HandDetector -> HandObservation
  -> FingerAnalyzer -> GestureRecognizer -> GestureStabilizer
  -> ExplorerController
  -> mirrored OpenCV popup with hand skeleton and red square tracker

Keyboard demo -> simulated poses / navigation keys -> ExplorerController
```

| Module | Responsibility |
|---|---|
| `src/visicli/camera/` | OpenCV camera capture and camera errors. |
| `src/visicli/vision/` | MediaPipe 3D/world landmarks and palm-relative finger extension/joint-bend analysis; normalized-landmark fallback. |
| `src/visicli/vision/camera_preview.py` | Mirrored OpenCV camera popup with hand landmarks and a red square tracker. |
| `src/visicli/gesture/` | Maps supported finger poses to gestures and stabilizes them over time. |
| `src/visicli/project/analyzer.py` | Bounded, deterministic AST scan; does not execute project code. |
| `src/visicli/project/model.py` | Immutable project node, edge, and graph records. |
| `src/visicli/project/explorer.py` | Hierarchical selection stack, parent navigation, page navigation, function visibility, and gesture-action bindings. |
| `src/visicli/terminal/project_view.py` | Responsive cards for packages/files/symbols, breadcrumbs, selection, and page status. |
| `src/visicli/terminal/dashboard.py` | Pose-driven ASCII hand, input status, layout composition, and terminal redraw lifecycle. |
| `src/visicli/terminal/input.py` | Raw terminal input lifecycle. |
| `src/visicli/terminal/log_capture.py` | Routes native stderr diagnostics to a log file. |
The analyzer, graph model, navigation controller, terminal view, and camera/vision adapters have separate responsibilities. Project source remains data throughout analysis. Import edges are limited to scanned project modules; call edges remain unlinked when resolution is ambiguous.

### Diagnostics and troubleshooting

- **Command not found:** install or refresh the package with `.venv/bin/python -m pip install -e ".[test]"`, then check `.venv/bin/visicli --help`.
- **Missing hand model:** run `.venv/bin/python -m visicli.download_model` or pass `--model PATH`.
- **Camera will not open:** check permissions and try `--camera-index 1`. Camera errors are reported; demo mode is not substituted silently.
- **Camera popup unavailable:** install/use a graphical OpenCV environment, or pass `--no-camera-view` to run camera tracking without a preview window. Press `q` or `Esc` inside the popup to close only that window.
- **MediaPipe/OpenCV messages:** native stderr is retained in `--log-file` (default `~/.cache/visicli/runtime.log`). A MediaPipe `NORM_RECT`/image-dimension warning has been observed; logging it keeps the UI readable but does not fix the upstream graph.
- **No hand detected:** improve lighting, keep the hand fully in frame, and use `--demo` to test the interface independently of camera tracking.
- **Hand geometry invalid:** reposition the whole hand in frame; degenerate landmarks are ignored rather than interpreted as a fist/action.

### Development and tests

```bash
.venv/bin/python -m pip install -e ".[test]"
.venv/bin/python -m pytest -q
.venv/bin/python -m compileall -q src tests
.venv/bin/python -m pip check
```

Tests cover analyzer safety and limits, graph relationships, card sizing, navigation, mocked image/world landmark conversion, palm/back mirroring and out-of-plane hand geometry, the camera popup tracker overlay, and terminal redraw. Synthetic landmarks do not establish real-world gesture accuracy.

### Known limitations

- Finger extension uses MediaPipe world landmarks when available and otherwise aspect-corrected image landmarks. Palm-relative projection, joint alignment, and thumb abduction are geometric heuristics, not a calibrated classifier; camera pose reliability still needs device-specific testing.
- Only the documented default poses trigger actions. The open-palm pose is deliberately unbound; arbitrary combinations and orientations are not distinct actions.
- Calls are resolved conservatively. Dynamic imports, runtime dispatch, arbitrary attribute calls, and ambiguous names are not fully represented.
- The 2D map is a static source view, not a runtime trace. Dense cells abbreviate content; larger projects are paged.
- Python 3.10+ is declared, but the minimum interpreter and non-Linux terminals need independent validation.
- Camera hardware, hand ergonomics, and broad platform compatibility require separate testing; no benchmark or production-readiness claim is implied.

---

## فارسی

### VisiCLI چیست؟

**ساختار پروژهٔ پایتون را با ژست دست یا صفحه‌کلید، مستقیماً در ترمینال ببینید.**

VisiCLI کد پایتون را به‌صورت ایستا بررسی می‌کند و سلسله‌مراتبی قابل‌ناوبری از کارت‌های دوبعدی برای بسته، فایل، کلاس و تابع نشان می‌دهد. هر نما یک سطح را همراه با مسیر breadcrumb و خلاصهٔ زیرمجموعه‌های مستقیم نمایش می‌دهد. برنامه مستقیماً نقشهٔ پروژه را باز می‌کند و منوی آغازین ندارد.

> **ایمنی:** VisiCLI کد پروژه را می‌خواند و تجزیه می‌کند؛ فایل‌های پروژهٔ مورد بررسی را import یا اجرا نمی‌کند.

### قابلیت‌ها

- نمایش بسته‌ها، فایل‌ها، کلاس‌ها، تابع‌ها و برخی رابطه‌های import و فراخوانی درون پروژه.
- نمایش سلسله‌مراتب مرتب کارت‌های بسته، فایل، کلاس و تابع؛ هر سطح فقط زیرمجموعه‌های مستقیم خود را نشان می‌دهد.
- تنظیم شبکه و تعداد کارت‌های هر صفحه بر اساس اندازهٔ ترمینال؛ خلاصه‌های طولانی برای جا شدن کوتاه می‌شوند.
- نمایش دوبارهٔ تصویر ASCII پویا از دست کنار نقشه؛ اگر دستی تشخیص داده نشود، وضعیت انتظار صریح نشان داده می‌شود.
- نمایش popup آینه‌ای زندهٔ دوربین با نقاط دست و tracker مربعی قرمز؛ برای محیط headless می‌توان آن را خاموش کرد.
- شروع مستقیم در نقشهٔ پروژه؛ کنترل با یک دست یا صفحه‌کلید، بدون منوی انتخاب و تأیید دست دوم.
- نگهداری پیام‌های دوربین و کتابخانه‌های بومی در فایل گزارش، بدون به‌هم‌زدن بازترسیم ترمینال.
- محدودسازی پیمایش با حذف پوشه‌های تولیدی و سقف تعداد فایل، بایت و تعریف.

VisiCLI ابزار مشاهدهٔ ساختار ایستای کد است، نه ردیاب اجرای پایتون یا تحلیل‌گر معنایی عمومی.

### شروع سریع

از پوشهٔ VisiCLI، پروژهٔ پایتون را با دوربین پیش‌فرض بررسی کنید:

```bash
cd /path/to/VisiCLI
.venv/bin/visicli --camera -p /path/to/my-python-project
```

اجرای رابط بدون باز کردن دوربین:

```bash
.venv/bin/visicli --demo -p /path/to/my-python-project
```

نقشه بلافاصله نمایش داده می‌شود. برای خروج `q` را بزنید. اجرای آزمایشیِ یک‌فریمی و غیرتعاملی:

```bash
.venv/bin/visicli --demo --frames 1 -p /path/to/my-python-project
```

### نصب

پیش‌نیازها:

- پایتون **۳٫۱۰ یا جدیدتر**
- ترمینال دارای پشتیبانی استاندارد از کنترل‌گرهای ANSI برای نمایش تعاملی
- برای حالت دوربین: وب‌کم فعال، مجوز دسترسی و مدل MediaPipe Hand Landmarker

نصب‌کنندهٔ لینوکس محیط مجازی جداگانه می‌سازد، برنامه و وابستگی‌ها را نصب می‌کند، مدل دست را دانلود و بررسی می‌کند و فرمان `visicli` را در `~/.local/bin` قرار می‌دهد. از `sudo` استفاده نمی‌کند و چیزی در پایتون سیستمی نصب نمی‌کند:

```bash
chmod +x install.sh
./install.sh
```

نصب‌کننده تنظیم مسیر را در فایل‌های متداول راه‌اندازی پوسته انجام می‌دهد. برای استفاده از فرمان `visicli`، ترمینال تازه‌ای باز کنید یا تنظیمات پوسته را بارگذاری مجدد کنید. فایل‌های نصب بیرون از پوشهٔ منبع قرار می‌گیرند:

```text
~/.local/share/visicli/venv/
~/.cache/visicli/hand_landmarker.task
```

برای نصب بدون مدل و دانلود مدل در زمان دیگر:

```bash
./install.sh --no-model
~/.local/share/visicli/venv/bin/python -m visicli.download_model
```

درستی مدل با checksum ثابت SHA-256 بررسی می‌شود. نصب‌کننده به Python 3.10+، پشتیبانی `venv`/`ensurepip`، دسترسی pip و wheelهای سازگار OpenCV و MediaPipe نیاز دارد و بستهٔ سیستم‌عامل را خودکار نصب نمی‌کند.

تغییرهای اختیاری نصب:

```bash
VISICLI_INSTALL_DIR="$HOME/apps/visicli" \
VISICLI_BIN_DIR="$HOME/.local/bin" \
PYTHON=python3.12 \
./install.sh
```

برای توسعه، محیط قابل‌ویرایش بسازید:

```bash
python3 -m venv .venv
.venv/bin/python -m pip install -e ".[test]"
.venv/bin/python -m visicli.download_model
```

### اکشن‌ها و روش کار

برنامه از ریشهٔ پروژه شروع می‌شود. با ورود به بسته، فایل یا کلاس، زیرمجموعه‌های آن دیده می‌شوند؛ مشت دقیقاً به سطح والد برمی‌گردد و انتخاب و صفحهٔ قبلی را بازیابی می‌کند. منوی انتخاب، صفحهٔ تنظیم اکشن یا تأیید دست دوم وجود ندارد.

| ژست / کلید آزمایشی | اکشن |
|---|---|
| `0` — مشت | بازگشت به سطح والد؛ در ریشهٔ پروژه همان‌جا می‌ماند. |
| `1` — انگشت اشاره | انتخاب مورد بعدی در سطح فعلی. |
| `2` — شست + اشاره | ورود به بسته، فایل، کلاس یا مورد انتخاب‌شده‌ای که زیرمجموعه دارد. |
| `3` — اشاره + میانی + حلقه | نمایش یا مخفی‌کردن گره‌های تابع در سلسله‌مراتب؛ تابع‌ها در شروع نمایش داده می‌شوند. |
| `4` — چهار انگشت بدون شست | رفتن به صفحهٔ بعد در سطح فعلی سلسله‌مراتب. |
| `5` — کف دست باز | فقط حالت بی‌عمل؛ دست باز را نشان می‌دهد و هیچ اکشنی اجرا نمی‌کند. |
| `q` | خروج. |

در حالت demo، کلیدهای `0` تا `5` ژست‌ها را شبیه‌سازی می‌کنند؛ همین کلیدها در حالت دوربین نیز جایگزین صفحه‌کلید هستند. کلید `5` دست باز را بدون اکشن نمایش می‌دهد. `Enter` یا `c` مانند اکشن ۲ وارد سطح انتخاب‌شده می‌شود. `b` یا `m` یک سطح به والد برمی‌گردد. حرکت در ابتدا و انتهای فهرست و صفحهٔ همان سطح دوری است.

ناوبری از ساختار منبع پیروی می‌کند: ریشهٔ پروژه ← بسته ← فایل ← کلاس/تابع ← اعضای تو‌در‌تو. هر سطح فقط زیرمجموعه‌های مستقیم خود را در کارت‌های متناسب با ترمینال نشان می‌دهد و breadcrumb مسیر فعلی را مشخص می‌کند. ورود به مورد انتهایی پیام «زیرمجموعه‌ای ندارد» می‌دهد و محتوای سطح قبلی را به‌جای آن نشان نمی‌دهد. بازگشت، انتخاب و صفحهٔ قبلی را بازیابی می‌کند. اکشن ۳ نمایش تابع‌ها را تغییر می‌دهد و اکشن ۴ صفحهٔ سطح جاری را عوض می‌کند.

### نقشهٔ پروژه چگونه ساخته می‌شود؟

۱. VisiCLI پوشهٔ انتخاب‌شده را با ترتیب مسیر قطعی می‌پیماید و فایل‌های `*.py` را در نظر می‌گیرد.
۲. کد واجد شرایط را با ماژول `ast` پایتون تجزیه می‌کند؛ ماژول‌های پروژه را import یا اجرا نمی‌کند.
۳. گره‌هایی برای بسته، فایل، کلاس و تابع می‌سازد و در صورت وجود، محل تعریف در کد را نگه می‌دارد.
۴. رابطه‌های containment، import درون‌پروژه‌ایِ قابل‌حل و فراخوانی‌هایی را ثبت می‌کند که دقیقاً به یک تعریف اسکن‌شده می‌رسند.
۵. گره‌های بسته/فایل/کلاس/تابع را در سلسله‌مراتبی قابل‌ناوبری سازمان‌دهی می‌کند و چیدمان محدود کارت‌ها را با تعداد سطر و ستون ترمینال تطبیق می‌دهد.

پوشه‌های تولیدی/وابستگی مانند `.git`، `.venv`، `venv`، `__pycache__`، `build` و `dist` حذف می‌شوند. فایل‌های پایتونِ symlink دنبال نمی‌شوند. سقف‌های پیش‌فرض:

| محدودیت | مقدار پیش‌فرض |
|---|---:|
| فایل‌های پایتون قابل بررسی | ۱۰٬۰۰۰ |
| اندازهٔ هر فایل منبع | ۲ MiB |
| مجموع منبع تجزیه‌شده | ۶۴ MiB |
| تعریف در هر فایل | ۲۰٬۰۰۰ |
| تعریف در کل پیمایش | ۱۰۰٬۰۰۰ |

فایل خراب، ناخوانا، بزرگ‌تر از حد یا بیرون از بودجه گزارش می‌شود. رابطهٔ ایستای نمایش‌داده‌شده اثبات رفتار زمان اجرا نیست.

### راهنمای فرمان

```text
visicli [--demo | --camera] [-p DIRECTORY]
        [--camera-index INDEX] [--model PATH] [--frames COUNT]
        [--debug] [--log-file PATH] [--no-camera-view] [--ascii-art]
```

| گزینه | کاربرد |
|---|---|
| `-p DIR`، `--project DIR` | پوشهٔ موجود پروژهٔ پایتون برای پیمایش. |
| `--camera` | استفاده از وب‌کم؛ حالت پیش‌فرض. |
| `--demo` | شبیه‌سازی ژست‌ها با صفحه‌کلید، بدون بازکردن دوربین. |
| `--camera-index N` | شمارهٔ دستگاه دوربین OpenCV؛ پیش‌فرض `0`. |
| `--model PATH` | مسیر مدل MediaPipe. |
| `--frames N` | نمایش تعداد محدودی فریم برای آزمایش سریع. |
| `--debug` | نمایش زمان پردازش فریم در نمای پروژه. |
| `--log-file PATH` | مسیر گزارش دوربین/کتابخانهٔ بومی؛ پیش‌فرض `~/.cache/visicli/runtime.log`. |
| `--no-camera-view` | غیرفعال‌کردن popup زندهٔ دوربین؛ مناسب محیط‌های بدون نمایشگر گرافیکی. |
| `--ascii-art` | گزینهٔ قدیمی برای سازگاری؛ داشبورد فعال همیشه تصویر ASCII دست را نشان می‌دهد. |
| `-h`، `--help` | نمایش راهنمای فرمان. |

نمونه‌ها:

```bash
visicli -p ./my-python-project
visicli --camera --camera-index 1 -p ./my-python-project
visicli --demo -p ./my-python-project
visicli --demo --frames 1 -p ./my-python-project
visicli --camera -p ./my-python-project --log-file ./visicli-runtime.log
visicli --camera --no-camera-view -p ./my-python-project
```

### معماری

```text
پروژهٔ پایتون
  -> ProjectAnalyzer مبتنی بر AST با سقف منابع
  -> ProjectGraph (گره‌های بسته/فایل/کلاس/تابع و رابطه‌های ایستا)
  -> ExplorerController (پشتهٔ ناوبری سلسله‌مراتبی، صفحه‌بندی و اکشن‌های پیش‌فرض)
  -> ProjectViewport (کارت‌های دوبعدی سطح جاری و breadcrumb)
  -> TerminalDashboard (تصویر ASCII دست در چپ، نقشهٔ پروژه در راست)

دوربین -> OpenCV Camera -> MediaPipe HandDetector -> HandObservation
  -> FingerAnalyzer -> GestureRecognizer -> GestureStabilizer
  -> ExplorerController
  -> پنجرهٔ آینه‌ای OpenCV با اسکلت دست و کادر مربعی قرمز tracker

حالت صفحه‌کلید -> ژست‌های شبیه‌سازی‌شده / کلیدهای ناوبری -> ExplorerController
```

| ماژول | مسئولیت |
|---|---|
| `src/visicli/camera/` | دریافت تصویر با OpenCV و خطاهای دوربین. |
| `src/visicli/vision/` | نقاط سه‌بعدی/جهانی MediaPipe، تخمین امتداد نسبت به کف‌دست و خمیدگی بندها؛ با مسیر جایگزین نقاط تصویر. |
| `src/visicli/vision/camera_preview.py` | popup آینه‌ای OpenCV با نقاط دست و کادر مربعی قرمز tracker. |
| `src/visicli/gesture/` | تبدیل ژست‌های پشتیبانی‌شده به اکشن و پایدارسازی زمانی. |
| `src/visicli/project/analyzer.py` | پیمایش محدود و قطعی AST؛ بدون اجرای کد پروژه. |
| `src/visicli/project/model.py` | مدل‌های تغییرناپذیر گره، یال و گراف پروژه. |
| `src/visicli/project/explorer.py` | پشتهٔ سلسله‌مراتبی، انتخاب والد/فرزند، صفحه‌بندی، نمایش تابع‌ها و اتصال ژست به اکشن. |
| `src/visicli/terminal/project_view.py` | کارت‌های بسته/فایل/نماد، مسیر breadcrumb، انتخاب و وضعیت صفحه. |
| `src/visicli/terminal/dashboard.py` | تصویر ASCII ژست‌محور دست، وضعیت ورودی، ترکیب نما و بازترسیم ترمینال. |
| `src/visicli/terminal/input.py` | چرخهٔ ورود ترمینال در حالت خام. |
| `src/visicli/terminal/log_capture.py` | هدایت stderr کتابخانه‌های بومی به فایل گزارش. |
تحلیل‌گر، مدل گراف، کنترل‌گر ناوبری، نمای ترمینال و اتصال‌های دوربین/بینایی مسئولیت‌های جدا دارند. کد پروژه در تمام مراحل داده باقی می‌ماند. یال import فقط برای ماژول‌های اسکن‌شدهٔ پروژه ساخته می‌شود و فراخوانی مبهم بدون یال می‌ماند.

### عیب‌یابی

- **فرمان پیدا نمی‌شود:** بسته را با `.venv/bin/python -m pip install -e ".[test]"` نصب/به‌روز کنید و `.venv/bin/visicli --help` را بررسی کنید.
- **مدل دست موجود نیست:** `.venv/bin/python -m visicli.download_model` را اجرا کنید یا `--model PATH` بدهید.
- **دوربین باز نمی‌شود:** مجوزها را بررسی کنید و `--camera-index 1` را امتحان کنید. خطای دوربین گزارش می‌شود و برنامه بی‌صدا به demo سوییچ نمی‌کند.
- **پنجرهٔ دوربین باز نمی‌شود:** از محیط گرافیکی و OpenCV دارای GUI استفاده کنید یا برای اجرای بدون پنجره `--no-camera-view` بدهید. فشردن `q` یا `Esc` در popup فقط همان پنجره را می‌بندد.
- **پیام MediaPipe/OpenCV:** stderr بومی در `--log-file` (پیش‌فرض `~/.cache/visicli/runtime.log`) نگه‌داری می‌شود. هشدار `NORM_RECT`/ابعاد تصویر MediaPipe مشاهده شده است؛ ثبت آن رابط را خوانا نگه می‌دارد اما ایراد بالادستی را رفع نمی‌کند.
- **دست تشخیص داده نمی‌شود:** نور و کادر را بهتر کنید و برای آزمودن خود رابط، مستقل از دوربین، `--demo` را اجرا کنید.
- **هندسهٔ دست نامعتبر است:** کل دست را دوباره در کادر قرار دهید؛ نقاط فرسوده/نامعتبر نادیده گرفته می‌شوند و به‌عنوان مشت یا اکشن تفسیر نمی‌شوند.

### توسعه و آزمون

```bash
.venv/bin/python -m pip install -e ".[test]"
.venv/bin/python -m pytest -q
.venv/bin/python -m compileall -q src tests
.venv/bin/python -m pip check
```

آزمون‌ها ایمنی و محدودیت تحلیل‌گر، رابطه‌های گراف، اندازهٔ کارت‌ها، ناوبری، تبدیل نقاط تصویری/جهانی ساختگی، پشت/کف دست با چرخش فضایی، tracker دوربین و بازترسیم ترمینال را پوشش می‌دهند. نقاط دست مصنوعی دقت واقعی ژست را ثابت نمی‌کنند.

### محدودیت‌های شناخته‌شده

- هنگام موجودبودن، نقاط جهانی MediaPipe وگرنه نقاط تصویرِ تصحیح‌شده با نسبت ابعاد استفاده می‌شوند. امتداد نسبت به کف‌دست، هم‌راستایی بندها و بازشدگی شست تخمین هندسی است، نه طبقه‌بند کالیبره؛ دقت دوربین باید روی دستگاه هدف سنجیده شود.
- فقط ژست‌های پیش‌فرض مستندشده اکشن اجرا می‌کنند؛ کف دست باز عمداً بدون اکشن است. ترکیب دلخواه یا جهت‌های متفاوت، اکشن مستقل نیستند.
- حل فراخوانی محافظه‌کارانه است؛ import پویا، dispatch زمان اجرا، فراخوانی دلخواه attribute و نام‌های مبهم کامل نمایش داده نمی‌شوند.
- نقشهٔ دوبعدی نمای ایستای منبع است، نه ردگیری زمان اجرا. محتوای کارت‌های متراکم خلاصه و پروژه‌های بزرگ صفحه‌بندی می‌شوند.
- نسخهٔ Python 3.10+ اعلام شده است، اما حداقل نسخه و ترمینال‌های غیرلینوکس باید جداگانه اعتبارسنجی شوند.
- وب‌کم، راحتی ژست‌ها و سازگاری گسترده نیاز به آزمون جدا دارند؛ ادعای benchmark یا آمادگی محصول نهایی مطرح نیست.

---

## Հայերեն

### Ի՞նչ է VisiCLI-ն

**Ուսումնասիրեք Python նախագծի կառուցվածքը տերմինալում՝ ձեռքի ժեստերով կամ ստեղնաշարով։**

VisiCLI-ն ստատիկ կերպով վերլուծում է Python կոդը և ցուցադրում փաթեթների, ֆայլերի, դասերի ու ֆունկցիաների եզրագծված երկչափ քարտերի նավարկելի հիերարխիա։ Յուրաքանչյուր տեսք ցույց է տալիս մեկ մակարդակ՝ breadcrumb ուղով և անմիջական զավակների համառոտ նկարագրությամբ։ Ծրագիրը անմիջապես բացում է նախագծի քարտեզը․ մեկնարկային ընտրացանկ չկա։

> **Անվտանգություն․** VisiCLI-ն կարդում և վերլուծում է նախագծի աղբյուրը, բայց չի ներմուծում և չի կատարում ուսումնասիրվող նախագծի կոդը։

### Հնարավորություններ

- Ցուցադրում է Python փաթեթները, ֆայլերը, դասերը, ֆունկցիաները և նախագծի ներսում լուծվող որոշ import/call կապեր։
- Ցուցադրում է փաթեթների, ֆայլերի, դասերի և ֆունկցիաների քարտերի հստակ հիերարխիա՝ յուրաքանչյուր մակարդակում միայն անմիջական զավակներով։
- Քարտերի ցանցն ու էջի չափը հարմարեցնում է տերմինալի չափերին․ երկար ամփոփումները կրճատվում են։
- Նախագծի քարտեզի կողքին ցուցադրում է ժեստին համապատասխան ASCII ձեռք․ ձեռքի բացակայության դեպքում ցույց է տալիս սպասման հստակ վիճակ։
- Ցուցադրում է հայելային տեսախցիկի live popup՝ ձեռքի կետերով և կարմիր քառակուսի tracker-ով․ headless միջավայրում popup-ը կարելի է անջատել։
- Սկսում է անմիջապես նախագծի քարտեզից․ հասանելի են մեկ ձեռքի ժեստերն ու ստեղնաշարի կառավարումը, առանց ընտրացանկի կամ երկրորդ ձեռքով հաստատման։
- Տեսախցիկի և native գրադարանների հաղորդագրությունները գրում է գրանցամատյանում, որպեսզի չխաթարվի տերմինալի կենդանի պատկերը։
- Սահմանափակում է սկանավորումը՝ բացառելով գեներացված պանակները և կիրառելով ֆայլերի, բայթերի ու սահմանումների քանակի շեմեր։

VisiCLI-ն աղբյուրի կառուցվածքի ստատիկ դիտարկիչ է, ոչ թե Python-ի կատարման հետագծիչ կամ ընդհանուր նշանակության իմաստային վերլուծիչ։

### Արագ մեկնարկ

VisiCLI-ի պանակից սկանավորեք Python նախագիծը՝ լռելյայն տեսախցիկով․

```bash
cd /path/to/VisiCLI
.venv/bin/visicli --camera -p /path/to/my-python-project
```

Գործարկել առանց տեսախցիկը բացելու․

```bash
.venv/bin/visicli --demo -p /path/to/my-python-project
```

Քարտեզն անմիջապես կհայտնվի։ Դուրս գալու համար սեղմեք `q`։ Սահմանափակ, ոչ ինտերակտիվ փորձնական գործարկում․

```bash
.venv/bin/visicli --demo --frames 1 -p /path/to/my-python-project
```

### Տեղադրում

Պահանջներ․

- Python **3.10 կամ ավելի նոր**
- Ինտերակտիվ ցուցադրման համար ANSI կուրսորի ստանդարտ կառավարումն աջակցող տերմինալ
- Տեսախցիկի ռեժիմի համար՝ աշխատող վեբ-տեսախցիկ, հասանելիության թույլտվություն և MediaPipe Hand Landmarker մոդել

Linux-ի տեղադրիչը ստեղծում է մեկուսացված միջավայր, տեղադրում է ծրագիրն ու կախվածությունները, ներբեռնում և ստուգում է ձեռքի մոդելը, ապա `visicli` հրամանը հասանելի դարձնում `~/.local/bin`-ում։ Այն չի օգտագործում `sudo` և փաթեթներ չի տեղադրում համակարգային Python-ում․

```bash
chmod +x install.sh
./install.sh
```

Տեղադրիչը կարգավորում է օգտվողի տարածված shell-ի մեկնարկային ֆայլերը։ `visicli` հրամանն օգտագործելու համար բացեք նոր տերմինալ կամ վերաբեռնեք shell-ի կարգավորումները։ Տեղադրման ֆայլերը պահվում են աղբյուրի պանակից դուրս․

```text
~/.local/share/visicli/venv/
~/.cache/visicli/hand_landmarker.task
```

Տեղադրել առանց մոդելը ներբեռնելու և ներբեռնել այն ավելի ուշ․

```bash
./install.sh --no-model
~/.local/share/visicli/venv/bin/python -m visicli.download_model
```

Մոդելը ստուգվում է ամրագրված SHA-256 ստուգիչ գումարով։ Տեղադրիչին անհրաժեշտ են Python 3.10+, `venv`/`ensurepip`, pip-ի հասանելիություն և OpenCV/MediaPipe-ի համատեղելի wheel-եր։ Համակարգային փաթեթները ինքնաշխատ չեն տեղադրվում։

Տեղադրիչի կամընտիր փոփոխականներ․

```bash
VISICLI_INSTALL_DIR="$HOME/apps/visicli" \
VISICLI_BIN_DIR="$HOME/.local/bin" \
PYTHON=python3.12 \
./install.sh
```

Մշակման համար ստեղծեք editable միջավայր․

```bash
python3 -m venv .venv
.venv/bin/python -m pip install -e ".[test]"
.venv/bin/python -m visicli.download_model
```

### Գործողություններ և նավարկման ձևը

Ծրագիրը մեկնարկում է նախագծի արմատից։ Փաթեթ, ֆայլ կամ դաս բացելիս ցուցադրվում են դրա զավակները․ բռունցքը վերադառնում է ճիշտ մեկ ծնող մակարդակ և վերականգնում նախորդ ընտրությունն ու էջը։ Ընտրացանկ, գործողությունների կարգավորման էկրան կամ երկրորդ ձեռքով հաստատում չկա։

| Ժեստ / փորձնական ստեղն | Գործողություն |
|---|---|
| `0` — բռունցք | Վերադառնալ ծնող մակարդակ․ նախագծի արմատում մնալ նույն տեղում։ |
| `1` — ցուցամատ | Ընտրել հաջորդ տարրը ընթացիկ մակարդակում։ |
| `2` — բութ մատ + ցուցամատ | Բացել ընտրված փաթեթը, ֆայլը, դասը կամ այլ տարր, որն ունի զավակներ։ |
| `3` — ցուցամատ + միջնամատ + մատնեմատ | Միացնել կամ անջատել ֆունկցիայի հանգույցների ցուցադրումը․ սկզբում դրանք տեսանելի են։ |
| `4` — չորս մատ՝ առանց բութ մատի | Անցնել հաջորդ էջին ընթացիկ հիերարխիայի մակարդակում։ |
| `5` — բաց ափ | Միայն անգործուն դիրք․ ցուցադրում է բաց ձեռքը և գործողություն չի կատարում։ |
| `q` | Դուրս գալ։ |

Demo ռեժիմում `0`–`5` ստեղները նմանակում են ժեստերը․ տեսախցիկի ռեժիմում դրանք նույնպես ստեղնաշարային այլընտրանք են։ `5`-ը ցույց է տալիս բաց ձեռքը՝ առանց գործողության կապելու։ `Enter` կամ `c`-ը բացում է ընտրված մակարդակը։ `b` կամ `m`-ը մեկ մակարդակ վեր է վերադառնում։ Ընթացիկ մակարդակի տարրերի և էջերի սկզբից/վերջից անցումը շրջանաձև է։

Նավարկումը հետևում է աղբյուրի կառուցվածքին՝ նախագծի արմատ → փաթեթ → ֆայլ → դաս/ֆունկցիա → ներքին անդամներ։ Յուրաքանչյուր մակարդակ ցուցադրում է միայն անմիջական զավակներին՝ տերմինալի չափին հարմար քարտերով, իսկ breadcrumb-ը ցույց է տալիս ընթացիկ ուղին։ Տերևային տարրը բացելիս ծրագիրը հայտնում է, որ ներքին տարրեր չկան․ նախորդ մակարդակի հին բովանդակությունը չի ցուցադրվում։ Վերադառնալիս վերականգնվում են նախորդ ընտրությունն ու էջը։ Գործողություն 3-ը փոխում է ֆունկցիաների տեսանելիությունը, 4-ը՝ ընթացիկ մակարդակի էջը։

### Ինչպե՞ս է կառուցվում նախագծի քարտեզը

1. VisiCLI-ն ընտրված պանակը շրջում է որոշակի, դետերմինիստական ուղու հերթականությամբ և դիտարկում Python `*.py` ֆայլերը։
2. Հարմար ֆայլերը վերլուծում է Python-ի `ast` մոդուլով․ նախագծի մոդուլները չի ներմուծում և չի կատարում։
3. Ստեղծում է փաթեթի, ֆայլի, դասի և ֆունկցիայի հանգույցներ, ինչպես նաև պահպանում է աղբյուրի տեղադրությունը, եթե այն հասանելի է։
4. Ավելացնում է containment կապեր, լուծվող ներնախագծային import կապեր և call կապեր միայն այն դեպքում, երբ կանչը համապատասխանում է ճիշտ մեկ սկանավորված սահմանման։
5. Յուրաքանչյուր ֆայլն ու դրա ներքին նշանները դասավորում է երկչափ տերմինալային բջջում, իսկ էջավորումը հաշվարկում է ըստ տերմինալի տողերի և սյունակների։

Բացառվում են գեներացված/կախվածությունների տարածված պանակները՝ `.git`, `.venv`, `venv`, `__pycache__`, `build` և `dist`։ Symlink Python ֆայլերին չի հետևում։ Լռելյայն սահմաններ․

| Սահմանափակում | Լռելյայն արժեք |
|---|---:|
| Դիտարկվող Python ֆայլեր | 10,000 |
| Յուրաքանչյուր ֆայլի աղբյուրի չափ | 2 MiB |
| Վերլուծվող աղբյուրի ընդհանուր չափ | 64 MiB |
| Սահմանումներ յուրաքանչյուր ֆայլում | 20,000 |
| Սահմանումներ ամբողջ սկանավորման ընթացքում | 100,000 |

Սխալ, անհասանելի, չափազանց մեծ կամ բյուջեն գերազանցող ֆայլերը հաղորդվում են։ Ցուցադրված ստատիկ կապը կատարման ժամանակի վարքի ապացույց չէ։

### Հրամանների տեղեկատու

```text
visicli [--demo | --camera] [-p DIRECTORY]
        [--camera-index INDEX] [--model PATH] [--frames COUNT]
        [--debug] [--log-file PATH] [--no-camera-view] [--ascii-art]
```

| Տարբերակ | Նկարագրություն |
|---|---|
| `-p DIR`, `--project DIR` | Սկանավորման ենթակա գոյություն ունեցող Python նախագծի պանակը։ |
| `--camera` | Օգտագործել վեբ-տեսախցիկը․ լռելյայն ռեժիմ։ |
| `--demo` | Ձեռքի դիրքերը կառավարել ստեղնաշարով՝ առանց տեսախցիկը բացելու։ |
| `--camera-index N` | OpenCV տեսախցիկի սարքի համարը․ լռելյայն `0`։ |
| `--model PATH` | MediaPipe task մոդելի ուղին։ |
| `--frames N` | Ցուցադրել սահմանափակ թվով կադրեր՝ արագ փորձարկման համար։ |
| `--debug` | Նախագծի տեսքում ցուցադրել կադրի մշակման ժամանակը։ |
| `--log-file PATH` | Տեսախցիկի/native հաղորդագրությունների ուղին․ լռելյայն `~/.cache/visicli/runtime.log`։ |
| `--no-camera-view` | Անջատել տեսախցիկի առանձին live popup-ը․ օգտակար է առանց գրաֆիկական էկրանի համակարգերում։ |
| `--ascii-art` | Հին համատեղելիության դրոշակ․ ակտիվ վահանակը միշտ ցուցադրում է ASCII ձեռքը։ |
| `-h`, `--help` | Ցուցադրել հրամանի օգնությունը։ |

Օրինակներ․

```bash
visicli -p ./my-python-project
visicli --camera --camera-index 1 -p ./my-python-project
visicli --demo -p ./my-python-project
visicli --demo --frames 1 -p ./my-python-project
visicli --camera -p ./my-python-project --log-file ./visicli-runtime.log
visicli --camera --no-camera-view -p ./my-python-project --log-file ./visicli-runtime.log
```

### Ճարտարապետություն

```text
Python նախագիծ
  -> սահմանափակված AST ProjectAnalyzer
  -> ProjectGraph (փաթեթ/ֆայլ/դաս/ֆունկցիա հանգույցներ և ստատիկ կապեր)
  -> ExplorerController (հիերարխիկ նավարկման stack, էջավորում, լռելյայն գործողություններ)
  -> ProjectViewport (ընթացիկ մակարդակի հարմարեցվող 2D քարտեր և breadcrumb)
  -> TerminalDashboard (ժեստին համապատասխան ASCII ձեռքը ձախում, նախագծի քարտեզը՝ աջում)

Տեսախցիկ -> OpenCV Camera -> MediaPipe HandDetector -> HandObservation
  -> FingerAnalyzer -> GestureRecognizer -> GestureStabilizer
  -> ExplorerController
  -> հայելային OpenCV popup՝ ձեռքի կմախքով և կարմիր քառակուսի tracker-ով

Ստեղնաշարի demo -> նմանակված ժեստեր / նավարկման ստեղներ -> ExplorerController
```

| Մոդուլ | Պատասխանատվություն |
|---|---|
| `src/visicli/camera/` | OpenCV տեսախցիկի կադրերի ստացում և տեսախցիկի սխալներ։ |
| `src/visicli/vision/` | MediaPipe-ի 3D/աշխարհային կետեր, ափի նկատմամբ մատների երկարացման ու հոդերի ծալման գնահատում՝ պատկերի կետերի fallback-ով։ |
| `src/visicli/vision/camera_preview.py` | Հայելային OpenCV popup՝ ձեռքի կետերով և կարմիր քառակուսի tracker-ով։ |
| `src/visicli/gesture/` | Աջակցվող մատնաձևերի ճանաչում և ժամանակային կայունացում։ |
| `src/visicli/project/analyzer.py` | Սահմանափակված, դետերմինիստական AST սկանավորում՝ առանց նախագծի կոդը կատարելու։ |
| `src/visicli/project/model.py` | Նախագծի անփոփոխ հանգույցների, կապերի և գրաֆի մոդելներ։ |
| `src/visicli/project/explorer.py` | Հիերարխիկ stack, ծնող/զավակ ընտրություն, էջավորում, ֆունկցիաների տեսանելիություն և ժեստ-գործողություն կապեր։ |
| `src/visicli/terminal/project_view.py` | Փաթեթների/ֆայլերի/նշանների քարտեր, breadcrumb, ընտրություն և էջի վիճակ։ |
| `src/visicli/terminal/dashboard.py` | Ժեստին համապատասխան ASCII ձեռք, մուտքի վիճակ, տեսքերի դասավորում և տերմինալի վերագծում։ |
| `src/visicli/terminal/input.py` | Տերմինալի raw մուտքի ցիկլ։ |
| `src/visicli/terminal/log_capture.py` | Native stderr հաղորդագրությունների ուղղորդում դեպի գրանցամատյան։ |
Վերլուծիչը, գրաֆի մոդելը, նավարկման կառավարիչը, տերմինալի տեսքը և տեսախցիկի/տեսողության ադապտերներն ունեն առանձին պարտականություններ։ Նախագծի աղբյուրը վերլուծության ընթացքում մնում է տվյալ։ Import կապերը սահմանափակվում են սկանավորված նախագծի մոդուլներով, իսկ երկիմաստ կանչերը մնում են առանց կապի։

### Ախտորոշում և խնդիրների լուծում

- **Հրամանը չի գտնվում․** տեղադրեք կամ թարմացրեք փաթեթը `.venv/bin/python -m pip install -e ".[test]"` հրամանով, ապա ստուգեք `.venv/bin/visicli --help`։
- **Ձեռքի մոդելը բացակայում է․** գործարկեք `.venv/bin/python -m visicli.download_model` կամ նշեք `--model PATH`։
- **Տեսախցիկը չի բացվում․** ստուգեք թույլտվությունները և փորձեք `--camera-index 1`։ Սխալները հաղորդվում են, demo ռեժիմը լուռ չի փոխարինում տեսախցիկին։
- **Տեսախցիկի popup-ը չի բացվում․** օգտագործեք գրաֆիկական OpenCV միջավայր կամ գործարկեք `--no-camera-view`՝ առանց preview պատուհանի։ Popup-ում `q` կամ `Esc` սեղմելը փակում է միայն այդ պատուհանը։
- **MediaPipe/OpenCV հաղորդագրություններ․** native stderr-ը պահվում է `--log-file` ֆայլում (լռելյայն `~/.cache/visicli/runtime.log`)։ Դիտվել է MediaPipe `NORM_RECT`/պատկերի չափերի զգուշացում․ գրանցումը պահում է UI-ի ընթեռնելիությունը, բայց չի շտկում upstream գրաֆը։
- **Ձեռքը չի հայտնաբերվում․** բարելավեք լուսավորությունը, ձեռքը պահեք կադրում և գործարկեք `--demo`՝ տեսախցիկից անկախ ինտերֆեյսը ստուգելու համար։
- **Ձեռքի երկրաչափությունն անվավեր է․** ամբողջ ձեռքը նորից տեղադրեք կադրում․ անվավեր կետերը անտեսվում են և չեն մեկնաբանվում որպես բռունցք/գործողություն։

### Մշակում և թեստեր

```bash
.venv/bin/python -m pip install -e ".[test]"
.venv/bin/python -m pytest -q
.venv/bin/python -m compileall -q src tests
.venv/bin/python -m pip check
```

Թեստերը ծածկում են վերլուծիչի անվտանգությունն ու սահմանները, գրաֆի կապերը, քարտերի չափերը, նավարկումը, սինթետիկ պատկերային/աշխարհային կետերը, ափի/ձեռքի հակառակ կողմի տարածական պտույտները, տեսախցիկի tracker-ը և տերմինալի վերագծումը։ Սինթետիկ կետերը չեն ապացուցում իրական ժեստերի ճշտությունը։

### Հայտնի սահմանափակումներ

- Հասանելիության դեպքում օգտագործվում են MediaPipe-ի աշխարհային կետերը, հակառակ դեպքում՝ պատկերի կետերը՝ կողմերի հարաբերակցությունը շտկելուց հետո։ Մատների երկարացման, հոդերի համագծության և բթամատի բացվածքի գնահատումը երկրաչափական էվրիստիկա է, ոչ թե կալիբրացված դասակարգիչ․ հուսալիությունը պետք է փորձարկել նպատակային սարքում։
- Գործողություններ են կատարում միայն փաստաթղթավորված լռելյայն ժեստերը․ բաց ափը միտումնավոր գործողություն չունի։ Կամայական համակցություններն ու կողմնորոշումները առանձին գործողություններ չեն։
- Կանչերի լուծումը պահպանողական է․ դինամիկ import-ը, runtime dispatch-ը, կամայական attribute կանչերը և երկիմաստ անունները լիովին չեն ներկայացվում։
- Երկչափ քարտեզը աղբյուրի ստատիկ պատկերն է, ոչ թե կատարման հետագիծը։ Խիտ քարտերի բովանդակությունը կրճատվում է, իսկ մեծ նախագծերը բաժանվում են էջերի։
- Հայտարարված է Python 3.10+ աջակցություն, սակայն նվազագույն տարբերակը և ոչ Linux տերմինալները պետք է առանձին ստուգվեն։
- Տեսախցիկի սարքավորումը, ձեռքի դիրքերի հարմարավետությունը և հարթակների լայն համատեղելիությունը պահանջում են առանձին փորձարկումներ․ benchmark-ի կամ արտադրական պատրաստության պնդում չկա։
