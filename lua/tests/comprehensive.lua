#!/usr/bin/env lua
package.path = package.path..";../?.lua"
local M = require "elton"

local t = { 33, hello = 3, [99] = 99, ["list!"] = { 5, 4, 3, 2, 1 },
    ["x*x"] = "x\"'''\n", mybool = true, ["your-bool"] = false,
    [true] = false, foo = { 'first', 2, true, false, { mytable=1 }, [101] = 202, }
}
local s = assert(M.stringify(t))
print("serialize = `" .. s .. "`")
local t2 = assert(M.parse(s))
for k, v in pairs(t) do
    if type(v) ~= "table" then
        assert(t2[k] == v, "Mismatch: `" .. tostring(t2[k]) .. "` vs `" .. tostring(v) .. "`")
    end
end

-- Disallow function call:
assert(not M.parse("{ (function() end)() }"), "Function call was allowed")

-- Disallow cycles:
t["list!"].cycle = t
-- assert(not M.stringify(t))
-- Note: implicitly handled by stack overflow, which can be recovered via pcall.
assert(not pcall(M.stringify, t))
t["list!"].cycle = nil

print("elton_Test PASS")