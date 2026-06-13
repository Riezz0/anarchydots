-- Autostart

hl.on("hyprland.start", function () 
hl.exec_cmd("pypr")
hl.exec_cmd("pypr-gui")
hl.exec_cmd("awww-daemon")
hl.exec_cmd("swaync")
hl.exec_cmd("coolercontrol")
hl.exec_cmd("/usr/local/bin/swww.sh")
hl.exec_cmd("wal --theme ~/.config/pywal/themes/active.json")
-- hl.exec_cmd("/usr/local/bin/waybar.sh")  -- replaced by quickshell powerbar
hl.exec_cmd("/usr/local/bin/qbarmain.sh")
hl.exec_cmd("/usr/local/bin/welcome.sh")
hl.exec_cmd("/usr/local/bin/hypr-reload.sh")
hl.exec_cmd("sleep 2 && hyprctl reload")
hl.exec_cmd("arch-update --tray")
end)
