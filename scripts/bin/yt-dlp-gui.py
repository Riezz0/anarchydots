#!/usr/bin/env python3
import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk, GLib, Gio
import subprocess
import threading
import os
import json
from pathlib import Path

COLORS = {}
CACHE_PATH = Path.home() / ".cache" / "wal" / "colors"

def load_colors():
    try:
        with open(CACHE_PATH) as f:
            for i, line in enumerate(f):
                if i < 16:
                    COLORS[f'color{i}'] = line.strip()
    except FileNotFoundError:
        COLORS.update({
            'color0': '#282828', 'color1': '#cc241d', 'color2': '#98971a',
            'color3': '#d79921', 'color4': '#458588', 'color5': '#b16286',
            'color6': '#689d6a', 'color7': '#a89984', 'color8': '#928374',
            'color9': '#fb4934', 'color10': '#b8bb26', 'color11': '#fabd2f',
            'color12': '#83a598', 'color13': '#d3869b', 'color14': '#8ec07c',
            'color15': '#ebdbb2'
        })

def apply_css():
    css = f"""
    window {{
        background-color: {COLORS.get('color0', '#282828')};
    }}
    .header {{
        background-color: alpha({COLORS.get('color4', '#458588')}, 0.85);
        border-bottom: 2px solid {COLORS.get('color4', '#458588')};
        border-radius: 5px;
    }}
    .title-label {{
        color: {COLORS.get('color15', '#ebdbb2')};
        font-weight: bold;
        font-size: 14px;
    }}
    .url-entry {{
        background-color: {COLORS.get('color0', '#282828')};
        color: {COLORS.get('color15', '#ebdbb2')};
        border: 2px solid {COLORS.get('color4', '#458588')};
        border-radius: 5px;
        padding: 8px;
        font-size: 12px;
    }}
    .url-entry:focus {{
        border-color: {COLORS.get('color12', '#83a598')};
    }}
    .combo-box {{
        background-color: {COLORS.get('color0', '#282828')};
        color: {COLORS.get('color15', '#ebdbb2')};
        border: 2px solid {COLORS.get('color4', '#458588')};
        border-radius: 5px;
        padding: 5px;
    }}
    .radio-button {{
        color: {COLORS.get('color15', '#ebdbb2')};
        padding: 5px;
    }}
    .radio-button label {{
        color: {COLORS.get('color15', '#ebdbb2')};
    }}
    .download-button {{
        background-color: {COLORS.get('color2', '#98971a')};
        color: {COLORS.get('color0', '#282828')};
        border: 2px solid {COLORS.get('color10', '#b8bb26')};
        border-radius: 5px;
        padding: 10px 20px;
        font-weight: bold;
        font-size: 12px;
    }}
    .download-button:hover {{
        background-color: {COLORS.get('color10', '#b8bb26')};
    }}
    .download-button:disabled {{
        background-color: alpha({COLORS.get('color8', '#928374')}, 0.5);
        color: alpha({COLORS.get('color15', '#ebdbb2')}, 0.5);
        border-color: alpha({COLORS.get('color4', '#458588')}, 0.3);
    }}
    .output-view {{
        background-color: {COLORS.get('color0', '#282828')};
        color: {COLORS.get('color14', '#8ec07c')};
        border: 2px solid {COLORS.get('color4', '#458588')};
        border-radius: 5px;
        padding: 8px;
        font-family: monospace;
        font-size: 11px;
    }}
    .progress-bar {{
        background-color: {COLORS.get('color0', '#282828')};
        border: 1px solid {COLORS.get('color4', '#458588')};
        border-radius: 5px;
    }}
    .progress-bar trough {{
        background-color: alpha({COLORS.get('color8', '#928374')}, 0.3);
    }}
    .progress-bar progress {{
        background-color: {COLORS.get('color4', '#458588')};
    }}
    .label {{
        color: {COLORS.get('color15', '#ebdbb2')};
    }}
    .frame {{
        border: 2px solid {COLORS.get('color4', '#458588')};
        border-radius: 5px;
        padding: 10px;
    }}
    .separator {{
        background-color: alpha({COLORS.get('color4', '#458588')}, 0.5);
    }}
    .save-box {{
        border: 1px solid {COLORS.get('color4', '#458588')};
        border-radius: 5px;
        padding: 5px;
    }}
    """
    css_provider = Gtk.CssProvider()
    css_provider.load_from_data(css.encode())
    Gtk.StyleContext.add_provider_for_screen(
        Gdk.Screen.get_default(),
        css_provider,
        Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
    )

class YtDlpGui(Gtk.Window):
    def __init__(self):
        super().__init__(title="yt-dlp downloader")
        self.set_default_size(700, 580)
        self.set_resizable(True)

        self.downloading = False
        self.process = None

        self.create_ui()
        self.connect("destroy", self.on_destroy)

    def create_ui(self):
        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        self.add(main_box)

        header = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        header.get_style_context().add_class("header")
        header.set_margin_start(5)
        header.set_margin_end(5)
        header.set_margin_top(5)
        header.set_margin_bottom(10)
        header.set_halign(Gtk.Align.CENTER)
        header.set_valign(Gtk.Align.CENTER)
        header.set_size_request(-1, 50)
        main_box.pack_start(header, False, False, 0)

        title = Gtk.Label(label="yt-dlp downloader")
        title.get_style_context().add_class("title-label")
        header.pack_start(title, False, False, 20)

        content_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=10)
        content_box.set_margin_start(15)
        content_box.set_margin_end(15)
        content_box.set_margin_top(5)
        content_box.set_margin_bottom(10)
        main_box.pack_start(content_box, True, True, 0)

        url_frame = Gtk.Frame()
        url_frame.get_style_context().add_class("frame")
        content_box.pack_start(url_frame, False, False, 0)

        url_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        url_box.set_margin_start(10)
        url_box.set_margin_end(10)
        url_box.set_margin_top(10)
        url_box.set_margin_bottom(10)
        url_frame.add(url_box)

        url_label = Gtk.Label(label="URL")
        url_label.get_style_context().add_class("label")
        url_label.set_halign(Gtk.Align.START)
        url_box.pack_start(url_label, False, False, 0)

        self.url_entry = Gtk.Entry()
        self.url_entry.get_style_context().add_class("url-entry")
        self.url_entry.set_placeholder_text("Enter YouTube URL...")
        url_box.pack_start(self.url_entry, False, False, 0)

        options_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=15)
        options_box.set_margin_top(5)
        options_box.set_margin_bottom(5)
        content_box.pack_start(options_box, False, False, 0)

        mode_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        mode_frame = Gtk.Frame(label=" Download Mode ")
        mode_frame.get_style_context().add_class("frame")
        mode_frame.add(mode_box)
        options_box.pack_start(mode_frame, True, True, 0)

        self.mode_video = Gtk.RadioButton.new_with_label(None, "Video")
        self.mode_video.get_style_context().add_class("radio-button")
        self.mode_video.connect("toggled", self.on_mode_changed)
        mode_box.pack_start(self.mode_video, False, False, 0)

        self.mode_audio = Gtk.RadioButton.new_with_label_from_widget(self.mode_video, "Audio Only")
        self.mode_audio.get_style_context().add_class("radio-button")
        self.mode_audio.connect("toggled", self.on_mode_changed)
        mode_box.pack_start(self.mode_audio, False, False, 0)

        format_stack = Gtk.Stack()
        format_stack.set_transition_type(Gtk.StackTransitionType.SLIDE_LEFT_RIGHT)
        format_stack.set_transition_duration(200)
        options_box.pack_start(format_stack, True, True, 0)

        video_format_outer = Gtk.Frame(label=" Video Format ")
        video_format_outer.get_style_context().add_class("frame")
        format_stack.add_named(video_format_outer, "video")
        video_format_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        video_format_outer.add(video_format_box)

        fmt_label = Gtk.Label(label="Format")
        fmt_label.get_style_context().add_class("label")
        fmt_label.set_halign(Gtk.Align.START)
        video_format_box.pack_start(fmt_label, False, False, 0)

        self.video_format_combo = Gtk.ComboBoxText()
        self.video_format_combo.get_style_context().add_class("combo-box")
        for fmt in ["mp4", "mkv", "webm", "avi"]:
            self.video_format_combo.append_text(fmt)
        self.video_format_combo.set_active(0)
        video_format_box.pack_start(self.video_format_combo, False, False, 0)

        vid_quality_label = Gtk.Label(label="Quality")
        vid_quality_label.get_style_context().add_class("label")
        vid_quality_label.set_halign(Gtk.Align.START)
        video_format_box.pack_start(vid_quality_label, False, False, 0)

        self.video_quality_combo = Gtk.ComboBoxText()
        self.video_quality_combo.get_style_context().add_class("combo-box")
        for q in ["2160p (4K)", "1440p (2K)", "1080p (Full HD)", "720p (HD)", "480p", "360p", "Best available"]:
            self.video_quality_combo.append_text(q)
        self.video_quality_combo.set_active(6)
        video_format_box.pack_start(self.video_quality_combo, False, False, 0)

        audio_format_outer = Gtk.Frame(label=" Audio Format ")
        audio_format_outer.get_style_context().add_class("frame")
        format_stack.add_named(audio_format_outer, "audio")
        audio_format_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5)
        audio_format_outer.add(audio_format_box)

        audio_fmt_label = Gtk.Label(label="Format")
        audio_fmt_label.get_style_context().add_class("label")
        audio_fmt_label.set_halign(Gtk.Align.START)
        audio_format_box.pack_start(audio_fmt_label, False, False, 0)

        self.audio_format_combo = Gtk.ComboBoxText()
        self.audio_format_combo.get_style_context().add_class("combo-box")
        for fmt in ["mp3", "aac", "flac", "opus", "vorbis", "m4a", "wav"]:
            self.audio_format_combo.append_text(fmt)
        self.audio_format_combo.set_active(0)
        audio_format_box.pack_start(self.audio_format_combo, False, False, 0)

        audio_quality_label = Gtk.Label(label="Quality")
        audio_quality_label.get_style_context().add_class("label")
        audio_quality_label.set_halign(Gtk.Align.START)
        audio_format_box.pack_start(audio_quality_label, False, False, 0)

        self.audio_quality_combo = Gtk.ComboBoxText()
        self.audio_quality_combo.get_style_context().add_class("combo-box")
        for q in ["Best", "320 kbps", "256 kbps", "192 kbps", "128 kbps", "Worst"]:
            self.audio_quality_combo.append_text(q)
        self.audio_quality_combo.set_active(0)
        audio_format_box.pack_start(self.audio_quality_combo, False, False, 0)

        self.format_stack = format_stack

        save_frame = Gtk.Frame(label=" Save To ")
        save_frame.get_style_context().add_class("frame")
        save_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        save_box.set_margin_start(10)
        save_box.set_margin_end(10)
        save_box.set_margin_top(5)
        save_box.set_margin_bottom(5)
        save_frame.add(save_box)
        options_box.pack_start(save_frame, True, True, 0)

        self.save_entry = Gtk.Entry()
        self.save_entry.get_style_context().add_class("url-entry")
        self.save_entry.set_text(os.path.expanduser("~/Downloads"))
        save_box.pack_start(self.save_entry, True, True, 0)

        browse_button = Gtk.Button(label="Browse")
        browse_button.get_style_context().add_class("download-button")
        browse_button.connect("clicked", self.on_browse_clicked)
        save_box.pack_start(browse_button, False, False, 0)

        controls_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        controls_box.set_halign(Gtk.Align.CENTER)
        content_box.pack_start(controls_box, False, False, 0)

        self.download_button = Gtk.Button(label="Download")
        self.download_button.get_style_context().add_class("download-button")
        self.download_button.connect("clicked", self.on_download_clicked)
        self.download_button.set_size_request(150, -1)
        controls_box.pack_start(self.download_button, False, False, 0)

        self.cancel_button = Gtk.Button(label="Cancel")
        self.cancel_button.get_style_context().add_class("download-button")
        self.cancel_button.connect("clicked", self.on_cancel_clicked)
        self.cancel_button.set_size_request(100, -1)
        self.cancel_button.set_sensitive(False)
        controls_box.pack_start(self.cancel_button, False, False, 0)

        self.progress_bar = Gtk.ProgressBar()
        self.progress_bar.get_style_context().add_class("progress-bar")
        self.progress_bar.set_show_text(True)
        content_box.pack_start(self.progress_bar, False, False, 0)

        output_frame = Gtk.Frame(label=" Output ")
        output_frame.get_style_context().add_class("frame")
        output_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        output_frame.add(output_box)
        content_box.pack_start(output_frame, True, True, 0)

        self.output_view = Gtk.TextView()
        self.output_view.get_style_context().add_class("output-view")
        self.output_view.set_editable(False)
        self.output_view.set_wrap_mode(Gtk.WrapMode.WORD_CHAR)
        self.output_view.set_left_margin(5)
        self.output_view.set_right_margin(5)
        self.output_view.set_top_margin(5)
        self.output_view.set_bottom_margin(5)

        scroll = Gtk.ScrolledWindow()
        scroll.set_vexpand(True)
        scroll.set_hexpand(True)
        scroll.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC)
        scroll.add(self.output_view)
        output_box.pack_start(scroll, True, True, 0)

        self.output_buffer = self.output_view.get_buffer()

    def on_mode_changed(self, button):
        if button.get_active():
            if button == self.mode_video:
                self.format_stack.set_visible_child_name("video")
            else:
                self.format_stack.set_visible_child_name("audio")

    def on_browse_clicked(self, button):
        dialog = Gtk.FileChooserDialog(
            title="Choose Save Directory",
            parent=self,
            action=Gtk.FileChooserAction.SELECT_FOLDER
        )
        dialog.add_button("Cancel", Gtk.ResponseType.CANCEL)
        dialog.add_button("Open", Gtk.ResponseType.OK)
        dialog.set_current_folder(os.path.expanduser("~/Downloads"))

        response = dialog.run()
        if response == Gtk.ResponseType.OK:
            self.save_entry.set_text(dialog.get_filename())
        dialog.destroy()

    def append_output(self, text):
        def _update():
            end_iter = self.output_buffer.get_end_iter()
            self.output_buffer.insert(end_iter, text + "\n")
            self.output_view.scroll_to_iter(self.output_buffer.get_end_iter(), 0.0, False, 0.0, 0.0)
            return False
        GLib.idle_add(_update)

    def set_progress(self, fraction, text=""):
        def _update():
            self.progress_bar.set_fraction(fraction)
            self.progress_bar.set_text(text)
            return False
        GLib.idle_add(_update)

    def build_command(self):
        url = self.url_entry.get_text().strip()
        if not url:
            return None

        save_dir = self.save_entry.get_text().strip()
        is_video = self.mode_video.get_active()

        cmd = ["yt-dlp", "--no-colors"]

        if is_video:
            fmt = self.video_format_combo.get_active_text()
            quality_text = self.video_quality_combo.get_active_text()

            if quality_text == "Best available":
                fmt_str = "bestvideo[ext=" + fmt + "]+bestaudio/best"
            else:
                res = quality_text.split(" ")[0].replace("p", "")
                fmt_str = f"bestvideo[height<={res}][ext={fmt}]+bestaudio/best"

            cmd.extend(["-f", fmt_str])
            cmd.extend(["--merge-output-format", fmt])
            cmd.extend(["-o", os.path.join(save_dir, "%(title)s.%(ext)s")])
        else:
            audio_fmt = self.audio_format_combo.get_active_text()
            quality_text = self.audio_quality_combo.get_active_text()

            if audio_fmt in ["mp3", "aac", "m4a"]:
                cmd.extend(["-x", "--audio-format", audio_fmt])

            if quality_text == "Best":
                cmd.extend(["-f", "bestaudio/best"])
            elif quality_text == "Worst":
                cmd.extend(["-f", "worstaudio/worst"])
            else:
                bitrate = quality_text.replace(" kbps", "K")
                cmd.extend(["-f", f"bestaudio[abr>={bitrate}]/bestaudio/best"])

            cmd.extend(["-o", os.path.join(save_dir, "%(title)s.%(ext)s")])

        cmd.append(url)
        return cmd

    def on_download_clicked(self, button):
        cmd = self.build_command()
        if cmd is None:
            self.append_output("Error: Please enter a valid URL")
            return

        self.downloading = True
        self.download_button.set_sensitive(False)
        self.cancel_button.set_sensitive(True)
        self.url_entry.set_sensitive(False)
        self.progress_bar.set_fraction(0.0)
        self.progress_bar.set_text("Starting download...")

        self.output_buffer.set_text("")
        self.append_output(" ".join(cmd))

        thread = threading.Thread(target=self.run_download, args=(cmd,), daemon=True)
        thread.start()

    def run_download(self, cmd):
        try:
            self.process = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                universal_newlines=True,
                bufsize=1
            )

            for line in self.process.stdout:
                if not self.downloading:
                    break
                line = line.strip()
                if line:
                    self.append_output(line)
                    if "[download]" in line and "%" in line:
                        try:
                            parts = line.split()
                            for part in parts:
                                if "%" in part:
                                    pct = float(part.replace("%", "")) / 100.0
                                    self.set_progress(pct, part)
                                    break
                        except (ValueError, IndexError):
                            pass

            self.process.wait()
            rc = self.process.returncode

            if rc == 0:
                self.append_output("\nDownload completed successfully!")
                self.set_progress(1.0, "Complete")
            elif self.downloading:
                self.append_output(f"\nProcess exited with code {rc}")

        except Exception as e:
            self.append_output(f"\nError: {str(e)}")
        finally:
            self.process = None
            GLib.idle_add(self.download_finished)

    def download_finished(self):
        self.downloading = False
        self.download_button.set_sensitive(True)
        self.cancel_button.set_sensitive(False)
        self.url_entry.set_sensitive(True)
        return False

    def on_cancel_clicked(self, button):
        if self.downloading:
            self.downloading = False
            if self.process:
                self.process.terminate()
            self.append_output("\nDownload cancelled by user")
            self.set_progress(0.0, "Cancelled")

    def on_destroy(self, widget):
        if self.process:
            self.process.terminate()
        Gtk.main_quit()

if __name__ == "__main__":
    load_colors()
    apply_css()
    win = YtDlpGui()
    win.show_all()
    Gtk.main()
