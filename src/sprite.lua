local vec2 = require "vector"
local magic = require "magic"
local imageCache = require "image-cache"

local sprite = {}

local spriteImgCache = imageCache:load("assets/sprites")

function sprite:new(x, y, name)
  local obj = {
    pos = vec2:new(x, y),
    name = name,
    image = spriteImgCache.images[name],
    scale = 0.5,
  }

  setmetatable(obj, self)
  self.__index = self

  return obj
end

-- Draw the sprite on the screen projected on the 2D plane
function sprite:draw(camPos, camDir, camPlane)
  -- Calculate sprite position relative to camera
  local spritePos = self.pos - camPos
  local aspect = love.graphics.getWidth() / love.graphics.getHeight()

  -- Transform sprite with the inverse camera matrix
  local invDet = 1.0 / (camPlane.x * camDir.y - camDir.x * camPlane.y)
  local transX = invDet * (camDir.y * spritePos.x - camDir.x * spritePos.y)
  local transY = invDet * (-camPlane.y * spritePos.x + camPlane.x * spritePos.y)

  -- Don't draw sprites behind the camera!
  if transY <= 0 then return end

  -- Calculate screen position
  local screenX = (love.graphics.getWidth() / 2) * (1 + transX / transY)

  -- Calculate sprite dimensions on screen
  local height = math.abs(love.graphics.getHeight() / transY) * self.scale
  local width = height -- Assuming square sprite

  -- Correct for the aspect ratio of the screen
  width = width * aspect * magic.heightScale
  height = height * aspect * magic.heightScale

  -- Move the sprite down to place it on the ground
  local moveDown = height * (1 / self.scale) * 0.5 - height * 0.5
  -- The Y coordinate of the sprite on the screen
  local screenY = (love.graphics.getHeight() / 2) - (height / 2) + moveDown

  local bright = 1 - (spritePos:length() / 7) -- Brightness based on distance

  -- Finally! Draw the sprite
  love.graphics.setColor(bright, bright, bright) -- Reset color to white
  love.graphics.draw(
    self.image,
    screenX - width / 2,
    screenY,
    0,
    width / self.image:getWidth(),
    height / self.image:getHeight()
  )
end

return sprite
