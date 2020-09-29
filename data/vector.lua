--[[
Copyright (c) 2010-2013 Matthias Richter
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

local assert = assert
local sqrt, cos, sin, atan2 = math.sqrt, math.cos, math.sin, math.atan2

local vector = {}
vector.__index = vector

local pool = {}
local head = 0
local stack = {}

-- for i=1, 1000000 do
--   pool[i] = setmetatable({x = 0, y = 0}, vector)
-- end

local function take(x, y)
  head = head + 1
  local vec = pool[head]
  if vec then
    if x and y then
      vec.x, vec.y = x, y
    end
  else
    vec = setmetatable({x = x or 0, y = y or 0}, vector)
    pool[head] = vec
  end
  return vec
end

local function push()
  stack[#stack + 1] = head
end

local function pop()
  head = stack[#stack]
  stack[#stack] = nil
end

local function free(size)
  head = 0
  if size and size >= 0 then
    for i=size+1,#pool do
      pool[i] = nil
    end
  end
end

local function poolsize()
  return #pool
end

local function new(x,y)
	return setmetatable({x = x or 0, y = y or 0}, vector)
end
local zero = new(0,0)

local function fromPolar(angle, radius)
	radius = radius or 1
	return take(cos(angle) * radius, sin(angle) * radius)
end

local function randomDirection(len_min, len_max)
	len_min = len_min or 1
	len_max = len_max or len_min

	assert(len_max > 0, "len_max must be greater than zero")
	assert(len_max >= len_min, "len_max must be greater than or equal to len_min")

	return fromPolar(math.random() * 2*math.pi,
	                 math.random() * (len_max-len_min) + len_min)
end

local function isvector(v)
	return type(v) == 'table' and type(v.x) == 'number' and type(v.y) == 'number'
end

function vector:clone()
	return take(self.x, self.y)
end

function vector:keep()
	return new(self.x, self.y)
end

function vector:push()
  push()
  return self
end

function vector:pop()
  pop()
  return self
end

function vector:unpack()
	return self.x, self.y
end

function vector:__tostring()
	return "("..tonumber(self.x)..","..tonumber(self.y)..")"
end

function vector.__unm(a)
	return take(-a.x, -a.y)
end

function vector.__add(a,b)
-- 	assert(isvector(a) and isvector(b), "Add: wrong argument types (<vector> expected)")
	return take(a.x+b.x, a.y+b.y)
end

function vector.__sub(a,b)
-- 	assert(isvector(a) and isvector(b), "Sub: wrong argument types (<vector> expected)")
	return take(a.x-b.x, a.y-b.y)
end

function vector.__mul(a,b)
	if type(a) == "number" then
		return take(a*b.x, a*b.y)
	elseif type(b) == "number" then
		return take(b*a.x, b*a.y)
	else
-- 		assert(isvector(a) and isvector(b), "Mul: wrong argument types (<vector> or <number> expected)")
		return a.x*b.x + a.y*b.y
	end
end

function vector:vsub(v)
  self.x = self.x - v.x
  self.y = self.y - v.y
  return self
end

function vector:vadd(v)
  self.x = self.x + v.x
  self.y = self.y + v.y
  return self
end

function vector:vdiv(v)
  self.x = self.x / v.x
  self.y = self.y / v.y
  return self
end

function vector:div(n)
  self.x = self.x / n
  self.y = self.y / n
  return self
end

function vector:vmul(v)
  self.x = self.x * v.x
  self.y = self.y * v.y
  return self
end

function vector:mul(n)
  self.x = self.x * n
  self.y = self.y * n
  return self
end

function vector:dot(v)
  return self.x * v.x + self.y * v.y
end

function vector:vset(v)
  self.x = v.x
  self.y = v.y
  return self
end

function vector:set(x, y)
  self.x = x
  self.y = y
  return self
end

function vector:__mul(a)
	if type(self) == "number" then
		return take(self * a.x, self * a.y)
	elseif type(a) == "number" then
		return take(self.x * a, self.y * a)
	else
-- 		assert(isvector(a) and isvector(b), "Mul: wrong argument types (<vector> or <number> expected)")
		return self.x * a.x + self.y * a.y
	end
end

function vector.__div(a,b)
-- 	assert(isvector(a) and type(b) == "number", "wrong argument types (expected <vector> / <number>)")
	return take(a.x / b, a.y / b)
end

function vector.__eq(a,b)
	return a.x == b.x and a.y == b.y
end

function vector.__lt(a,b)
	return a.x < b.x or (a.x == b.x and a.y < b.y)
end

function vector.__le(a,b)
	return a.x <= b.x and a.y <= b.y
end

function vector.permul(a,b)
	assert(isvector(a) and isvector(b), "permul: wrong argument types (<vector> expected)")
	return take(a.x*b.x, a.y*b.y)
end

function vector:toPolar()
	return take(atan2(self.x, self.y), self:len())
end

function vector:len2()
	return self.x^2 + self.y^2
end

function vector:len()
	return sqrt(self.x^2 + self.y^2)
end

function vector.dist(a, b)
-- 	assert(isvector(a) and isvector(b), "dist: wrong argument types (<vector> expected)")
	local dx = a.x - b.x
	local dy = a.y - b.y
	return sqrt(dx * dx + dy * dy)
end

function vector.dist2(a, b)
-- 	assert(isvector(a) and isvector(b), "dist: wrong argument types (<vector> expected)")
	local dx = a.x - b.x
	local dy = a.y - b.y
	return (dx * dx + dy * dy)
end

function vector:normalizeInplace()
	local l = self:len()
	if l > 0 then
		self.x, self.y = self.x / l, self.y / l
	end
	return self
end

function vector:normalized()
	return take(self.x, self.y):normalizeInplace()
end

function vector:rotateInplace(phi)
	local c, s = cos(phi), sin(phi)
	self.x, self.y = c * self.x - s * self.y, s * self.x + c * self.y
	return self
end

function vector:rotated(phi)
	local c, s = cos(phi), sin(phi)
	return take(c * self.x - s * self.y, s * self.x + c * self.y)
end

function vector:perpendicular()
	return take(-self.y, self.x)
end

function vector:projectOn(v)
	assert(isvector(v), "invalid argument: cannot project vector on " .. type(v))
	-- (self * v) * v / v:len2()
	local s = (self.x * v.x + self.y * v.y) / (v.x * v.x + v.y * v.y)
	return take(s * v.x, s * v.y)
end

function vector:mirrorOn(v)
	assert(isvector(v), "invalid argument: cannot mirror vector on " .. type(v))
	-- 2 * self:projectOn(v) - self
	local s = 2 * (self.x * v.x + self.y * v.y) / (v.x * v.x + v.y * v.y)
	return take(s * v.x - self.x, s * v.y - self.y)
end

function vector:cross(v)
	assert(isvector(v), "cross: wrong argument types (<vector> expected)")
	return self.x * v.y - self.y * v.x
end

-- ref.: http://blog.signalsondisplay.com/?p=336
function vector:trimInplace(maxLen)
	local s = maxLen * maxLen / self:len2()
-- 	if s >
	s = (s > 1 and 1) or math.sqrt(s)
	self.x, self.y = self.x * s, self.y * s
	return self
end

function vector:angleTo(other)
	if other then
		return atan2(self.y, self.x) - atan2(other.y, other.x)
	end
	return atan2(self.y, self.x)
end

function vector:trimmed(maxLen)
	return take(self.x, self.y):trimInplace(maxLen)
end

-- function vector:set(a, b)
--   if isvector(a) then
--     self.x = a.x
--     self.y = a.y
--   elseif type(a) == "number" and type(b) == "number" then
--     self.x = a
--     self.y = b
--   else
--     error("dist: invalid argument types (expected <vector> or <number> <number>)")
--   end
-- end


-- the module
return setmetatable({
	new             = new,
	fromPolar       = fromPolar,
	randomDirection = randomDirection,
	isvector        = isvector,
	zero            = zero,

	free            = free,
	push            = push,
	pop             = pop,
	take            = take,
	poolsize        = poolsize
}, {
	__call = function(_, ...) return new(...) end
})
