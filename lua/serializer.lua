-- Copyright 2012-2014 Christopher E. Miller
-- Dual License (choose): MIT License 1.0 / Boost Software License 1.0
-- http://www.boost.org/users/license.html

local M = {}


local entry -- forward decl

local function entrytable(k, v, level, file)
	local ktype = type(k)
	file:write(string.rep("\t", level))
	if ktype == "number" then
		file:write("[", k, "]={\n")
	elseif ktype == "string" then
		file:write(string.format("[%q]={\n", k))
	end
	for k2, v2 in pairs(v) do
		entry(k2, v2, level + 1, file)
	end
	file:write(string.rep("\t", level))
	file:write("},\n")
end

function entry(k, v, level, file)
	local ktype, vtype = type(k), type(v)
	if vtype == "table" then
		entrytable(k, v, level, file)
	else
		file:write(string.rep("\t", level))
		if ktype == "number" then
			if vtype == "number" then
				file:write("[", k, "]=", v, ",\n")
			elseif vtype == "string" then
				file:write(string.format("[%s]=%q,\n", k, v))
			elseif vtype == "boolean" then
				file:write(string.format("[%s]=%s,\n", k, tostring(v)))
			end
		elseif ktype == "string" then
			if k:find("^%a[%a%d_]*$") then
				if vtype == "number" then
					file:write(k, "=", v, ",\n")
				elseif vtype == "string" then
					file:write(string.format("%s=%q,\n", k, v))
				elseif vtype == "boolean" then
					file:write(string.format("%s=%s,\n", k, tostring(v)))
				end
			else
				if vtype == "number" then
					file:write(string.format("[%q]=%s,\n", k, v))
				elseif vtype == "string" then
					file:write(string.format("[%q]=%q,\n", k, v))
				elseif vtype == "boolean" then
					file:write(string.format("[%q]=%s,\n", k, tostring(v)))
				end
			end
		end
	end
end


--- obj is the object to serialize.
--- file can be a filename, a file object, or any object with a :write(...) method.
function M.serialize(obj, file)
	local isstr = false
	local needclose = false
	if type(file) == "string" then
		local f, xerr = io.open(file, "w+") -- update mode, all previous data is erased
		if not f then return nil, xerr end
		file = f
		needclose = true
	end

	for k, v in pairs(obj) do
		entry(k, v, 0, file)
	end

	if isstr then return file.str end
	if needclose then file:close() end
	return file
end


---
function M.stringify(obj)
	local file = { }
	function file:write(...)
		local n = select('#', ...)
		for i = 1, n do
			local x = select(i, ...)
			self[#self + 1] = x
		end
	end
	local a, b = M.serialize(obj, file)
	if not a then
		return a, b
	end
	return table.concat(file)
end


local function loadfunc(ld, name, env)
	if _VERSION == "Lua 5.1" then
		local a, b = load(ld, name)
		if not a then
			return a, b
		end
		setfenv(a, env)
		return a
	elseif _VERSION >= "Lua 5.2" then
		return load(ld, name, "t", env)
	end
end


local function validate(obj)
	for k, v in pairs(obj) do
		local kt = type(k)
		local vt = type(v)
		assert(kt ~= "function" and vt ~= "function", "Function not allowed")
		if kt == "table" then
			validate(v)
		end
		if vt == "table" then
			validate(v)
		end
	end
end


local function deserializer(source, isLiteral)
	local name = "file"
	local file = source
	local needclose = false
	if type(source) == "string" then
		if isLiteral then
			name = "data"
		else
			local f, xerr = io.open(source, "rb")
			if not f then return nil, xerr end
			file = f
			needclose = true
			name = "filename-" .. source
		end
	end
	local env = { }
	local state = 0
	local fn, xerr = loadfunc(function()
		if state == 0 then
			state = 1
			return "return {\n"
		elseif state == 1 then
			if isLiteral then
				state = 2
				return source
			end
			local rr = file:read(4096)
			if rr then
				return rr
			end
			state = -1
			return "\n}"
		elseif state == 2 then
			-- For isLiteral only.
			state = -1
			return "\n}"
		end
	end, "deserialize-" .. name, env)
	if needclose then file:close() end
	if not fn then return nil, xerr end
	local a, b = fn()
	if a and b then
		validate(a)
		setmetatable(b, a)
		a, b = b, nil
	end
	assert(type(a) == "table", "Table expected")
	return a
end


--- source can be a filename, a file object, or any object with a :read() method.
function M.deserialize(source)
	return deserializer(source)
end


--- data is literally serialized data.
function M.parse(data)
	return deserializer(data, true)
end


--[[
local function serializer_Test()
	local t = { 33, hello = 3, [99] = 99, ["list!"] = { 5, 4, 3, 2, 1 },
		["x*x"] = "x\"'''\n", mybool = true, ["your-bool"] = false }
	local s = assert(M.stringify(t))
	print("serialize = `" .. s .. "`")
	local t2 = assert(M.parse(s))
	for k, v in pairs(t) do
		if type(v) ~= "table" then
			assert(t2[k] == v)
		end
	end
	print("serializer_Test PASS")
end

serializer_Test() -- Run test.
--]]


return M

