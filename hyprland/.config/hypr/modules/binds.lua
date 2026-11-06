local mainMod = "SUPER"

-- Session Management
hl.bind("SUPER + M", hl.dsp.exec_cmd("uwsm stop"),                                                                                                          { description = "Exit Session" })
hl.bind("SUPER + L", hl.dsp.exec_cmd("qs -p ~/.config/quickshell/Anarchy-Bar/Q-Apps/Lockscreen"),                                                           { description = "Lock Screen" })

-- Scratchpads
local pendingScratchpad

local scratchpads = {
    nautipad = { classes = { "org.gnome.Nautilus" }, command = "nautilus" },
    codepad = { classes = { "codepad", "code-oss" }, command = "code" },
    termpad = { classes = { "termpad" }, command = "kitty --class=termpad" },
    vimpad = { classes = { "vimpad" }, command = "kitty --class=vimpad -e nvim" },
    osdpad = { classes = { "ARKB" }, command = "qs -p ~/.config/quickshell/Anarchy-Bar/Q-Apps/KeyboardLayout" },
}

local function matchesScratchpad(window, pad)
    for _, class in ipairs(pad.classes) do
        if window.class == class or window.initial_class == class then
            return true
        end
    end
    return false
end

hl.on("window.open", function(window)
    local pending = pendingScratchpad
    if not pending or not matchesScratchpad(window, pending.pad) then
        return
    end

    pendingScratchpad = nil
    hl.dispatch(hl.dsp.focus({ monitor = window.monitor.name }))
    hl.dispatch(hl.dsp.window.move({
        window = window,
        workspace = "special:" .. pending.name,
        follow = false,
    }))
    hl.dispatch(hl.dsp.workspace.toggle_special(pending.name))
    hl.dispatch(hl.dsp.focus({ window = window }))
end)

local function toggleScratchpad(name)
    local pad = scratchpads[name]
    local activeMonitor = hl.get_active_monitor()
    if not activeMonitor then
        return
    end

    local window

    for _, candidate in ipairs(hl.get_windows()) do
        if matchesScratchpad(candidate, pad) then
            window = candidate
            break
        end
    end

    if not window then
        pendingScratchpad = { name = name, pad = pad }
        hl.exec_cmd(pad.command)
        return
    end

    local targetWorkspace = "special:" .. name

    if window.workspace.special then
        hl.dispatch(hl.dsp.focus({ monitor = window.monitor.name }))
        local activeSpecial = hl.get_active_special_workspace()
        if activeSpecial and activeSpecial.id == window.workspace.id then
            -- Do not refocus the window after hiding it: that can reopen its
            -- special workspace immediately.
            hl.dispatch(hl.dsp.workspace.toggle_special(name))
        else
            if window.workspace.name ~= name and window.workspace.name ~= targetWorkspace then
                hl.dispatch(hl.dsp.window.move({
                    window = window,
                    workspace = targetWorkspace,
                    follow = false,
                }))
            end
            hl.dispatch(hl.dsp.workspace.toggle_special(name))
            hl.dispatch(hl.dsp.focus({ window = window }))
        end
        return
    end

    local activeWorkspace = hl.get_active_workspace()
    local activeWindow = hl.get_active_window()
    local isFocusedOnActiveWorkspace = activeWorkspace
        and window.workspace.id == activeWorkspace.id
        and activeWindow
        and window.address == activeWindow.address

    hl.dispatch(hl.dsp.window.move({
        window = window,
        workspace = targetWorkspace,
        follow = false,
    }))

    -- Moving the currently focused window into its special workspace hides it;
    -- otherwise toggling the workspace brings the scratchpad to the front.
    if not isFocusedOnActiveWorkspace then
        hl.dispatch(hl.dsp.focus({ monitor = window.monitor.name }))
        hl.dispatch(hl.dsp.workspace.toggle_special(name))
        hl.dispatch(hl.dsp.focus({ window = window }))
    end
end

AnarchyToggleScratchpad = toggleScratchpad

hl.bind("SUPER + E", function() toggleScratchpad("nautipad") end, { description = "Nautilus Scratchpad" })
hl.bind("SUPER + T", function() toggleScratchpad("codepad") end, { description = "VS Code Scratchpad" })
hl.bind("SUPER + SHIFT + RETURN", function() toggleScratchpad("termpad") end, { description = "Terminal Scratchpad" })
hl.bind("SUPER + V", function() toggleScratchpad("vimpad") end, { description = "Neovim Scratchpad" })
hl.bind("SUPER + K", function() toggleScratchpad("osdpad") end, { description = "AR Keyboard OSD" })

-- App Launch
hl.bind("SUPER + SPACE", hl.dsp.exec_cmd("pkill rofi || ~/.config/rofi/launcher/launcher.sh"),                                                              { description = "App Launcher" })
hl.bind("SUPER + SHIFT + T", hl.dsp.exec_cmd("~/.config/quickshell/Anarchy-Bar/Scripts/toggle-theme-switcher.sh"),                                          { description = "Theme Switcher" })
hl.bind("SUPER + RETURN", hl.dsp.exec_cmd("kitty"),                                                                                                         { description = "Terminal" })
hl.bind("SUPER + B", hl.dsp.exec_cmd("firefox"),                                                                                                            { description = "Firefox" })
hl.bind("SUPER + H", hl.dsp.exec_cmd("hyprpicker -a"),                                                                                                      { description = "Color Picker" })
hl.bind("SUPER + P", hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | swappy -f -"),                                                                               { description = "Screenshot" })
hl.bind("SUPER + SHIFT + Y", hl.dsp.exec_cmd("/usr/local/bin/yt-dlp-gui.py"),                                                                               { description = "YTDL" })

-- Window Management
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(),                                                                                                           { description = "Move Window" })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(),                                                                                                        { description = "Resize Window" })
hl.bind(mainMod .. " + Tab", function() hl.dsp.layout("cyclenext") end,                                                                                     { description = "Switch Window" })
hl.bind(mainMod .. " + Q", hl.dsp.window.close(),                                                                                                           { description = "Close Window" })
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }),                                                            { description = "Toggle Fullscreen" })

-- Workspace Management
hl.bind(mainMod .. " + 1", hl.dsp.focus({ workspace = 1 }),                                                                                                 { description = "Workspace 1" })
hl.bind(mainMod .. " + 2", hl.dsp.focus({ workspace = 2 }),                                                                                                 { description = "Workspace 2" })
hl.bind(mainMod .. " + 3", hl.dsp.focus({ workspace = 3 }),                                                                                                 { description = "Workspace 3" })
hl.bind(mainMod .. " + 4", hl.dsp.focus({ workspace = 4 }),                                                                                                 { description = "Workspace 4" })
hl.bind(mainMod .. " + 5", hl.dsp.focus({ workspace = 5 }),                                                                                                 { description = "Workspace 5" })
hl.bind(mainMod .. " + 6", hl.dsp.focus({ workspace = 6 }),                                                                                                 { description = "Workspace 6" })
hl.bind(mainMod .. " + 7", hl.dsp.focus({ workspace = 7 }),                                                                                                 { description = "Workspace 7" })
hl.bind(mainMod .. " + 8", hl.dsp.focus({ workspace = 8 }),                                                                                                 { description = "Workspace 8" })
hl.bind(mainMod .. " + 9", hl.dsp.focus({ workspace = 9 }),                                                                                                 { description = "Workspace 9" })
hl.bind(mainMod .. " + 0", hl.dsp.focus({ workspace = 10 }),                                                                                                { description = "Workspace 10" })
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }),                                                                                    { description = "Next Workspace" })
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }),                                                                                      { description = "Previous Workspace" })

-- Move Window to Workspace
hl.bind(mainMod .. " + SHIFT + 1", hl.dsp.window.move({ workspace = 1 }),                                                                                   { description = "Move to Workspace 1" })
hl.bind(mainMod .. " + SHIFT + 2", hl.dsp.window.move({ workspace = 2 }),                                                                                   { description = "Move to Workspace 2" })
hl.bind(mainMod .. " + SHIFT + 3", hl.dsp.window.move({ workspace = 3 }),                                                                                   { description = "Move to Workspace 3" })
hl.bind(mainMod .. " + SHIFT + 4", hl.dsp.window.move({ workspace = 4 }),                                                                                   { description = "Move to Workspace 4" })
hl.bind(mainMod .. " + SHIFT + 5", hl.dsp.window.move({ workspace = 5 }),                                                                                   { description = "Move to Workspace 5" })
hl.bind(mainMod .. " + SHIFT + 6", hl.dsp.window.move({ workspace = 6 }),                                                                                   { description = "Move to Workspace 6" })
hl.bind(mainMod .. " + SHIFT + 7", hl.dsp.window.move({ workspace = 7 }),                                                                                   { description = "Move to Workspace 7" })
hl.bind(mainMod .. " + SHIFT + 8", hl.dsp.window.move({ workspace = 8 }),                                                                                   { description = "Move to Workspace 8" })
hl.bind(mainMod .. " + SHIFT + 9", hl.dsp.window.move({ workspace = 9 }),                                                                                   { description = "Move to Workspace 9" })
hl.bind(mainMod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 10 }),                                                                                  { description = "Move to Workspace 10" })

-- Volume Control
hl.bind("SUPER + EQUAL", hl.dsp.exec_cmd("/usr/local/bin/volume.sh up"),                                                                                    { description = "Volume Up" })
hl.bind("SUPER + MINUS", hl.dsp.exec_cmd("/usr/local/bin/volume.sh down"),                                                                                  { description = "Volume Down" })
hl.bind("SUPER + BACKSLASH", hl.dsp.exec_cmd("/usr/local/bin/volume.sh mute"),                                                                              { description = "Volume Mute" })

-- Testing
hl.bind("ALT + W", hl.dsp.exec_cmd("~/git/islamiyyah/tester.sh"),                                                                                           { description = "Islamiyyah App Testing" })

hl.bind("SUPER + U", hl.dsp.global("caelestia:launcher"))
hl.bind("SUPER + C", hl.dsp.global("caelestia:showall"))
