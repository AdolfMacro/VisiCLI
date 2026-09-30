import os
from io import StringIO
from types import SimpleNamespace

import pytest

import visicli.app as app
from visicli.app import _parse_args, run


def test_cli_rejects_invalid_frame_count():
    with pytest.raises(SystemExit) as error:
        _parse_args(["--demo", "--frames", "0"])
    assert error.value.code == 2


def test_cli_rejects_negative_camera_index():
    with pytest.raises(SystemExit) as error:
        _parse_args(["--camera-index", "-1"])
    assert error.value.code == 2


def test_cli_enables_ascii_art_option():
    args = _parse_args(["--demo", "--ascii-art"])

    assert args.ascii_art is True


def test_cli_can_disable_live_camera_popup():
    args = _parse_args(["--no-camera-view"])

    assert args.no_camera_view is True


def test_direct_run_rejects_invalid_frame_count():
    with pytest.raises(ValueError, match="max_frames must be positive"):
        run(demo=True, max_frames=0)


def test_finite_demo_prints_dashboard_not_a_3d_scene(capsys):
    assert run(demo=True, max_frames=1) == 0
    output = capsys.readouterr().out

    assert "PROJECT MAP" in output
    assert "KEYBOARD DEMO" in output
    assert "PROJECT MAP" in output
    assert "SET ACTION" not in output
    assert "GEAR" not in output
    assert "#" not in output


def test_legacy_ascii_art_option_keeps_the_input_panel_compact(capsys):
    assert run(demo=True, max_frames=1, ascii_art=True) == 0
    output = capsys.readouterr().out

    assert "HAND --" in output
    assert "NO HAND FOUND" in output
    assert "PROJECT MAP" in output
    assert "HOLD HAND IN VIEW" in output


def test_cli_validates_python_project_directory(tmp_path):
    args = _parse_args(["--demo", "-p", str(tmp_path)])
    assert args.project == tmp_path

    with pytest.raises(SystemExit) as error:
        _parse_args(["--demo", "-p", str(tmp_path / "missing")])
    assert error.value.code == 2


def test_finite_demo_loads_project_and_preserves_input_status(tmp_path, capsys):
    project = tmp_path / "sample"
    project.mkdir()
    (project / "main.py").write_text("def run():\n    return 1\n")

    assert run(demo=True, max_frames=1, project_path=project) == 0
    output = capsys.readouterr().out

    assert "sample" in output
    assert "1 files | 1 symbols" in output
    assert "NO HAND FOUND" in output
    assert "┌─" in output
    assert "RUN PROJECT" not in output


def test_interactive_keyboard_enters_selected_file_without_initial_menu(monkeypatch, tmp_path):
    project = tmp_path / "sample"
    project.mkdir()
    (project / "main.py").write_text("def run():\n    return 1\n")
    keys = iter((b"1", b"c"))
    ready_checks = iter((True, True))
    stdin = SimpleNamespace(isatty=lambda: True, fileno=lambda: 0)

    class TtyOutput(StringIO):
        def isatty(self):
            return True

    class InputStub:
        def enable_raw_mode(self):
            pass

        def disable_raw_mode(self):
            pass

    stdout = TtyOutput()
    monkeypatch.setattr(app.sys, "stdin", stdin)
    monkeypatch.setattr(app.sys, "stdout", stdout)
    monkeypatch.setattr(app.os, "read", lambda _fd, _size: next(keys))
    monkeypatch.setattr(
        app.select,
        "select",
        lambda *_args: ([stdin], [], []) if next(ready_checks) else ([], [], []),
    )
    monkeypatch.setattr(app, "InputHandler", InputStub)
    monkeypatch.setattr(app, "_terminal_size", lambda: (100, 24))
    monkeypatch.setattr(app.time, "sleep", lambda _duration: None)

    assert run(demo=True, max_frames=2, project_path=project) == 0
    assert "Entered main.py" in stdout.getvalue()


def test_terminal_size_uses_small_reported_cell_grid(monkeypatch):
    monkeypatch.setattr(
        app.shutil,
        "get_terminal_size",
        lambda fallback: os.terminal_size((12, 6)),
    )

    assert app._terminal_size() == (12, 6)


def test_read_key_uses_single_unbuffered_byte(monkeypatch):
    monkeypatch.setattr(app.sys, "stdin", SimpleNamespace(fileno=lambda: 17))
    monkeypatch.setattr(app.os, "read", lambda descriptor, size: b"2")

    assert app._read_key() == "2"


def test_read_key_treats_eof_as_quit_signal(monkeypatch):
    monkeypatch.setattr(app.sys, "stdin", SimpleNamespace(fileno=lambda: 17))
    monkeypatch.setattr(app.os, "read", lambda descriptor, size: b"")

    assert app._read_key() is None
