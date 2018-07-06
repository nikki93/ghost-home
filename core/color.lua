-- Based on CPML: https://github.com/excessive/cpml

--- Color utilities
-- @module color

local color    = {}
local color_mt = {}

--- Clamps a value within the specified range.
-- @param value Input value
-- @param min Minimum output value
-- @param max Maximum output value
-- @return number
local function clamp(value, min, max)
    return math.max(math.min(value, max), min)
end

local function new(r, g, b, a)
    return setmetatable({
        r = r, g = g, b = b, a = a,
    }, color_mt)
end

---- HSV utilities (adapted from http://www.cs.rit.edu/~ncs/color/t_convert.html)
---- hsv_to_color(hsv)
---- Converts a set of HSV values to a color. hsv is a table.
---- See also: hsv(h, s, v)
--local function hsv_to_color(hsv)
--	local i
--	local f, q, p, t
--	local h, s, v
--	local a = hsv.a or 1
--	s = hsv.g
--	v = hsv.b
--
--	if s == 0 then
--		return new(v, v, v, a)
--	end
--
--	h = hsv.r / 60
--
--	i = math.floor(h)
--	f = h - i
--	p = v * (1-s)
--	q = v * (1-s*f)
--	t = v * (1-s*(1-f))
--
--	if     i == 0 then return new(v, t, p, a)
--	elseif i == 1 then return new(q, v, p, a)
--	elseif i == 2 then return new(p, v, t, a)
--	elseif i == 3 then return new(p, q, v, a)
--	elseif i == 4 then return new(t, p, v, a)
--	else               return new(v, p, q, a)
--	end
--end
--
---- color_to_hsv(c)
---- Takes in a normal color and returns a table with the HSV values.
--local function color_to_hsv(c)
--	local r = c.r
--	local g = c.g
--	local b = c.b
--	local a = c.a or 1
--	local h, s, v
--
--	local min = math.min(r, g, b)
--	local max = math.max(r, g, b)
--	v = max
--
--	local delta = max - min
--
--	-- black, nothing else is really possible here.
--	if min == 0 and max == 0 then
--		return { 0, 0, 0, a }
--	end
--
--	if max ~= 0 then
--		s = delta / max
--	else
--		-- r = g = b = 0 s = 0, v is undefined
--		s = 0
--		h = -1
--		return { h, s, v, 1 }
--	end
--
--	if r == max then
--		h = ( g - b ) / delta     -- yellow/magenta
--	elseif g == max then
--		h = 2 + ( b - r ) / delta -- cyan/yellow
--	else
--		h = 4 + ( r - g ) / delta -- magenta/cyan
--	end
--
--	h = h * 60 -- degrees
--
--	if h < 0 then
--		h = h + 360
--	end
--
--	return { h, s, v, a }
--end

--- The public constructor.
-- @param x Can be of three types: </br>
-- number red component 0-1
-- table {r, g, b, a}
-- nil for {0,0,0,0}
-- @tparam number g Green component 0-1
-- @tparam number b Blue component 0-1
-- @tparam number a Alpha component 0-1
-- @treturn color out
function color.new(r, g, b, a)
	-- number, number, number, number
	if r and g and b and a then
		assert(type(r) == "number", "new: Wrong argument type for r (<number> expected)")
		assert(type(g) == "number", "new: Wrong argument type for g (<number> expected)")
		assert(type(b) == "number", "new: Wrong argument type for b (<number> expected)")
		assert(type(a) == "number", "new: Wrong argument type for a (<number> expected)")

		return new(r, g, b, a)

	-- {r, g, b, a}
	elseif type(r) == "table" then
		local rr, gg, bb, aa = r.r, r.g, r.b, r.a
		assert(type(rr) == "number", "new: Wrong argument type for r (<number> expected)")
		assert(type(gg) == "number", "new: Wrong argument type for g (<number> expected)")
		assert(type(bb) == "number", "new: Wrong argument type for b (<number> expected)")
		assert(type(aa) == "number", "new: Wrong argument type for a (<number> expected)")

		return new(rr, gg, bb, aa)
	end

	return new(0, 0, 0, 0)
end

----- Convert hue,saturation,value table to color object.
---- @tparam table hsva {hue 0-359, saturation 0-1, value 0-1, alpha 0-1}
---- @treturn color out
--color.hsv_to_color_table = hsv_to_color
--
----- Convert color to hue,saturation,value table
---- @tparam color in
---- @treturn table hsva {hue 0-359, saturation 0-1, value 0-1, alpha 0-1}
--color.color_to_hsv_table = color_to_hsv
--
----- Convert hue,saturation,value to color object.
---- @tparam number h hue 0-359
---- @tparam number s saturation 0-1
---- @tparam number v value 0-1
---- @treturn color out
--function color.from_hsv(h, s, v)
--	return hsv_to_color { h, s, v }
--end
--
----- Convert hue,saturation,value to color object.
---- @tparam number h hue 0-359
---- @tparam number s saturation 0-1
---- @tparam number v value 0-1
---- @tparam number a alpha 0-1
---- @treturn color out
--function color.from_hsva(h, s, v, a)
--	return hsv_to_color { h, s, v, a }
--end

--- Invert a color.
-- @tparam color to invert
-- @treturn color out
function color.invert(c)
	return new(1 - c.r, 1 - c.g, 1 - c.b, c.a)
end

--- Lighten a color by a component-wise fixed amount (alpha unchanged)
-- @tparam color to lighten
-- @tparam number amount to increase each component by, 0-1 scale
-- @treturn color out
function color.lighten(c, v)
	return new(
		clamp(c.r + v, 0, 1),
		clamp(c.g + v, 0, 1),
		clamp(c.b + v, 0, 1),
		c.a
	)
end

function color.lerp(a, b, s)
	return a + s * (b - a)
end

--- Darken a color by a component-wise fixed amount (alpha unchanged)
-- @tparam color to darken
-- @tparam number amount to decrease each component by, 0-1 scale
-- @treturn color out
function color.darken(c, v)
	return new(
		clamp(c.r - v, 0, 1),
		clamp(c.g - v, 0, 1),
		clamp(c.b - v, 0, 1),
		c.a
	)
end

--- Multiply a color's components by a value (alpha unchanged)
-- @tparam color to multiply
-- @tparam number to multiply each component by
-- @treturn color out
function color.multiply(c, v)
	local t = color.new()
    t.r = c.r * v
    t.g = c.g * v
    t.b = c.b * v
	t.a = c.a
	return t
end

-- directly set alpha channel
-- @tparam color to alter
-- @tparam number new alpha 0-1
-- @treturn color out
function color.alpha(c, v)
	local t = color.new()
    t.r = c.r
    t.g = c.g
    t.b = c.b
	t.a = v
	return t
end

--- Multiply a color's alpha by a value
-- @tparam color to multiply
-- @tparam number to multiply alpha by
-- @treturn color out
function color.opacity(c, v)
	local t = color.new()
    t.r = c.r
    t.g = c.g
    t.b = c.b
	t.a = c.a * v
	return t
end

----- Set a color's hue (saturation, value, alpha unchanged)
---- @tparam color to alter
---- @tparam hue to set 0-359
---- @treturn color out
--function color.hue(col, hue)
--	local c = color_to_hsv(col)
--	c.r = (hue + 360) % 360
--	return hsv_to_color(c)
--end
--
----- Set a color's saturation (hue, value, alpha unchanged)
---- @tparam color to alter
---- @tparam hue to set 0-359
---- @treturn color out
--function color.saturation(col, percent)
--	local c = color_to_hsv(col)
--	c.g = clamp(percent, 0, 1)
--	return hsv_to_color(c)
--end
--
----- Set a color's value (saturation, hue, alpha unchanged)
---- @tparam color to alter
---- @tparam hue to set 0-359
---- @treturn color out
--function color.value(col, percent)
--	local c = color_to_hsv(col)
--	c.b = clamp(percent, 0, 1)
--	return hsv_to_color(c)
--end

---- http://en.wikipedia.org/wiki/SRGB#The_reverse_transformation
--function color.gamma_to_linear(r, g, b, a)
--	local function convert(c)
--		if c > 1.0 then
--			return 1.0
--		elseif c < 0.0 then
--			return 0.0
--		elseif c <= 0.04045 then
--			return c / 12.92
--		else
--			return math.pow((c + 0.055) / 1.055, 2.4)
--		end
--	end
--
--	if type(r) == "table" then
--		local c = {}
--		for i = 1, 3 do
--			c[i] = convert(r[i] / 1) * 1
--		end
--
--		c.a = convert(r.a / 1) * 1
--		return c
--	else
--		return convert(r / 1) * 1, convert(g / 1) * 1, convert(b / 1) * 1, a or 1
--	end
--end
--
---- http://en.wikipedia.org/wiki/SRGB#The_forward_transformation_.28CIE_xyY_or_CIE_XYZ_to_sRGB.29
--function color.linear_to_gamma(r, g, b, a)
--	local function convert(c)
--		if c > 1.0 then
--			return 1.0
--		elseif c < 0.0 then
--			return 0.0
--		elseif c < 0.0031308 then
--			return c * 12.92
--		else
--			return 1.055 * math.pow(c, 0.41666) - 0.055
--		end
--	end
--
--	if type(r) == "table" then
--		local c = {}
--		for i = 1, 3 do
--			c[i] = convert(r[i] / 1) * 1
--		end
--
--		c.a = convert(r.a / 1) * 1
--		return c
--	else
--		return convert(r / 1) * 1, convert(g / 1) * 1, convert(b / 1) * 1, a or 1
--	end
--end

--- Check if color is valid
-- @tparam color to test
-- @treturn boolean is color
function color.is_color(a)
	if type(a) ~= "table" then
		return false
	end

	for i = 1, 4 do
		if type(a[i]) ~= "number" then
			return false
		end
	end

	return true
end

--- Return a formatted string.
-- @tparam color a color to be turned into a string
-- @treturn string formatted
function color.to_string(a)
	return string.format("[ %3.0f, %3.0f, %3.0f, %3.0f ]", a.r, a.g, a.b, a.a)
end

function color_mt.__index(t, k)
	if type(t) == "cdata" then
		if type(k) == "number" then
			return t._c[k-1]
		end
	end

	return rawget(color, k)
end

function color_mt.__newindex(t, k, v)
	if type(t) == "cdata" then
		if type(k) == "number" then
			t._c[k-1] = v
		end
	end
end

color_mt.__tostring = color.to_string

function color_mt.__call(_, r, g, b, a)
	return color.new(r, g, b, a)
end

function color_mt.__add(a, b)
	return new(a.r + b.r, a.g + b.g, a.b + b.b, a.a + b.a)
end

function color_mt.__sub(a, b)
	return new(a.r - b.r, a.g - b.g, a.b - b.b, a.a - b.a)
end

function color_mt.__mul(a, b)
	if type(a) == "number" then
		return new(a * b.r, a * b.g, a * b.b, a * b.a)
	elseif type(b) == "number" then
		return new(b * a.r, b * a.g, b * a.b, b * a.a)
	else
		return new(a.r * b.r, a.g * b.g, a.b * b.b, a.a * b.a)
	end
end

return setmetatable({}, color_mt)
