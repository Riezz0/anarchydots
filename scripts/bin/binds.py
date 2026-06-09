#!/usr/bin/env python3
import gi
import os
import re
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk, Pango

class PixelPerfectShortcuts(Gtk.Window):
    def __init__(self):
        super().__init__(title="HyprBinds")
        self.lua_path = os.path.expanduser("~/.config/hypr/modules/binds.lua")
        colors = self.get_pywal_colors()
        
        self.set_default_size(700, 700)
        self.set_position(Gtk.WindowPosition.CENTER)
        self.set_border_width(20)
        
        self.apply_styles(colors)
        self.create_layout()

    def get_pywal_colors(self):
        colors = {}
        try:
            with open(os.path.expanduser("~/.cache/wal/colors")) as f:
                for i, line in enumerate(f):
                    colors[f'color{i}'] = line.strip()
        except:
            colors = {f'color{i}': "#222222" for i in range(16)}
        return colors

    def apply_styles(self, colors):
        css_provider = Gtk.CssProvider()
        # Enforce font and fixed-width column behavior
        css = f"""
        * {{ font-family: 'JetBrains Nerd Font Mono Propo'; font-size: 12px; }}
        window {{ background-color: {colors['color0']}; }}
        .category {{ color: {colors['color2']}; font-weight: bold; font-size: 1.3em; margin: 25px 0 10px 0; }}
        .header {{ color: {colors['color3']}; font-weight: bold; border-bottom: 2px solid {colors['color3']}; padding-bottom: 5px; }}
        .keybind {{ color: {colors['color4']}; font-weight: bold; min-width: 250px; }}
        .description {{ color: {colors['color7']}; }}
        """
        css_provider.load_from_data(css.encode())
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(), css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

    def create_layout(self):
        scrolled = Gtk.ScrolledWindow()
        self.add(scrolled)
        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        scrolled.add(main_box)

        all_binds = self.get_categorized_binds()
        
        order = ['terminal', 'workspaces', 'window management', 'apps', 'scratchpads', 'system', 'volume', 'other']
        for cat in order:
            if cat in all_binds and all_binds[cat]:
                lbl = Gtk.Label(label=cat.upper())
                lbl.set_xalign(0)
                lbl.get_style_context().add_class("category")
                main_box.pack_start(lbl, False, False, 0)

                # Grid: homogeneous=False ensures columns aren't forced to equal size
                grid = Gtk.Grid(column_spacing=20, row_spacing=10)
                grid.set_column_homogeneous(False)
                main_box.pack_start(grid, False, False, 0)

                # Headers
                for col, text in enumerate(["KEYBIND", "DESCRIPTION"]):
                    h = Gtk.Label(label=text)
                    h.set_xalign(0)
                    h.get_style_context().add_class("header")
                    grid.attach(h, col, 0, 1, 1)

                # Rows
                for i, (k, d) in enumerate(all_binds[cat], start=1):
                    k_lbl = Gtk.Label(label=k)
                    k_lbl.set_xalign(0)
                    k_lbl.get_style_context().add_class("keybind")
                    
                    d_lbl = Gtk.Label(label=d)
                    d_lbl.set_xalign(0)
                    d_lbl.set_line_wrap(True)
                    d_lbl.get_style_context().add_class("description")
                    d_lbl.set_hexpand(True) # Description takes remaining space
                    
                    grid.attach(k_lbl, 0, i, 1, 1)
                    grid.attach(d_lbl, 1, i, 1, 1)

    def get_categorized_binds(self):
        cats = {c: [] for c in ['terminal', 'workspaces', 'window management', 'apps', 'scratchpads', 'system', 'volume', 'other']}
        pattern = re.compile(r'hl\.bind\(\s*["\'](.*?)["\'].*?description\s*=\s*["\'](.*?)["\']', re.IGNORECASE)
        
        if os.path.exists(self.lua_path):
            with open(self.lua_path, 'r') as f:
                for line in f:
                    m = pattern.search(line)
                    if m:
                        k, d = m.groups()
                        dl = d.lower()
                        if 'volume' in dl: cats['volume'].append((k, d))
                        elif 'workspace' in dl: cats['workspaces'].append((k, d))
                        elif 'window' in dl: cats['window management'].append((k, d))
                        elif 'launch' in dl: cats['apps'].append((k, d))
                        elif 'scratchpad' in dl: cats['scratchpads'].append((k, d))
                        elif any(x in dl for x in ['session', 'lock']): cats['system'].append((k, d))
                        else: cats['other'].append((k, d))
        return cats

if __name__ == "__main__":
    win = PixelPerfectShortcuts()
    win.connect("destroy", Gtk.main_quit)
    win.show_all()
    Gtk.main()
