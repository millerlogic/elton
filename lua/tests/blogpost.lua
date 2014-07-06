#!/usr/bin/env lua
package.path = package.path..";../?.lua"

local elton = require "elton"

local serialized = elton.stringify {
    date = "2014-03-14 13:32",
    title = "An example Elton document",
    tags = {"test", "example"},
    post = [[
Example
=======

Lorem ipsum dolor sit amet...
]]
}

print("Blog post as Elton:")
print(serialized)
