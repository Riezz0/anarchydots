local mainMod = "SUPER"

-- Session Management
hl.bind("SUPER + M", hl.dsp.exec_cmd("uwsm stop"),                                                                          { description = "Exit Session" })
hl.bind("SUPER + L", hl.dsp.exec_cmd("hyprlock"),                                                                           { description = "Lock Screen" })

-- Scratchpads
hl.bind("SUPER + E", hl.dsp.exec_cmd("pypr toggle nautipad"),                                                               { description = "File Explorer Scratchpad" })
hl.bind("SUPER + SHIFT + P", hl.dsp.exec_cmd("pypr toggle pyprpad"),                                                        { description = "Pyprpad Scratchpad" })
hl.bind("SUPER + T", hl.dsp.exec_cmd("pypr toggle codipad"),                                                                { description = "VS Code Scratchpad" })
hl.bind("SUPER + SHIFT + RETURN", hl.dsp.exec_cmd("pypr toggle termpad"),                                                   { description = "Terminal Scratchpad" })
hl.bind("SUPER + V", hl.dsp.exec_cmd("pypr toggle vimpad"),                                                                 { description = "Neovim Scratchpad" })

-- App Launch
hl.bind("SUPER + SPACE", hl.dsp.exec_cmd("pkill rofi || ~/.config/rofi/launcher/launcher.sh"),                              { description = "App Launcher" })
hl.bind("SUPER + RETURN", hl.dsp.exec_cmd("kitty"),                                                                         { description = "Terminal" })
hl.bind("SUPER + G", hl.dsp.exec_cmd("flatpak run org.libretro.RetroArch"),                                                 { description = "RetroArch" })
hl.bind("SUPER + B", hl.dsp.exec_cmd("firefox"),                                                                            { description = "Firefox" })
hl.bind("SUPER + H", hl.dsp.exec_cmd("hyprpicker -a"),                                                                      { description = "Color Picker" })
hl.bind("SUPER + P", hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | swappy -f -"),                                               { description = "Screenshot" })

-- Window Management
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(),                                                                          { description = "Move Window" })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(),                                                                        { description = "Resize Window" })
hl.bind(mainMod .. " + Tab", function() hl.dsp.layout("cyclenext") end,                                                     { description = "Switch Window" })
hl.bind(mainMod .. " + Q", hl.dsp.window.close(),                                                                           { description = "Close Window" })
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }),                            { description = "Toggle Fullscreen" })

-- Workspace Management
hl.bind(mainMod .. " + 1", hl.dsp.focus({ workspace = 1 }),                                                                 { description = "Workspace 1" })
hl.bind(mainMod .. " + 2", hl.dsp.focus({ workspace = 2 }),                                                                 { description = "Workspace 2" })
hl.bind(mainMod .. " + 3", hl.dsp.focus({ workspace = 3 }),                                                                 { description = "Workspace 3" })
hl.bind(mainMod .. " + 4", hl.dsp.focus({ workspace = 4 }),                                                                 { description = "Workspace 4" })
hl.bind(mainMod .. " + 5", hl.dsp.focus({ workspace = 5 }),                                                                 { description = "Workspace 5" })
hl.bind(mainMod .. " + 6", hl.dsp.focus({ workspace = 6 }),                                                                 { description = "Workspace 6" })
hl.bind(mainMod .. " + 7", hl.dsp.focus({ workspace = 7 }),                                                                 { description = "Workspace 7" })
hl.bind(mainMod .. " + 8", hl.dsp.focus({ workspace = 8 }),                                                                 { description = "Workspace 8" })
hl.bind(mainMod .. " + 9", hl.dsp.focus({ workspace = 9 }),                                                                 { description = "Workspace 9" })
hl.bind(mainMod .. " + 0", hl.dsp.focus({ workspace = 10 }),                                                                { description = "Workspace 10" })
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }),                                                    { description = "Next Workspace" })
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }),                                                      { description = "Previous Workspace" })

-- Volume Control
hl.bind("SUPER + EQUAL", hl.dsp.exec_cmd("~/.config/scripts/volume.sh up"),                                                 { description = "Volume Up" })
hl.bind("SUPER + MINUS", hl.dsp.exec_cmd("~/.config/scripts/volume.sh down"),                                               { description = "Volume Down" })
hl.bind("SUPER + BACKSLASH", hl.dsp.exec_cmd("~/.config/scripts/volume.sh mute"),                                           { description = "Volume Mute" })

-- Testing
hl.bind("ALT + W", hl.dsp.exec_cmd("/usr/local/bin/waybar.sh"),                                                             { description = "Waybar Testing" })
hl.bind("ALT + P", hl.dsp.exec_cmd("~/.config/scripts/swaync.sh"),                                                          { description = "SwayNC Testing" })
hl.bind("ALT + O", hl.dsp.exec_cmd("~/git/oomox/gui.sh"),                                                                   { description = "Themix Testing" })
