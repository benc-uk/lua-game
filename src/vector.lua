local vec2 = {}

-- vec2 class constructor
function vec2:new(x, y)
  local obj = { x = x or 0, y = y or 0 }
  setmetatable(obj, self)
  self.__index = self
  return obj
end

-- Create a new vec2 object with the same values as this one
function vec2:clone()
  return vec2:new(self.x, self.y)
end

-- Add another vector to this vector in place
function vec2:add(v)
  self.x = self.x + v.x
  self.y = self.y + v.y
end

-- Add another vector to this vector and return a new vector
function vec2:addNew(v)
  return vec2:new(self.x + v.x, self.y + v.y)
end

-- Add another vector to this vector and return a new vector
function vec2:__add(v)
  return vec2:new(self.x + v.x, self.y + v.y)
end

-- Subtract another vector from this vector in place
function vec2:sub(v)
  self.x = self.x - v.x
  self.y = self.y - v.y
end

-- Subtract another vector from this vector and return a new vector
function vec2:subNew(v)
  return vec2:new(self.x - v.x, self.y - v.y)
end

-- Subtract another vector from this vector and return a new vector
function vec2:__sub(v)
  return vec2:new(self.x - v.x, self.y - v.y)
end

-- Scale the vector in place by a scalar
function vec2:scale(f)
  self.x = self.x * f
  self.y = self.y * f
end

-- Scale the vector by a scalar and return a new scaled vector
function vec2:scaleNew(f)
  return vec2:new(self.x * f, self.y * f)
end

-- multiplication with a scalar or another vector
function vec2:__mul(o)
  if type(o) == "number" then
    return vec2:new(self.x * o, self.y * o)
  elseif getmetatable(o) == vec2 then
    return vec2:new(self.x * o.x, self.y * o.y)
  else
    error("Invalid operand for vec2 multiplication")
  end
end

-- Normalize the vector in place
function vec2:normalize()
  local length = math.sqrt(self.x ^ 2 + self.y ^ 2)
  if length > 0 then
    self.x = self.x / length
    self.y = self.y / length
  end
end

-- Normalize the vector and return a new normalized vector
function vec2:normalizeNew()
  local length = math.sqrt(self.x ^ 2 + self.y ^ 2)
  if length > 0 then
    return vec2:new(self.x / length, self.y / length)
  else
    return vec2:new(0, 0)
  end
end

-- Returns the dot product of two 2D vectors
function vec2:dot(v)
  return self.x * v.x + self.y * v.y
end

-- Returns the cross product of two 2D vectors
function vec2:cross(v)
  return self.x * v.y - self.y * v.x
end

-- Returns the length of the vector
function vec2:length()
  return math.sqrt(self.x ^ 2 + self.y ^ 2)
end

-- Returns the distance between two vectors
function vec2:distance(v)
  return math.sqrt((self.x - v.x) ^ 2 + (self.y - v.y) ^ 2)
end

-- Rotate the vector by a given angle in degrees
function vec2:rotate(deg)
  local rad = math.rad(deg)
  local cos = math.cos(rad)
  local sin = math.sin(rad)

  local x = self.x * cos - self.y * sin
  local y = self.x * sin + self.y * cos

  self.x = x
  self.y = y

  return self
end

-- tostring method for debugging
function vec2:__tostring()
  return string.format("vec2(%f, %f)", self.x, self.y)
end

return vec2
