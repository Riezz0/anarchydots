-- Global
local theme = require("modules.colors")
hl.window_rule({name = "globalrules", match = { class = ".*",
}, animation = "slide top",})

-- Nautilus
hl.window_rule({ name = "nautilusrules", match = { class = "org.gnome.Nautilus" },float = true, size = "1200 700", 
center = true, border_size = 2, opaque = 1, animation = "slide top",
border_color = { colors = { theme.color1, theme.color1 } } })

-- Neovim
hl.window_rule({ name = "nvimrules", match = { class = "vimpad" },float = true, size = "1200 700", 
center = true, border_size = 2, opaque = 1, animation = "slide top",
border_color = { colors = { theme.color1, theme.color1 } } })

-- Term Pad
hl.window_rule({ name = "termpadrules", match = { class = "termpad" },float = true, size = "1200 700", 
center = true, border_size = 2, opaque = 0, animation = "slide top", 
border_color = { colors = { theme.color1, theme.color1 } } })

-- HyprThemer
hl.window_rule({ name = "themerrules", match = { class = "themer.py" },float = true, size = "1200 700", 
center = true, border_size = 2, opaque = 0, animation = "slide top", 
border_color = { colors = { theme.color1, theme.color1 } } })

-- HyprBinds
hl.window_rule({ name = "bindsrules", match = { class = "binds.py" },float = true, size = "1200 700", 
center = true, border_size = 2, opaque = 0, animation = "slide top", 
border_color = { colors = { theme.color1, theme.color1 } } })

-- VSS Code
hl.workspace_rule({ workspace = "special:codepad", on_created_empty = "codium", persistent = false })
hl.window_rule({ name = "coderules", match = { class = "codium" },float = true, size = "1200 700", 
center = true, border_size = 2, opaque = 1, animation = "slide right" })

-- Cooler Control
hl.window_rule({ name = "coolercontrol", match = { class = "org.coolercontrol.CoolerControl" },float = true, size = "1200 700", 
center = true, border_size = 2, opaque = 1, animation = "slide right" })

-- Core Control
hl.window_rule({ name = "corecontrol", match = { class = "org.corectrl.CoreCtrl" },float = true, size = "1200 700", 
center = true, border_size = 2, opaque = 1, animation = "slide right" })

-- Kitty Global
hl.window_rule({ match = { class = "kitty" }, border_size = 2, center = true, opacity = 0.8 })
hl.window_rule({ match = { class = "kitty", fullscreen = 1 }, opacity = 1.0  })


-- Vesktop
hl.workspace_rule({ workspace = "special:veskpad", on_created_empty = "vesktop", persistent = false })
hl.window_rule({ name = "vesktoprules", match = { class = "vesktop" },float = true, size = "1200 600", 
center = true, border_size = 2, opaque = 1, animation = "slide right" })

-- Kvauntum
hl.window_rule({ name = "kvantumrules", match = { class = "kvantummanager" },float = true, size = "1200 600", 
center = true, border_size = 2, opaque = 1, animation = "slide right" })

-- Bluetooth Manager 
hl.window_rule({ name = "bluemanrules", match = { class = "blueman-manager" },float = true, size = "1200 600", 
center = true, border_size = 2, opaque = 1, animation = "slide right" })

-- Quran
hl.workspace_rule({ workspace = "special:quranpad", on_created_empty = "chromium --app=https://www.quranwbw.com", persistent = false })
hl.window_rule({ name = "vesktoprules", match = { class = "vesktop" },float = true, size = "1200 600", 
center = true, border_size = 2, opaque = 1, animation = "slide right" })
