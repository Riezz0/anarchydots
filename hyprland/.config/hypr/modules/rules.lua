-- Global
local theme = require("modules.colors")
hl.window_rule({name = "globalrules", match = { class = ".*",
}, animation = "slide top",})

-- Portals
hl.window_rule({ name = "portal-gtkrules", match = { class = "xdg-desktop-portal-gtk" },
float = true, size = "1000 500", center = true, border_size = 2, opacity = "1", 
animation = "slide top", border_color = { colors = { theme.color2, theme.color2 } } })

-- Nautilus
hl.window_rule({ name = "nautilusrules", match = { class = "org.gnome.Nautilus" },float = true, size = "1200 700", 
center = true, border_size = 2, opacity = "1", animation = "slide top",
border_color = { colors = { theme.color2, theme.color2 } } })

-- Neovim
hl.window_rule({ name = "nvimrules", match = { class = "vimpad" },float = true, size = "1200 700", 
center = true, border_size = 2, opacity = "1", animation = "slide top",
border_color = { colors = { theme.color2, theme.color2 } } })

-- Term Pad
hl.window_rule({ name = "termpadrules", match = { class = "termpad" },float = true, size = "1200 700", 
center = true, border_size = 2, opacity = "1", animation = "slide top", 
border_color = { colors = { theme.color2, theme.color2 } } })

-- HyprThemer
hl.window_rule({ name = "themerrules", match = { class = "themer.py" },float = true, size = "1200 700", 
center = true, border_size = 2, opacity = "1", animation = "slide top", 
border_color = { colors = { theme.color2, theme.color2 } } })

-- HyprBinds
hl.window_rule({ name = "bindsrules", match = { class = "binds.py" },float = true, size = "1200 700", 
center = true, border_size = 2, opacity = "1", animation = "slide top", 
border_color = { colors = { theme.color2, theme.color2 } } })

-- VSS Code
hl.window_rule({ name = "vssrules", match = { class = "codium" },float = true, size = "1200 700", 
center = true, border_size = 2, opacity = "1", animation = "slide top", 
border_color = { colors = { theme.color2, theme.color2 } } })

-- Piper GUI
hl.window_rule({ name = "pyprrules", match = { title = "pypr-gui" },float = true, size = "1200 700", 
center = true, border_size = 2, opacity = "1", animation = "slide top", 
border_color = { colors = { theme.color2, theme.color2 } } })


