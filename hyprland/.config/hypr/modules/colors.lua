-- Define the helper function locally
local function rgba(r, g, b, a)
    -- Hyprland color format: 0xRRGGBBAA
    return string.format("0x%02x%02x%02x%02x", r, g, b, math.floor(a * 255))
end


-- Create and populate the table
local M = {}


-- Background and Foreground
M.background = "0xff251810"
M.foreground = "0xffc8c5c3"
M.cursor     = "0xffc8c5c3"


-- Colors
M.color0     = "0xff251810"
M.color1     = "0xff9f4817"
M.color2     = "0xff6c5636"
M.color3     = "0xff5b6358"
M.color4     = "0xff806f4d"
M.color5     = "0xffa27645"
M.color6     = "0xff8e8366"
M.color7     = "0xff9c9692"
M.color8     = "0xff74665f"
M.color9     = "0xffD5611F"
M.color10    = "0xff917349"
M.color11    = "0xff7A8576"
M.color12    = "0xffAB9467"
M.color13    = "0xffD89E5C"
M.color14    = "0xffBEAF89"
M.color15    = "0xffc8c5c3"


-- Return the table
return M
