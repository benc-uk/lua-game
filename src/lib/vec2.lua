--[[
Copyright (c) 2017-2019 raidho36

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]--

-- JIT version requires LuaJIT running
assert ( type ( jit ) == 'table' and jit.status ( ) == true )

local mabs, msqrt, msin, mcos, matan2, mexp, mlog, m2pi = math.abs, math.sqrt, math.sin, math.cos, math.atan2, math.exp, math.log, math.pi * 2

local Vec2 = setmetatable ( { }, { __call = function ( class, ... ) return class.new ( ... ) end } )
Vec2.__index = Vec2

function Vec2.new ( x, y )
	return setmetatable ( { }, Vec2 ):init ( x, y )
end

function Vec2:init ( x, y )
	self.x = x or 0
	self.y = y or 0
	return self
end

function Vec2:clone ( )
	return Vec2.new ( self.x, self.y )
end

function Vec2:copy ( v )
	self.x = v.x
	self.y = v.y
	return self
end

-- vector from polar coordinates (angle, length)
function Vec2:polar ( a, l )
	self.x = mcos ( a ) * l
	self.y = msin ( a ) * l
	return self
end

function Vec2:add ( v )
	self.x = self.x + v.x
	self.y = self.y + v.y
	return self
end
function Vec2:sadd ( a, b )
	self.x = a.x + b.x
	self.y = a.y + b.y
	return self
end

function Vec2:sub ( v )
	self.x = self.x - v.x
	self.y = self.y - v.y
	return self
end
function Vec2:ssub ( a, b )
	self.x = a.x - b.x
	self.y = a.y - b.y
	return self
end

function Vec2:scale ( f )
	self.x = self.x * f
	self.y = self.y * f
	return self
end
function Vec2:sscale ( v, f )
	self.x = v.x * f
	self.y = v.y * f
	return self
end

function Vec2:addscale ( v, f )
	self.x = self.x + v.x * f
	self.y = self.y + v.y * f
	return self
end
function Vec2:saddscale ( a, b, f )
	self.x = a.x + b.x * f
	self.y = a.y + b.y * f
	return self
end

function Vec2:invert ( )
	self.x, self.y = -self.x, -self.y
	return self
end
function Vec2:sinvert ( v )
	self.x = -v.x
	self.y = -v.y
	return self
end

function Vec2:normalize ( )
	local l = 1 / msqrt ( self.x * self.x + self.y * self.y )
	self.x = self.x * l
	self.y = self.y * l
	return self
end
function Vec2:snormalize ( v )
	local l = 1 / msqrt ( v.x * v.x + v.y * v.y )
	self.x = v.x * l
	self.y = v.y * l
	return self
end

function Vec2:resize ( l )
	l = l / msqrt ( self.x * self.x + self.y * self.y )
	self.x = self.x * l
	self.y = self.y * l
	return self
end
function Vec2:sresize ( v, l )
	l = l / msqrt ( v.x * v.x + v.y * v.y )
	self.x = v.x * l
	self.y = v.y * l
	return self
end

function Vec2:len ( )
	return msqrt ( self.x * self.x + self.y * self.y )
end
function Vec2:len2 ( )
	return self.x * self.x + self.y * self.y
end

function Vec2:dir ( )
	return matan2 ( self.y, self.x )
end

-- distance to another vec2
function Vec2:dist ( v )
	local x, y = self.x - v.x, self.y - v.y
	return msqrt ( x * x + y * y )
end
function Vec2:dist2 ( v )
	local x, y = self.x - v.x, self.y - v.y
	return x * x + y * y
end

-- angle to another vec2
function Vec2:angle ( v )
	return matan2 ( v.y - self.y, v.x - self.x )
end

function Vec2:dot ( v )
	return self.x * v.x + self.y * v.y
end

-- interpolate to position between A and B
-- self is used to store result
function Vec2:lerp ( a, b, t )
	local i = 1 - t
	self.x = a.x * i + b.x * t
	self.y = a.y * i + b.y * t
	return self
end

function Vec2:pack ( )
	return { self.x, self.y }
end

function Vec2:unpack ( )
	return self.x, self.y
end

------------------------------
-- additional functionality --
------------------------------

-- cross product is not defined in 2d however orthogonal vector can still be constructed
-- use self to store result
function Vec2:cross ( v )
	self.x, self.y = -v.y, v.x
	return self
end

-- computes determinant of [A,B] matrix, also perp dot product, also area of A,B paralellogram
function Vec2:perpdot ( v )
	return self.x * v.y - self.y * v.x
end

function Vec2:mul ( f )
	self.x = self.x * f
	self.y = self.y * f
	return self
end
function Vec2:smul ( v, f )
	self.x = v.x * f
	self.y = v.y * f
	return self
end

function Vec2:div ( f )
	self.x = self.x / f
	self.y = self.y / f
	return self
end
function Vec2:div ( v, f )
	self.x = v.x / f
	self.y = v.y / f
	return self
end

-- complex number conjugation
function Vec2:conj ( )
	self.y = -self.y
	return self
end
function Vec2:sconj ( z )
	self.x =  z.x
	self.y = -z.y
	return self
end

-- complex number multiplication
function Vec2:cmul ( z )
	self.x, self.y =
		self.x * z.x - self.y * z.y,
		self.y * z.x + self.x * z.y
	return self
end
function Vec2:scmul ( a, b )
	self.x = a.x * b.x - a.y * b.y
	self.y = a.y * b.x + a.x * b.y
	return self
end

-- complex number division
function Vec2:cdiv ( z )
	local zl = z.x * z.x + z.y * z.y
	self.x, self.y =
		( self.x * z.x + self.y * z.y ) / zl,
		( self.y * z.x - self.x * z.y ) / zl
	return self
end
function Vec2:scdiv ( a, b )
	local bl = b.x * b.x + b.y * b.y
	self.x = ( a.x * b.x + a.y * b.y ) / bl
	self.y = ( a.y * b.x - a.x * b.y ) / bl
	return self
end

function Vec2:cexp ( )
	local l = mexp ( self.x )
	self.x, self.y =
		mcos ( self.y ) * l,
		msin ( self.y ) * l
	return self
end
function Vec2:scexp ( z )
	local l = mexp ( z.x )
	self.x = mcos ( z.y ) * l
	self.y = msin ( z.y ) * l
	return self
end

function Vec2:clog ( )
	self.x, self.y =
		mlog ( msqrt ( self.x * self.x + self.y * self.y ) ),
		matan2 ( self.y, self.x )
	return self
end
function Vec2:sclog ( z )
	self.x = mlog ( msqrt ( z.x * z.x + z.y * z.y ) )
	self.y = matan2 ( z.y, z.x )
	return self
end

function Vec2:cpowz ( a )
	-- z^w = e^(w*log(z))
	-- clog ( self )
	local x, y =
		mlog ( msqrt ( self.x * self.x + self.y * self.y ) ),
		matan2 ( self.y, self.x )
	-- cmul ( a, clog ( self ) )
	x, y =
		a.x * x - a.y * y,
		a.y * x + a.x * y
	-- cexp ( cmul ( a, clog ( self ) ) )
	x = mexp ( x )
	self.x, self.y =
		mcos ( y ) * x,
		msin ( y ) * x
	return self
end
function Vec2:scpowz ( z, a )
	local x, y =
		mlog ( msqrt ( z.x * z.x + z.y * z.y ) ),
		matan2 ( z.y, z.x )
	x, y =
		a.x * x - a.y * y,
		a.y * x + a.x * y
	x = mexp ( x )
	self.x, self.y =
		mcos ( y ) * x,
		msin ( y ) * x
	return self
end

function Vec2:cpow ( a )
	local x, y =
		mexp ( mlog ( msqrt ( self.x * self.x + self.y * self.y ) ) * a ),
		matan2 ( self.y, self.x ) * a
	self.x, self.y =
		mcos ( y ) * x,
		msin ( y ) * x
	return self
end
function Vec2:scpow ( z, a )
	local x, y =
		mexp ( mlog ( msqrt ( z.x * z.x + z.y * z.y ) ) * a ),
		matan2 ( z.y, z.x ) * a
	self.x, self.y =
		mcos ( y ) * x,
		msin ( y ) * x
	return self
end

local ffi = require ( "ffi" )

ffi.cdef ( "typedef struct rsml_vec2 { double x, y; } rsml_vec2;" )
Vec2.new = ffi.typeof ( "rsml_vec2" )
ffi.metatype ( "rsml_vec2", Vec2 )

return Vec2
