-- check_syntax.lua s automatickými opravami

-- Pomocná funkce pro získání všech .lua souborů ve složce (Windows only)
function get_lua_files(dir, files)
    files = files or {}
    local p = io.popen('dir "'..dir..'" /b /s')
    for file in p:lines() do
        if file:match('%.lua$') then
            table.insert(files, file)
        end
    end
    p:close()
    return files
end

function check_file_and_save(path, output_file)
    local f = io.open(path, "r")
    if not f then return end
    local code = f:read("*a")
    f:close()
    local ok, err = load(code, path)
    if not ok then
        local error_line = path .. ": " .. err
        print(error_line)
        output_file:write(error_line .. "\n")
    end
end

print("Checking syntax...")
local files = get_lua_files("game")
local error_file = io.open('syntax_errors.txt', 'w')
if error_file then
    for _, file in ipairs(files) do
        check_file_and_save(file, error_file)
    end
    error_file:close()
end
