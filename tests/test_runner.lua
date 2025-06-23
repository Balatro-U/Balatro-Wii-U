-- Test runner pro LovePotion/LÖVE/Wii U: kontrola syntaxe a runtime všech Lua souborů (rekurzivně)

local tests = {}

local function check_lua_file(path)
    local only_syntax = {
        ["main.lua"] = true,
        ["blind.lua"] = true,
        ["back.lua"] = true,
        ["card.lua"] = true,
        ["card_character.lua"] = true,
        ["cardarea.lua"] = true,
        ["challenges.lua"] = true,
        ["engine/animatedsprite.lua"] = true,
        -- přidej další soubory se závislostmi
    }
    if love and love.filesystem and love.filesystem.load then
        local ok, chunk_or_err = pcall(love.filesystem.load, path)
        if not ok then
            return false, "love.filesystem.load error: " .. tostring(chunk_or_err)
        end
        if not only_syntax[path:match("[^/\\]+$")] then
            local run_ok, run_err = pcall(chunk_or_err)
            if not run_ok then
                return false, "Runtime error: " .. tostring(run_err)
            end
        end
    else
        -- fallback pro desktop Lua (ne Wii U)
        local f = io.open(path, "r")
        if not f then return false, "Soubor nešel otevřít: " .. path end
        local code = f:read("*a")
        f:close()
        local func, syntax_err = load(code, path)
        if not func then
            return false, syntax_err
        end
        if not only_syntax[path:match("[^/\\]+$")] then
            local run_ok, run_err = pcall(func)
            if not run_ok then
                return false, "Runtime error: " .. tostring(run_err)
            end
        end
    end
    return true
end

function tests.test_all_lua_files()
    local function scan_dir(dir)
        local files = love.filesystem.getDirectoryItems(dir)
        for _, file in ipairs(files) do
            local full = dir ~= "" and (dir .. "/" .. file) or file
            local info = love.filesystem.getInfo(full)
            if info and info.type == "file" and file:sub(-4) == ".lua" then
                local ok, err = check_lua_file(full)
                assert(ok, "Chyba v souboru " .. full .. ": " .. tostring(err))
            elseif info and info.type == "directory" then
                scan_dir(full)
            end
        end
    end
    scan_dir("") -- prázdný string = root složka projektu v LovePotion/LÖVE
end

-- Test runner
local function run_tests()
    local passed, failed = 0, 0
    for name, test in pairs(tests) do
        local ok, err = pcall(test)
        if ok then
            print("[OK]   " .. name)
            passed = passed + 1
        else
            print("[FAIL] " .. name .. ": " .. tostring(err))
            failed = failed + 1
        end
    end
    print("== Výsledek testů: " .. passed .. " OK, " .. failed .. " FAIL ==")
end

if love and love.load then
    local orig_load = love.load
    love.load = function(...)
        if orig_load then orig_load(...) end
        run_tests()
    end
else
    run_tests()
end

return {
    run_tests = run_tests,
    tests = tests,
}