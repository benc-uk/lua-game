local vec2           = require "vector"
local consts         = require "consts"
local imageCache     = require "image-cache"

local sprite         = {}
local spriteImgCache = imageCache:load("assets/sprites")

function sprite:new(x, y, name)
  local obj = {
    pos = vec2:new(x, y),
    name = name,
    image = spriteImgCache.images[name],
    scale = 1,
    alpha = 1,
  }

  setmetatable(obj, self)
  self.__index = self

  return obj
end

-- Draw the sprite on the screen projected on the 2D plane
function sprite:draw(camPos, camDir, camPlane, shader)
  -- Calculate sprite position relative to camera
  local spritePos = self.pos - camPos
  local aspect = love.graphics.getWidth() / love.graphics.getHeight()

  -- Precompute inverse determinant and transformed sprite position
  local invDet = 1.0 / (camPlane.x * camDir.y - camDir.x * camPlane.y)
  local transX = invDet * (camDir.y * spritePos.x - camDir.x * spritePos.y)
  local transY = invDet * (-camPlane.y * spritePos.x + camPlane.x * spritePos.y)

  -- Don't draw sprites behind the camera!
  if transY <= 0 then return end

  -- Calculate screen position
  local screenWidth = love.graphics.getWidth()
  local screenX = (screenWidth / 2) * (1 + transX / transY)

  -- Calculate sprite dimensions on screen
  local height = math.abs(love.graphics.getHeight() * (1 / transY)) * self.scale * aspect * consts.heightScale
  local width = height -- Assuming square sprites

  -- Calculate the visible range
  local halfWidth = width / 2
  local startX = math.max(0, math.floor(screenX - halfWidth))
  local endX = math.min(screenWidth - 1, math.floor(screenX + halfWidth))

  -- Skip if sprite is out of screen bounds
  if startX > screenWidth or endX < 0 then return end

  -- Move the sprite down to place it on the ground
  local screenY = (love.graphics.getHeight() / 2) + (height * (1 / self.scale - 1) * 0.5)
  local imageWidth = self.image:getWidth()
  local imageHeight = self.image:getHeight()

  shader:send("hitDist", transY)
  local quad = love.graphics.newQuad(0, 0, imageWidth, imageHeight, imageWidth, imageHeight)
  love.graphics.draw(self.image, quad, screenX, screenY, 0, width / imageWidth, height / imageHeight,
    imageWidth / 2,
    imageHeight / 2)
end

return sprite
