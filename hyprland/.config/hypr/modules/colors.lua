-- Define the helper function locally
local function rgba(r, g, b, a)
    return string.format("0x%02x%02x%02x%02x", r, g, b, math.floor(a * 255))
end

local M = {}

M.background = "0xff0b0f19"
M.foreground = "0xffc2c3c5"
M.cursor     = "0xffc2c3c5"

M.color0  = "0xff0b0f19"
M.color1  = "0xff546864"
M.color2  = "0xff6f7b6d"
M.color3  = "0xffa58765"
M.color4  = "0xff8a9084"
M.color5  = "0xffab936b"
M.color6  = "0xffbda687"
M.color7  = "0xff8e9299"
M.color8  = "0xff5a616e"
M.color9  = "0xff718b86"
M.color10 = "0xff95a592"
M.color11 = "0xffddb587"
M.color12 = "0xffb8c1b1"
M.color13 = "0xffe5c58f"
M.color14 = "0xfffddeb4"
M.color15 = "0xffc2c3c5"

return M
