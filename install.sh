#!/usr/bin/env bash
set -Eeuo pipefail

PROGRAM_NAME="VisiCLI"

usage() {
    cat <<'EOF'
Usage: ./install.sh [--no-model] [--help]

Install VisiCLI for the current Linux user:
  - creates an isolated Python virtual environment under ~/.local/share/visicli
  - installs VisiCLI and its Python dependencies
  - downloads the verified hand-tracking model unless --no-model is specified
  - exposes `visicli` through ~/.local/bin and configures common user shells

Environment overrides:
  VISICLI_INSTALL_DIR   Installation directory (default: $XDG_DATA_HOME/visicli
                        or ~/.local/share/visicli)
  VISICLI_BIN_DIR       Executable directory (default: ~/.local/bin)
  PYTHON                Python 3 executable (default: python3)
EOF
}

fail() {
    printf '%s: %s\n' "$PROGRAM_NAME installer" "$*" >&2
    exit 1
}

download_model=1
while (($#)); do
    case "$1" in
        --no-model)
            download_model=0
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            fail "unknown option: $1 (try --help)"
            ;;
    esac
    shift
done

[[ "$(uname -s)" == "Linux" ]] || fail "this installer supports Linux systems."

python_command="${PYTHON:-python3}"
command -v "$python_command" >/dev/null 2>&1 ||
    fail "Python 3.10+ was not found. Install Python and its venv support, then retry."
python_path="$(command -v "$python_command")"

python_version="$("$python_path" -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')" ||
    fail "Could not query the Python interpreter at $python_path."
if ! "$python_path" -c 'import sys; raise SystemExit(sys.version_info < (3, 10))'; then
    fail "Python 3.10 or newer is required; found $python_version."
fi

project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
data_root="${XDG_DATA_HOME:-$HOME/.local/share}"
install_dir="${VISICLI_INSTALL_DIR:-$data_root/visicli}"
bin_dir="${VISICLI_BIN_DIR:-$HOME/.local/bin}"
venv_dir="$install_dir/venv"
entry_point="$venv_dir/bin/visicli"
launcher="$bin_dir/visicli"

mkdir -p -- "$install_dir" "$bin_dir"
install_dir="$(cd -- "$install_dir" && pwd -P)"
bin_dir="$(cd -- "$bin_dir" && pwd -P)"
venv_dir="$install_dir/venv"
entry_point="$venv_dir/bin/visicli"
launcher="$bin_dir/visicli"

if [[ -e "$launcher" || -L "$launcher" ]]; then
    if [[ ! -L "$launcher" || "$(readlink -- "$launcher")" != "$entry_point" ]]; then
        fail "$launcher already exists and is not this VisiCLI installation; leaving it untouched."
    fi
fi

if [[ ! -x "$venv_dir/bin/python" ]]; then
    printf 'Creating isolated environment: %s\n' "$venv_dir"
    if ! "$python_path" -m venv "$venv_dir"; then
        fail "Could not create a virtual environment. Install your distribution's Python venv/ensurepip package and retry."
    fi
fi

venv_python="$venv_dir/bin/python"
[[ -x "$venv_python" ]] ||
    fail "Virtual environment did not provide $venv_python."

printf 'Installing VisiCLI and Python dependencies...\n'
"$venv_python" -m pip install --upgrade pip ||
    fail "Could not upgrade pip in the VisiCLI environment."
"$venv_python" -m pip install "$project_root" ||
    fail "Dependency installation failed. Check network access and Python wheel support for this platform."

[[ -x "$entry_point" ]] ||
    fail "The package installed but did not create the expected command: $entry_point."

if [[ -e "$launcher" || -L "$launcher" ]]; then
    :
else
    ln -s -- "$entry_point" "$launcher"
fi

path_marker="# >>> VisiCLI user PATH >>>"
profile_line="case \":\$PATH:\" in *\":$bin_dir:\"*) ;; *) export PATH=\"$bin_dir:\$PATH\" ;; esac"
add_path_to_file() {
    local config_file="$1"
    mkdir -p -- "$(dirname -- "$config_file")"
    [[ -e "$config_file" ]] || : > "$config_file"
    if ! grep -Fq -- "$path_marker" "$config_file"; then
        {
            printf '\n%s\n' "$path_marker"
            printf '%s\n' "$profile_line"
            printf '%s\n' "# <<< VisiCLI user PATH <<<"
        } >> "$config_file"
    fi
}

add_path_to_file "$HOME/.profile"
for shell_config in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.zprofile"; do
    if [[ -e "$shell_config" ]]; then
        add_path_to_file "$shell_config"
    fi
done

fish_config="${XDG_CONFIG_HOME:-$HOME/.config}/fish/config.fish"
if command -v fish >/dev/null 2>&1 || [[ -e "$fish_config" ]]; then
    mkdir -p -- "$(dirname -- "$fish_config")"
    [[ -e "$fish_config" ]] || : > "$fish_config"
    if ! grep -Fq -- "# >>> VisiCLI user PATH >>>" "$fish_config"; then
        {
            printf '\n%s\n' "$path_marker"
            printf 'fish_add_path --path "%s"\n' "$bin_dir"
            printf '%s\n' "# <<< VisiCLI user PATH <<<"
        } >> "$fish_config"
    fi
fi

if ((download_model)); then
    printf 'Downloading and verifying the hand-landmarker model...\n'
    "$venv_python" -m visicli.download_model ||
        fail "Model download failed. VisiCLI is installed; retry with network access or run install.sh --no-model."
fi

printf '\n%s is installed for this user.\n' "$PROGRAM_NAME"
printf 'Run: %s --help\n' "$launcher"
case ":${PATH}:" in
    *":$bin_dir:"*)
        printf 'The current shell can run: visicli\n'
        ;;
    *)
        printf 'Open a new terminal (or reload your shell configuration), then run: visicli\n'
        printf 'For this terminal now, run: export PATH="%s:$PATH"\n' "$bin_dir"
        ;;
esac
