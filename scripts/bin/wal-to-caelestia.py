#!/usr/bin/env python3
"""Convert pywal cache colors into a caelestia shell scheme.

Mirrors Anarchy-Bar's Modules/Theme.qml import: a strict 1:1 mapping from
~/.cache/wal/colors.json (`special.background/foreground` + `color0-15`,
no invented blend tones). Neutrals come from color0 (base bg) and color8
(dim/bright bg); accents map 1:1 to the same palette roles your bar uses.

Reads ~/.cache/wal/colors.json (written by `wal`), writes
~/.local/state/caelestia/scheme.json. The shell hot-reloads this file.

Usage: wal-to-caelestia [theme-name]
"""

import json
import os
import re
import sys
from pathlib import Path

WAL = Path.home() / ".cache/wal/colors.json"
OUT = Path(os.getenv("XDG_STATE_HOME", Path.home() / ".local/state")) / "caelestia/scheme.json"

THEME = sys.argv[1] if len(sys.argv) > 1 else "pywal"


def parse(h: str) -> tuple[float, float, float]:
    return tuple(int(h.lstrip("#")[i : i + 2], 16) / 255 for i in (0, 2, 4))


def unparse(rgb: tuple[float, float, float]) -> str:
    return "%02X%02X%02X" % tuple(max(0, min(255, round(x * 255))) for x in rgb)


def lum(h: str) -> float:
    r, g, b = parse(h)
    return 0.299 * r + 0.587 * g + 0.114 * b


def hexonly(h: str) -> str:
    return h.lstrip("#").upper()


def blend(a: str, b: str, t: float) -> str:
    """Channel-wise linear mix from a towards b by fraction t."""
    A, B = parse(a), parse(b)
    return unparse(tuple(A[i] + (B[i] - A[i]) * t for i in range(3)))


def active_wallpaper(active: Path, default_theme: str) -> tuple[str, str]:
    """Resolve WALL from the active theme script without executing shell code."""
    variables = {
        "HOME": str(Path.home()),
        "USER_HOME": str(Path.home()),
        "THEME_NAME": default_theme,
    }
    assignment = re.compile(r"^\s*(THEME_NAME|USER_HOME|THEME_DIR|WALL)\s*=\s*(.*?)\s*$")
    reference = re.compile(r"\$(?:\{([A-Za-z_][A-Za-z0-9_]*)\}|([A-Za-z_][A-Za-z0-9_]*))")

    if active.is_file():
        for line in active.read_text().splitlines():
            match = assignment.match(line)
            if not match:
                continue

            key, value = match.groups()
            value = value.strip()
            if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
                value = value[1:-1]

            # Theme scripts commonly define WALL in terms of THEME_DIR, and
            # THEME_DIR in terms of HOME/USER_HOME and THEME_NAME.
            for _ in range(len(variables) + 1):
                expanded = reference.sub(
                    lambda ref: variables.get(ref.group(1) or ref.group(2), ref.group(0)),
                    value,
                )
                if expanded == value:
                    break
                value = expanded

            variables[key] = os.path.expanduser(value)

    return variables.get("THEME_NAME", default_theme), variables.get("WALL", "")


def main() -> None:
    wal = json.loads(WAL.read_text())
    # bare hex (no '#') — Colours.qml prepends its own '#'
    bg = wal["special"]["background"].lstrip("#")
    fg = wal["special"]["foreground"].lstrip("#")
    c = [wal["colors"][f"color{i}"].lstrip("#") for i in range(16)]

    c0, c1, c2, c3, c4, c5, c6, c7 = c[0:8]
    c8, c9, c10, c11, c12, c13, c14, c15 = c[8:16]

    light = lum(bg) > 0.5

    # flat surfaces — exactly like Anarchy-Bar's bar background:
    #   theme.background = wal special.background, one solid color.
    # No invented blends; bg-family = color0 flat (bar background look);
    # state surfaces get subtle neutral lifts, accent containers are dark
    # accent tints — never the warm color8.
    def step(t: float) -> str:
        """Dark neutral between bg and fg — only subtle lifts, no c8 warmth."""
        return blend(c0, fg, t)

    def acc_tint(accent: str, t: float) -> str:
        """Dark container of a pywal accent over the flat background."""
        return blend(c0, accent, t)

    def acc_on(accent: str) -> str:
        """Bright readable text for accented containers."""
        return blend(accent, fg, 0.65)

    scheme = {
        "name": "pywal",
        "flavour": THEME,
        "mode": "light" if light else "dark",
        "variant": "content",
        "colours": {
            # neutrals — flat wal background (same as Anarchy-Bar)
            "background": bg,
            "base": c0,
            "mantle": c0,
            "crust": c0,
            "surface": c0,
            "surfaceDim": c0,
            "surfaceBright": step(0.18),
            "surface0": c0,
            "surface1": step(0.10),
            "surface2": step(0.18),
            "surfaceContainerLowest": c0,
            "surfaceContainerLow": c0,
            "surfaceContainer": c0,
            "surfaceContainerHigh": c0,
            "surfaceContainerHighest": c0,
            "surfaceVariant": step(0.12),
            "onBackground": fg,
            "text": fg,
            "subtext1": c7,
            "subtext0": blend(fg, c0, 0.50),
            "overlay0": blend(fg, c0, 0.60),
            "overlay1": blend(fg, c0, 0.65),
            "overlay2": blend(fg, c0, 0.60),
            "onSurface": fg,
            "onSurfaceVariant": c7,
            "inverseSurface": fg,
            "inverseOnSurface": bg,
            "inversePrimary": c8,
            "outline": c7 if light else c7,
            "outlineVariant": step(0.35),
            "shadow": c0,
            "scrim": c0,
            # primary (accent color4, matching the bar's main accent usage)
            "primary": c4,
            "primaryDim": c12,
            "onPrimary": c0,
            "primaryContainer": c8,
            "onPrimaryContainer": fg,
            "primaryFixed": c12,
            "primaryFixedDim": c12,
            "onPrimaryFixed": c0,
            "onPrimaryFixedVariant": c4,
            "primary_paletteKeyColor": c4,
            # secondary (accent color2)
            "secondary": c2,
            "secondaryDim": c10,
            "onSecondary": c0,
            "secondaryContainer": c8,
            "onSecondaryContainer": fg,
            "secondaryFixed": c10,
            "secondaryFixedDim": c10,
            "onSecondaryFixed": c0,
            "onSecondaryFixedVariant": c2,
            "secondary_paletteKeyColor": c2,
            # tertiary (accent color5)
            "tertiary": c5,
            "tertiaryDim": c13,
            "onTertiary": c0,
            "tertiaryContainer": c8,
            "onTertiaryContainer": fg,
            "tertiaryFixed": c13,
            "tertiaryFixedDim": c13,
            "onTertiaryFixed": c0,
            "onTertiaryFixedVariant": c5,
            "tertiary_paletteKeyColor": c5,
            # error (accent color1)
            "error": c1,
            "errorDim": c9,
            "onError": c0,
            "errorContainer": c8,
            "onErrorContainer": fg,
            "errorPaletteKeyColor": c1,
            # success (accent color2)
            "success": c2,
            "onSuccess": c0,
            "successContainer": c8,
            "onSuccessContainer": c2,
            # catppuccin-style aliases, pywal-hue faithful
            "blue": c4,
            "green": c2,
            "yellow": c3,
            "red": c1,
            "maroon": c1,
            "peach": c3,
            "pink": c5,
            "mauve": c5,
            "lavender": c4,
            "teal": c6,
            "sky": c6,
            "sapphire": c6,
            "flamingo": c1,
            "rosewater": fg,
            # links / status pairs
            "klink": c4,
            "klinkSelection": c8,
            "kvisited": c5,
            "kvisitedSelection": c8,
            "knegative": c1,
            "knegativeSelection": c8,
            "kneutral": c3,
            "kneutralSelection": c8,
            "kpositive": c2,
            "kpositiveSelection": c8,
        },
    }

    # terminal colors — faithful copy
    for i in range(16):
        scheme["colours"][f"term{i}"] = hexonly(c[i])

    OUT.parent.mkdir(parents=True, exist_ok=True)
    # NOTE: write in-place (not atomic rename) — the shell's FileView watch
    # breaks on atomic renames, same issue as Anarchy-Bar's comment in
    # Modules/Theme.qml. We also poll reload() on the QML side.
    OUT.write_text(json.dumps(scheme))

    # register the active wallpaper with the shell. IMPORTANT: point at the
    # per-THEME image (the active theme's WAL target), not Wall.png — the
    # shell only reloads when the source PATH changes, and Wall.png gets
    # overwritten in place, which would leave the shell stuck on the last
    # wallpaper. The source path comes from the active theme script's WALL=.
    active = Path.home() / ".local/share/themes/hypr-theme-active.sh"
    theme_name, wall = active_wallpaper(active, THEME)
    if not wall or not os.path.exists(wall):
        wall = os.path.expanduser("~/.config/activebg/Wall.png")
    if os.path.exists(wall):
        wall_state = OUT.parent / "wallpaper"
        wall_state.mkdir(parents=True, exist_ok=True)
        current = wall_state / "path.txt"
        want = str(wall)
        try:
            needs = current.read_text().strip() != want
        except OSError:
            needs = True
        if needs:
            current.write_text(want)
            # change mtime of thumbnail too so pickers refresh
            try:
                thumb = wall_state / "thumbnail.jpg"
                thumb.unlink(missing_ok=True)
                thumb.symlink_to(wall)
            except OSError:
                pass

    print(f"wrote {OUT} ({THEME}, {'light' if light else 'dark'})")


if __name__ == "__main__":
    main()
