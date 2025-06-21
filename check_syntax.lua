-- check_syntax.lua
-- Add LuaRocks paths manually if luarocks.loader fails
package.path = package.path .. ";C:/Users/xtoma/AppData/Roaming/luarocks/share/lua/5.4/?.lua"
package.cpath = package.cpath .. ";C:/Users/xtoma/AppData/Roaming/luarocks/lib/lua/5.4/?.dll"
pcall(require, "luarocks.loader")

local lfs = require("lfs")
local function check_dir(path)
  for file in lfs.dir(path) do
    if file:match("%.lua$") then
      local f = path..'/'..file
      local ok, err = loadfile(f)
      if not ok then print(f..": "..err) end
    elseif file ~= "." and file ~= ".." then
      check_dir(path..'/'..file)
    end
  end
end

local function check_file(f)
  local ok, err = loadfile(f)
  if not ok then print(f..": "..err) end
end

for file in io.popen('dir /b /s *.lua'):lines() do
  check_file(file)
end