local table = require 'table'
local insert = table.insert
local unpack = table.unpack

local function makefss(self, f)
	local c, fss = self.parent, {{f}, self.mws}
	while c ~= nil do
		insert(fss, c.mws)
		c = c.parent
	end
	return fss
end

local function makectx(fss, i, j, p)
	return setmetatable({}, {
		__index = p;
		__call = function(self)
			local fs = fss[i]
			while fs ~= nil do
				local f = fs[j]
				if f ~= nil then
					return f(makectx(fss, i, j+1, self))
				end
				i, j = i-1, 1
				fs = fss[i]
			end
		end;
	})
end

local function use(self, ...)
	for _, mw in ipairs{...} do
		insert(self.mws, mw)
	end
	return self
end

local function call(self, f, ...)
	local args, res = {...}
	local fss = makefss(self, function(ctx)
		res = {true, f(ctx, unpack(args))}
	end)
	local ok, err = pcall(makectx(fss, #fss, 1))
	if res == nil then
		if ok then
			return false
		end
		return ok, err
	end
	return unpack(res)
end

local function clone(self)
	return {
		mws = {};
		use = use;
		call = call;
		clone = clone;
		parent = self;
	}
end

return {
	new = function()
		return clone()
	end;
}
