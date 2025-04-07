local vec2 = {}

function vec2:new(x, y)
  local obj = { x = x or 0, y = y or 0 }
  setmetatable(obj, self)
  self.__index = self
  return obj
end

function vec2:clone()
  return vec2:new(self.x, self.y)
end

function vec2:add(v)
  self.x = self.x + v.x
  self.y = self.y + v.y
end

function vec2:addNew(v)
  return vec2:new(self.x + v.x, self.y + v.y)
end

function vec2:__add(v)
  return vec2:new(self.x + v.x, self.y + v.y)
end

function vec2:sub(v)
  self.x = self.x - v.x
  self.y = self.y - v.y
end

function vec2:subNew(v)
  return vec2:new(self.x - v.x, self.y - v.y)
end

function vec2:__sub(v)
  return vec2:new(self.x - v.x, self.y - v.y)
end

function vec2:scale(f)
  self.x = self.x * f
  self.y = self.y * f
end

function vec2:scaleNew(f)
  return vec2:new(self.x * f, self.y * f)
end

function vec2:__mul(f)
  return vec2:new(self.x * f, self.y * f)
end

function vec2:normalize()
  local length = math.sqrt(self.x ^ 2 + self.y ^ 2)
  if length > 0 then
    self.x = self.x / length
    self.y = self.y / length
  end
end

function vec2:normalizeNew()
  local length = math.sqrt(self.x ^ 2 + self.y ^ 2)
  if length > 0 then
    return vec2:new(self.x / length, self.y / length)
  else
    return vec2:new(0, 0)
  end
end

function vec2:dot(v)
  return self.x * v.x + self.y * v.y
end

function vec2:cross(v)
  return self.x * v.y - self.y * v.x
end

function vec2:length()
  return math.sqrt(self.x ^ 2 + self.y ^ 2)
end

function vec2:distance(v)
  return math.sqrt((self.x - v.x) ^ 2 + (self.y - v.y) ^ 2)
end

function vec2:angle()
  return math.atan2(self.y, self.x)
end

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
