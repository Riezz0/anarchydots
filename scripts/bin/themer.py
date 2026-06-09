#!/usr/bin/env python3
"""
Hyprland Theme Switcher (wxPython + pywal live reload)
----------------------------------------------------
• Scans ~/.config/.hypr-themes
• Compact, responsive thumbnail grid (auto-wrap + scroll)
• UI colors from current pywal scheme (LIVE reload)
• Hover accent effect (pywal accent)
• ACTIVE THEME indicator (border)
• Instant SEARCH / FILTER box
• LIVE theme detection (add/remove themes at runtime)
• On click, executes the theme's *.sh script and closes app

IMPORTANT:
• Requires wxPython (system-wide)
• Uses pywal cache (~/.cache/wal/colors.json)
"""

# ---------------- SAFE IMPORT ----------------
import sys
import json
from pathlib import Path
import subprocess

try:
    import wx
except ModuleNotFoundError:
    print("\n[ERROR] wxPython is not installed.\n")
    print("Install instructions:")
    print("  Arch Linux : sudo pacman -S python-wxpython")
    print("  Ubuntu     : sudo apt install python3-wxgtk4.0")
    print("  Pip (user) : pip install --user wxPython")
    sys.exit(1)
# ---------------------------------------------

# ---------------- CONFIG ----------------
THEME_ROOT = Path.home() / ".config/.hypr-themes"
WAL_COLORS = Path.home() / ".cache/wal/colors.json"
THUMB_NAMES = ["thumbnail.png", "thumbnail.jpg", "thumbnail.jpeg", "thumbnail.webp"]
THUMB_SIZE = (200, 120)
CARD_PADDING = 4
GRID_GAP = 8
MIN_CARD_WIDTH = 220
WAL_POLL_INTERVAL_MS = 1000
# ----------------------------------------

def load_pywal_colors():
    fallback = {
        "background": "#1e1e2e",
        "foreground": "#cdd6f4",
        "color0": "#11111b",
        "color4": "#89b4fa",
    }

    if not WAL_COLORS.exists():
        return fallback

    try:
        data = json.loads(WAL_COLORS.read_text())
        return {
            "background": data.get("special", {}).get("background", fallback["background"]),
            "foreground": data.get("special", {}).get("foreground", fallback["foreground"]),
            "color0": data.get("colors", {}).get("color0", fallback["color0"]),
            "color4": data.get("colors", {}).get("color4", fallback["color4"]),
        }
    except Exception:
        return fallback

COLORS = load_pywal_colors()
ACTIVE_THEME = None

def _self_test():
    assert THEME_ROOT.exists(), f"Theme root not found: {THEME_ROOT}"
    assert THEME_ROOT.is_dir(), "Theme root is not a directory"

# ---------------- THEME CARD ----------------
class ThemeCard(wx.Panel):
    def __init__(self, parent, theme_path: Path):
        super().__init__(parent)
        self.theme_path = theme_path
        self.theme_name = theme_path.name
        self.script = self.find_script()
        self.hovered = False
        self.build_ui()

    def find_script(self):
        for f in self.theme_path.glob("*.sh"):
            if f.name.startswith(self.theme_name):
                return f
        return None

    def find_thumbnail(self):
        for name in THUMB_NAMES:
            p = self.theme_path / name
            if p.exists():
                return p
        return None

    def build_ui(self):
        sizer = wx.BoxSizer(wx.VERTICAL)

        thumb_path = self.find_thumbnail()
        if thumb_path:
            img = wx.Image(str(thumb_path), wx.BITMAP_TYPE_ANY)
            img = img.Scale(*THUMB_SIZE, wx.IMAGE_QUALITY_HIGH)
            self.bmp = wx.StaticBitmap(self, bitmap=wx.Bitmap(img))
        else:
            self.bmp = wx.StaticText(self, label="No Thumbnail", style=wx.ALIGN_CENTER)
            self.bmp.SetMinSize(THUMB_SIZE)

        self.name = wx.StaticText(self, label=self.theme_name, style=wx.ALIGN_CENTER)
        self.name.SetFont(wx.Font(10, wx.FONTFAMILY_DEFAULT, wx.FONTSTYLE_NORMAL, wx.FONTWEIGHT_BOLD))

        for w in (self, self.bmp, self.name):
            w.Bind(wx.EVT_LEFT_UP, self.on_click)
            w.Bind(wx.EVT_ENTER_WINDOW, self.on_hover)
            w.Bind(wx.EVT_LEAVE_WINDOW, self.on_leave)

        sizer.Add(self.bmp, 0, wx.ALL | wx.CENTER, CARD_PADDING)
        sizer.Add(self.name, 0, wx.BOTTOM | wx.CENTER, CARD_PADDING)
        self.SetSizer(sizer)
        self.apply_colors()

    def apply_colors(self):
        global ACTIVE_THEME
        is_active = ACTIVE_THEME == self.theme_name
        bg = COLORS["color4"] if self.hovered else COLORS["background"]
        self.SetBackgroundColour(bg)
        self.name.SetForegroundColour(COLORS["foreground"])

        if is_active:
            self.SetWindowStyle(wx.BORDER_SIMPLE)
            self.SetBackgroundColour(COLORS["color4"])
        else:
            self.SetWindowStyle(wx.BORDER_NONE)

        if isinstance(self.bmp, wx.StaticText):
            self.bmp.SetBackgroundColour(COLORS["color0"])
            self.bmp.SetForegroundColour(COLORS["foreground"])
        self.Refresh()

    def on_hover(self, _):
        self.hovered = True
        self.apply_colors()

    def on_leave(self, _):
        self.hovered = False
        self.apply_colors()

    def on_click(self, _):
        global ACTIVE_THEME
        if self.script:
            ACTIVE_THEME = self.theme_name
            subprocess.Popen(["bash", str(self.script)])
            # Close the main window after clicking
            top_level = self.GetTopLevelParent()
            if top_level:
                top_level.Close()

# ---------------- THEME SWITCHER ----------------
class ThemeSwitcher(wx.Frame):
    def __init__(self):
        super().__init__(None, title="HyprThemer", size=(900, 650))

        self.panel = wx.Panel(self)
        self.panel.SetBackgroundColour(COLORS["background"])

        self.search = wx.SearchCtrl(self.panel, style=wx.TE_PROCESS_ENTER)
        self.search.ShowCancelButton(True)
        self.search.Bind(wx.EVT_TEXT, self.on_search)

        self.scroll = wx.ScrolledWindow(self.panel, style=wx.VSCROLL)
        self.scroll.SetScrollRate(0, 20)
        self.scroll.SetBackgroundColour(COLORS["background"])

        self.cards = []

        self.populate_cards()

        layout = wx.BoxSizer(wx.VERTICAL)
        layout.Add(self.search, 0, wx.ALL | wx.EXPAND, 8)
        layout.Add(self.scroll, 1, wx.ALL | wx.EXPAND, 4)
        self.panel.SetSizer(layout)

        # pywal live reload
        self._wal_mtime = WAL_COLORS.stat().st_mtime if WAL_COLORS.exists() else 0
        self.timer = wx.Timer(self)
        self.Bind(wx.EVT_TIMER, self.on_wal_check, self.timer)
        self.timer.Start(WAL_POLL_INTERVAL_MS)

        # filesystem watcher
        wx.CallAfter(self.init_fs_watcher)

        self.Centre()
        self.Show()

    def init_fs_watcher(self):
        try:
            self.watcher = wx.FileSystemWatcher()
            self.watcher.AddTree(str(THEME_ROOT))
            self.Bind(wx.EVT_FSWATCHER, self.on_fs_event)
        except Exception as e:
            print(f"[WARN] FileSystemWatcher disabled: {e}")

    def populate_cards(self, query: str = ""):
        self.scroll.DestroyChildren()
        self.cards.clear()
        self.grid = wx.WrapSizer(wx.HORIZONTAL)

        for theme in sorted(THEME_ROOT.iterdir()):
            if theme.is_dir() and query.lower() in theme.name.lower():
                card = ThemeCard(self.scroll, theme)
                card.SetMinSize((220, -1))
                self.cards.append(card)
                self.grid.Add(card, 0, wx.ALL, 8)

        self.scroll.SetSizer(self.grid)
        self.scroll.Layout()

    def on_search(self, event):
        self.populate_cards(event.GetString())

    def on_fs_event(self, _):
        self.populate_cards(self.search.GetValue())

    def on_wal_check(self, _):
        if not WAL_COLORS.exists():
            return
        mtime = WAL_COLORS.stat().st_mtime
        if mtime != self._wal_mtime:
            self._wal_mtime = mtime
            self.reload_colors()

    def reload_colors(self):
        global COLORS
        COLORS = load_pywal_colors()
        self.panel.SetBackgroundColour(COLORS["background"])
        self.scroll.SetBackgroundColour(COLORS["background"])
        for card in self.cards:
            card.apply_colors()
        self.Refresh()

# ---------------- MAIN ----------------
if __name__ == "__main__":
    _self_test()
    app = wx.App(False)
    window = ThemeSwitcher()
    app.MainLoop()

