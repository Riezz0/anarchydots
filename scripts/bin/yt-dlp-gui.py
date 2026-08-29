#!/usr/bin/env python3
import sys
import subprocess
import threading
import os
import re
from pathlib import Path

import gi
gi.require_version('Gtk', '4.0')
gi.require_version('Adw', '1')
from gi.repository import Gtk, Adw, GLib, Gio, Gdk

WAL = {}
CACHE = Path.home() / ".cache" / "wal" / "colors"
ANSI_RE = re.compile(r'\x1b\[[0-9;]*m')


def load_wal():
    try:
        with open(CACHE) as f:
            for i, line in enumerate(f):
                if i < 16:
                    WAL[i] = line.strip()
    except FileNotFoundError:
        defaults = [
            "#282828", "#cc241d", "#98971a", "#d79921",
            "#458588", "#b16286", "#689d6a", "#a89984",
            "#928374", "#fb4934", "#b8bb26", "#fabd2f",
            "#83a598", "#d3869b", "#8ec07c", "#ebdbb2",
        ]
        for i, col in enumerate(defaults):
            WAL[i] = col


def apply_css():
    c = WAL
    css = f"""
@define-color accent_color {c[4]};
@define-color accent_bg_color {c[4]};
@define-color accent_fg_color {c[0]};
@define-color destructive_color {c[1]};
@define-color destructive_bg_color {c[1]};
@define-color destructive_fg_color {c[15]};
@define-color success_color {c[2]};
@define-color success_bg_color {c[2]};
@define-color success_fg_color {c[0]};
@define-color warning_color {c[3]};
@define-color warning_bg_color {c[3]};
@define-color warning_fg_color {c[0]};
@define-color error_color {c[9]};
@define-color error_bg_color {c[9]};
@define-color error_fg_color {c[15]};
@define-color window_bg_color {c[0]};
@define-color window_fg_color {c[15]};
@define-color view_bg_color {c[0]};
@define-color view_fg_color {c[15]};
@define-color headerbar_bg_color {c[0]};
@define-color headerbar_fg_color {c[15]};
@define-color headerbar_border_color {c[4]};
@define-color headerbar_backdrop_color {c[0]};
@define-color headerbar_shade_color {c[4]};
@define-color card_bg_color alpha({c[8]}, 0.15);
@define-color card_fg_color {c[15]};
@define-color card_shade_color {c[0]};
@define-color dialog_bg_color {c[0]};
@define-color dialog_fg_color {c[15]};
@define-color popover_bg_color {c[0]};
@define-color popover_fg_color {c[15]};

window {{
    background-color: {c[0]} !important;
    color: {c[15]} !important;
}}

headerbar {{
    background-color: {c[0]} !important;
    color: {c[15]} !important;
    border-bottom: 1px solid {c[4]} !important;
}}

headerbar title {{
    color: {c[12]} !important;
}}

headerbar subtitle {{
    color: alpha({c[15]}, 0.5) !important;
}}

preferences-group {{
    background-color: transparent !important;
    border: none !important;
    padding: 0 !important;
    margin-bottom: 8px !important;
}}

preferences-group > label {{
    color: {c[12]} !important;
}}

.comborow {{
    background-color: transparent !important;
    border-radius: 8px !important;
}}

.comborow:hover {{
    background-color: alpha({c[4]}, 0.08) !important;
}}

actionrow {{
    background-color: transparent !important;
    border-radius: 8px !important;
}}

actionrow:hover {{
    background-color: alpha({c[4]}, 0.08) !important;
}}

entry {{
    background-color: alpha({c[8]}, 0.25) !important;
    color: {c[15]} !important;
    border: none !important;
    border-radius: 8px !important;
    padding: 8px 12px !important;
    min-height: 20px !important;
    caret-color: {c[15]} !important;
}}

entry:focus-within {{
    background-color: alpha({c[8]}, 0.35) !important;
}}

entry selection {{
    background-color: {c[4]} !important;
    color: {c[15]} !important;
}}

entry placeholder {{
    color: alpha({c[15]}, 0.6) !important;
}}

entry.flat {{
    border: none !important;
    box-shadow: none !important;
}}

button {{
    background-color: alpha({c[15]}, 0.08) !important;
    color: {c[15]} !important;
    border: 1px solid alpha({c[15]}, 0.12) !important;
    border-radius: 8px !important;
    padding: 8px 16px !important;
    min-height: 20px !important;
}}

button:hover {{
    background-color: alpha({c[4]}, 0.25) !important;
    border-color: {c[4]} !important;
}}

button:active {{
    background-color: {c[4]} !important;
    color: {c[0]} !important;
}}

button:disabled {{
    opacity: 0.35 !important;
}}

button.suggested-action {{
    background-color: {c[4]} !important;
    color: {c[0]} !important;
    border-color: {c[4]} !important;
    font-weight: bold !important;
}}

button.suggested-action:hover {{
    background-color: {c[12]} !important;
    color: {c[0]} !important;
}}

progressbar {{
    background-color: transparent !important;
    border-radius: 999px !important;
    min-height: 6px !important;
}}

progressbar progress {{
    background-color: {c[4]} !important;
    border-radius: 999px !important;
}}

progressbar trough {{
    background-color: alpha({c[15]}, 0.08) !important;
    border-radius: 999px !important;
    min-height: 6px !important;
}}

textview {{
    background-color: {c[0]} !important;
    color: {c[14]} !important;
    border: 1px solid alpha({c[15]}, 0.1) !important;
    border-radius: 8px !important;
}}

textview text {{
    background-color: {c[0]} !important;
    color: {c[14]} !important;
}}

scrolledwindow {{
    background-color: transparent !important;
}}

separator {{
    background-color: alpha({c[15]}, 0.1) !important;
}}

frame {{
    border: none !important;
    box-shadow: none !important;
}}

.url-input {{
    background-color: alpha({c[8]}, 0.25) !important;
    color: {c[15]} !important;
    border: none !important;
    border-radius: 8px !important;
    padding: 10px 14px !important;
    min-height: 24px !important;
    font-size: 14px !important;
    caret-color: {c[15]} !important;
}}

.url-input:focus-within {{
    background-color: alpha({c[8]}, 0.35) !important;
}}

.url-input,
.url-input *,
.url-input entry {{
    border: none !important;
    box-shadow: none !important;
    outline: none !important;
}}

.toast {{
    background-color: {c[4]} !important;
    color: {c[0]} !important;
    border-radius: 8px !important;
}}
"""
    provider = Gtk.CssProvider()
    provider.load_from_string(css)
    Gtk.StyleContext.add_provider_for_display(
        Gdk.Display.get_default(),
        provider,
        Gtk.STYLE_PROVIDER_PRIORITY_USER,
    )


class YtDlpWindow(Adw.ApplicationWindow):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.set_title("YouTube Video Downloader")
        self.set_default_size(740, 720)
        self.downloading = False
        self.process = None
        self._build_ui()

    def _build_ui(self):
        c = WAL

        toast_overlay = Adw.ToastOverlay()
        self.set_content(toast_overlay)

        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        toast_overlay.set_child(main_box)

        header = Adw.HeaderBar()
        header.set_title_widget(
            Adw.WindowTitle(title="YouTube Video Downloader", subtitle="yt-dlp powered")
        )
        main_box.append(header)

        toolbar_view = Adw.ToolbarView()
        toolbar_view.add_top_bar(header)
        main_box.append(toolbar_view)

        scrolled = Gtk.ScrolledWindow()
        scrolled.set_vexpand(True)
        scrolled.set_hexpand(True)
        scrolled.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        toolbar_view.set_content(scrolled)

        clamp = Adw.Clamp()
        clamp.set_maximum_size(680)
        clamp.set_margin_top(16)
        clamp.set_margin_bottom(16)
        clamp.set_margin_start(24)
        clamp.set_margin_end(24)
        scrolled.set_child(clamp)

        content = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        clamp.set_child(content)

        # --- URL input ---
        url_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        url_box.set_margin_bottom(4)

        url_label = Gtk.Label(label="URL")
        url_label.set_xalign(0)
        url_label.add_css_class("title")
        url_box.append(url_label)

        self.url_entry = Gtk.Entry()
        self.url_entry.add_css_class("url-input")
        self.url_entry.add_css_class("flat")
        self.url_entry.set_placeholder_text("Paste a YouTube or other video URL here...")
        self.url_entry.set_hexpand(True)
        self.url_entry.connect("changed", self._on_url_changed)
        url_box.append(self.url_entry)

        content.append(url_box)

        # --- Format settings ---
        format_group = Adw.PreferencesGroup(title="Format Settings")
        content.append(format_group)

        self.cookie_row = Adw.ComboRow(
            title="Browser Cookies",
            subtitle="Use browser cookies to bypass YouTube bot detection",
        )
        self.cookie_row.set_model(Gtk.StringList.new([
            "None", "Firefox", "Chromium", "Brave", "Vivaldi", "Edge", "Opera", "Chrome",
        ]))
        self.cookie_row.set_selected(0)
        format_group.add(self.cookie_row)

        self.mode_row = Adw.ComboRow(
            title="Download Mode",
            subtitle="Choose between video or audio extraction",
        )
        self.mode_row.set_model(Gtk.StringList.new(["Video", "Audio Only"]))
        self.mode_row.set_selected(0)
        self.mode_row.connect("notify::selected", self._on_mode_changed)
        format_group.add(self.mode_row)

        self.video_fmt_row = Adw.ComboRow(
            title="Video Format", subtitle="Container format for the video"
        )
        self.video_fmt_row.set_model(Gtk.StringList.new(["mp4", "mkv", "webm", "avi"]))
        self.video_fmt_row.set_selected(0)
        format_group.add(self.video_fmt_row)

        self.audio_fmt_row = Adw.ComboRow(
            title="Audio Format", subtitle="Output audio container"
        )
        self.audio_fmt_row.set_model(
            Gtk.StringList.new(["mp3", "aac", "flac", "opus", "vorbis", "m4a", "wav"])
        )
        self.audio_fmt_row.set_selected(0)
        self.audio_fmt_row.set_visible(False)
        format_group.add(self.audio_fmt_row)

        self.audio_qual_row = Adw.ComboRow(
            title="Audio Quality", subtitle="Bitrate for audio extraction"
        )
        self.audio_qual_row.set_model(
            Gtk.StringList.new(["Best", "320 kbps", "256 kbps", "192 kbps", "128 kbps", "Worst"])
        )
        self.audio_qual_row.set_selected(0)
        self.audio_qual_row.set_visible(False)
        format_group.add(self.audio_qual_row)

        # --- Save location ---
        save_group = Adw.PreferencesGroup(title="Save Location")
        content.append(save_group)

        self.save_row = Adw.ActionRow(
            title="Output Directory", subtitle=os.path.expanduser("~/Downloads")
        )
        self.save_row.set_activatable(True)
        save_icon = Gtk.Image.new_from_icon_name("folder-open-symbolic")
        save_icon.set_icon_size(Gtk.IconSize.NORMAL)
        self.save_row.add_suffix(save_icon)
        self.save_row.connect("activated", self._on_browse_clicked)
        save_group.add(self.save_row)

        self.save_path = os.path.expanduser("~/Downloads")

        # --- Buttons ---
        btn_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        btn_box.set_halign(Gtk.Align.CENTER)
        btn_box.set_margin_top(8)
        content.append(btn_box)

        self.download_btn = Gtk.Button(label="Download")
        self.download_btn.add_css_class("suggested-action")
        self.download_btn.add_css_class("pill")
        self.download_btn.set_size_request(160, -1)
        self.download_btn.connect("clicked", self._on_download_clicked)
        btn_box.append(self.download_btn)

        self.cancel_btn = Gtk.Button(label="Cancel")
        self.cancel_btn.add_css_class("pill")
        self.cancel_btn.set_size_request(120, -1)
        self.cancel_btn.set_sensitive(False)
        self.cancel_btn.connect("clicked", self._on_cancel_clicked)
        btn_box.append(self.cancel_btn)

        # --- Progress ---
        progress_row = Adw.ActionRow(title="Progress")
        self.progress_bar = Gtk.ProgressBar()
        self.progress_bar.set_show_text(True)
        self.progress_bar.set_hexpand(True)
        self.progress_bar.set_size_request(200, -1)
        progress_row.add_suffix(self.progress_bar)
        content.append(progress_row)

        sep = Gtk.Separator(orientation=Gtk.Orientation.HORIZONTAL)
        content.append(sep)

        # --- Output log ---
        output_group = Adw.PreferencesGroup(title="Output Log")
        content.append(output_group)

        self.output_view = Gtk.TextView()
        self.output_view.set_editable(False)
        self.output_view.set_wrap_mode(Gtk.WrapMode.WORD_CHAR)
        self.output_view.set_left_margin(10)
        self.output_view.set_right_margin(10)
        self.output_view.set_top_margin(10)
        self.output_view.set_bottom_margin(10)
        self.output_view.set_monospace(True)
        self.output_view.set_vexpand(True)

        scroll_output = Gtk.ScrolledWindow()
        scroll_output.set_child(self.output_view)
        scroll_output.set_vexpand(True)
        scroll_output.set_min_content_height(180)
        scroll_output.set_max_content_height(300)
        output_group.add(scroll_output)

        self.output_buffer = self.output_view.get_buffer()

    def _on_url_changed(self, entry):
        pass

    def _on_mode_changed(self, row, param):
        is_video = row.get_selected() == 0
        self.video_fmt_row.set_visible(is_video)
        self.audio_fmt_row.set_visible(not is_video)
        self.audio_qual_row.set_visible(not is_video)

    def _on_browse_clicked(self, row):
        dialog = Gtk.FileDialog()
        dialog.set_title("Choose Save Directory")
        folder = Gio.File.new_for_path(self.save_path)
        dialog.set_initial_folder(folder)

        def on_response(dialog, result):
            try:
                file = dialog.select_folder_finish(result)
                if file:
                    self.save_path = file.get_path()
                    self.save_row.set_subtitle(self.save_path)
            except GLib.Error:
                pass

        dialog.select_folder(self, None, on_response)

    def _append_output(self, text):
        def _update():
            end_iter = self.output_buffer.get_end_iter()
            self.output_buffer.insert(end_iter, text + "\n")
            mark = self.output_buffer.create_mark(
                None, self.output_buffer.get_end_iter(), False
            )
            self.output_view.scroll_to_mark(mark, 0.0, False, 0.0, 0.0)
            return False
        GLib.idle_add(_update)

    def _set_progress(self, fraction, text=""):
        def _update():
            self.progress_bar.set_fraction(fraction)
            self.progress_bar.set_text(text)
            return False
        GLib.idle_add(_update)

    def _show_toast(self, msg, timeout=3):
        toast = Adw.Toast(title=msg)
        toast.set_timeout(timeout)
        child = self.get_child()
        if isinstance(child, Adw.ToastOverlay):
            child.add_toast(toast)

    def _build_command(self):
        url = self.url_entry.get_text().strip()
        if not url:
            return None

        cmd = ["yt-dlp", "--no-colors", "--progress"]
        is_video = self.mode_row.get_selected() == 0

        cookie_browser = self.cookie_row.get_model().get_string(
            self.cookie_row.get_selected()
        )
        if cookie_browser != "None":
            cmd.extend(["--cookies-from-browser", cookie_browser.lower()])

        if is_video:
            fmt = self.video_fmt_row.get_model().get_string(
                self.video_fmt_row.get_selected()
            )
            cmd.extend(["-f", f"bestvideo[height<=1080][ext={fmt}]+bestaudio/best[height<=1080]/best"])
            cmd.extend(["--merge-output-format", fmt])
        else:
            audio_fmt = self.audio_fmt_row.get_model().get_string(
                self.audio_fmt_row.get_selected()
            )
            quality_text = self.audio_qual_row.get_model().get_string(
                self.audio_qual_row.get_selected()
            )
            if audio_fmt in ("mp3", "aac", "m4a"):
                cmd.extend(["-x", "--audio-format", audio_fmt])
            if quality_text == "Best":
                cmd.extend(["-f", "bestaudio/best"])
            elif quality_text == "Worst":
                cmd.extend(["-f", "worstaudio/worst"])
            else:
                bitrate = quality_text.replace(" kbps", "K")
                cmd.extend(["-f", f"bestaudio[abr>={bitrate}]/bestaudio/best"])

        cmd.extend(["-o", os.path.join(self.save_path, "%(title)s.%(ext)s")])
        cmd.append(url)
        return cmd

    def _on_download_clicked(self, button):
        cmd = self._build_command()
        if cmd is None:
            self._show_toast("Please enter a valid URL")
            return

        self.downloading = True
        self.download_btn.set_sensitive(False)
        self.cancel_btn.set_sensitive(True)
        self.progress_bar.set_fraction(0.0)
        self.progress_bar.set_text("Starting download...")

        self.output_buffer.set_text("")
        self._append_output("$ " + " ".join(cmd))

        thread = threading.Thread(target=self._run_download, args=(cmd,), daemon=True)
        thread.start()

    def _run_download(self, cmd):
        try:
            self.process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                universal_newlines=True,
                bufsize=1,
            )

            for line in self.process.stdout:
                if not self.downloading:
                    break
                line = line.strip()
                if line:
                    self._append_output(ANSI_RE.sub('', line))
                    if "[download]" in line and "%" in line:
                        try:
                            for part in line.split():
                                if "%" in part:
                                    pct = float(part.replace("%", "")) / 100.0
                                    self._set_progress(pct, part)
                                    break
                        except (ValueError, IndexError):
                            pass

            self.process.wait()
            rc = self.process.returncode

            if rc == 0:
                self._append_output("\nDownload completed successfully!")
                self._set_progress(1.0, "Complete")
                GLib.idle_add(self._show_toast, "Download complete!", 4)
            elif self.downloading:
                self._append_output(f"\nProcess exited with code {rc}")
                GLib.idle_add(self._show_toast, f"Error: exit code {rc}")

        except Exception as e:
            self._append_output(f"\nError: {e}")
            GLib.idle_add(self._show_toast, f"Error: {e}")
        finally:
            self.process = None
            GLib.idle_add(self._download_finished)

    def _download_finished(self):
        self.downloading = False
        self.download_btn.set_sensitive(True)
        self.cancel_btn.set_sensitive(False)
        return False

    def _on_cancel_clicked(self, button):
        if self.downloading:
            self.downloading = False
            if self.process:
                self.process.terminate()
            self._append_output("\nDownload cancelled by user")
            self._set_progress(0.0, "Cancelled")
            self._show_toast("Download cancelled")


class YtDlpApp(Adw.Application):
    def __init__(self):
        super().__init__(
            application_id="com.github.yt-dlp-gui",
            flags=Gio.ApplicationFlags.FLAGS_NONE,
        )
        self.connect("activate", self._on_activate)

    def _on_activate(self, app):
        win = YtDlpWindow(application=app)
        win.present()


def main():
    load_wal()
    apply_css()
    app = YtDlpApp()
    return app.run(sys.argv)


if __name__ == "__main__":
    main()
