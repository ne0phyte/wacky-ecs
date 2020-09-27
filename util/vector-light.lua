--[[
Copyright (c) 2012-2013 Matthias Richter
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.
Except as contained in this notice, the name(s) of the above copyright holders
shall not be used in advertising or otherwise to promote the sale, use or
other dealings in this Software without prior written authorization.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
]]--

local sqrt, cos, sin, atan2 = math.sqrt, math.cos, math.sin, math.atan2

local function str(x,y)
	return "("..tonumber(x)..","..tonumber(y)..")"
end

local function mul(s, x,y)
	return s*x, s*y
end

local function div(s, x,y)
	return x/s, y/s
end

local function add(x1,y1, x2,y2)
	return x1+x2, y1+y2
end

local function sub(x1,y1, x2,y2)
	return x1-x2, y1-y2
end

local function permul(x1,y1, x2,y2)
	return x1*x2, y1*y2
end

local function dot(x1,y1, x2,y2)
	return x1*x2 + y1*y2
end

local function det(x1,y1, x2,y2)
	return x1*y2 - y1*x2
end

local function eq(x1,y1, x2,y2)
	return x1 == x2 and y1 == y2
end

local function lt(x1,y1, x2,y2)
	return x1 < x2 or (x1 == x2 and y1 < y2)
end

local function le(x1,y1, x2,y2)
	return x1 <= x2 and y1 <= y2
end

local function len2(x,y)
	return x*x + y*y
end

local function len(x,y)
	return sqrt(x*x + y*y)
end

local function fromPolar(angle, radius)
	radius = radius or 1
	return cos(angle)*radius, sin(angle)*radius
end

local function randomDirection(len_min, len_max)
	len_min = len_min or 1
	len_max = len_max or len_min

	assert(len_max > 0, "len_max must be greater than zero")
	assert(len_max >= len_min, "len_max must be greater than or equal to len_min")

	return fromPolar(math.random()*2*math.pi,
	                 math.random() * (len_max-len_min) + len_min)
end

local function toPolar(x, y)
	return atan2(y,x), len(x,y)
end

local function dist2(x1,y1, x2,y2)
	return len2(x1-x2, y1-y2)
end

local function dist(x1,y1, x2,y2)
	return len(x1-x2, y1-y2)
end

local function normalize(x,y)
	local l = len(x,y)
	if l > 0 then
		return x/l, y/l
	end
	return x,y
end

local function rotate(phi, x,y)
	local c, s = cos(phi), sin(phi)
	return c*x - s*y, s*x + c*y
end

local function perpendicular(x,y)
	return -y, x
end

local function project(x,y, u,v)
	local s = (x*u + y*v) / (u*u + v*v)
	return s*u, s*v
end

local function mirror(x,y, u,v)
	local s = 2 * (x*u + y*v) / (u*u + v*v)
	return s*u - x, s*v - y
end

-- ref.: http://blog.signalsondisplay.com/?p=336
local function trim(maxLen, x, y)
	local s = maxLen * maxLen / len2(x, y)
	s = s > 1 and 1 or math.sqrt(s)
	return x * s, y * s
end

local function angleTo(x,y, u,v)
	if u and v then
		return atan2(y, x) - atan2(v, u)
	end
	return atan2(y, x)
end

-- variants accepting vector types {x = .., y = ..}

local function vstr(v)
	return "("..tonumber(v.x)..","..tonumber(v.y)..")"
end

local function vmul(s, v)
	return s*v.x, s*v.y
end

local function vdiv(s, v)
	return v.x/s, v.y/s
end

local function add(v1, v2)
	return v1.x+v2.x, v1.y+v2.y
end

local function vsub(v1, v2)
	return v1.x-v2.x, v1.y-v2.y
end

local function vpermul(v1, v2)
	return v1.x*v2.x, v1.y*v2.y
end

local function vdot(v1, v2)
	return v1.x*v2.x + v1.y*v2.y
end

local function vdet(v1, v2)
	return v1.x*v2.y - v1.y*v2.x
end

local function veq(v1, v2)
	return v1.x == v2.x and v1.y == v2.y
end

local function vlt(v1, v2)
	return v1.x < v2.x or (v1.x == v2.x and v1.y < v2.y)
end

local function vle(v1, v2)
	return v1.x <= v2.x and v2.y <= v2.y
end

local function vlen2(v)
	return v.x*v.x + v.y*v.y
end

local function vlen(v)
	return sqrt(v.x*v.x + v.y*v.y)
end

local function vtoPolar(v)
	return atan2(v.y,v.x), len(v.x,v.y)
end

local function vdist2(v1, v2)
	return vlen2(v1.x-v2.x, v1.y-v2.y)
end

local function vdist(v1, v2)
	return len(v1.x-v2.x, v1.y-v2.y)
end

local function vnormalize(v)
	local l = len(v.x,v.y)
	if l > 0 then
		return v.x/l, v.y/l
	end
	return v.x,v.y
end

local function vrotate(phi, v)
	local c, s = cos(phi), sin(phi)
	return c*v.x - s*v.y, s*v.x + c*v.y
end

local function vperpendicular(v)
	return -v.y, v.x
end

local function vproject(v, uv)
	local s = (v.x*uv.x + v.y*uv.y) / (uv.x*uv.x + uv.y*uv.y)
	return s*uv.x, s*uv.y
end

local function vmirror(v, uv)
	local s = 2 * (v.x*uv.x + v.y*uv.y) / (uv.x*uv.x + uv.y*uv.y)
	return s*uv.x - v.x, s*uv.y - v.y
end

-- ref.: http://blog.signalsondisplay.com/?p=336
local function vtrim(maxLen, v)
	local s = maxLen * maxLen / vlen2(v)
	s = s > 1 and 1 or math.sqrt(s)
	return v.x * s, v.y * s
end

local function vangleTo(v, uv)
	if uv then
		return atan2(v.y, v.x) - atan2(uv.y, uv.x)
	end
	return atan2(v.y, v.x)
end

-- the module
return {
	str = str,

	fromPolar       = fromPolar,
	toPolar         = toPolar,
	randomDirection = randomDirection,

	vtoPolar         = vtoPolar,

	-- arithmetic
	mul    = mul,
	div    = div,
	idiv   = idiv,
	add    = add,
	sub    = sub,
	permul = permul,
	dot    = dot,
	det    = det,
	cross  = det,

	vmul    = vmul,
	vdiv    = vdiv,
	vidiv   = vidiv,
	vadd    = vadd,
	vsub    = vsub,
	vpermul = vpermul,
	vdot    = vdot,
	vdet    = vdet,
	vcross  = vdet,

	-- relation
	eq = eq,
	lt = lt,
	le = le,

	veq = veq,
	vlt = vlt,
	vle = vle,

	-- misc operations
	len2          = len2,
	len           = len,
	dist2         = dist2,
	dist          = dist,
	normalize     = normalize,
	rotate        = rotate,
	perpendicular = perpendicular,
	project       = project,
	mirror        = mirror,
	trim          = trim,
	angleTo       = angleTo,

	vlen2          = vlen2,
	vlen           = vlen,
	vdist2         = vdist2,
	vdist          = vdist,
	vnormalize     = vnormalize,
	vrotate        = vrotate,
	vperpendicular = vperpendicular,
	vproject       = vproject,
	vmirror        = vmirror,
	vtrim          = vtrim,
	vangleTo       = vangleTo,
}
