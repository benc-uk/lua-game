local vec2           = require "vector"
local magic          = require "magic"
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

  shader:send("hitDist", transY)

  -- Precompute screen dimensions and scaling factors
  local screenWidth = love.graphics.getWidth()
  local screenHeight = love.graphics.getHeight()
  local halfScreenWidth = screenWidth / 2
  local halfScreenHeight = screenHeight / 2
  local heightScale = aspect * magic.heightScale

  -- Calculate screen position
  local screenX = halfScreenWidth * (1 + transX / transY)

  -- Calculate sprite dimensions on screen
  local height = math.abs(screenHeight * (1 / transY)) * self.scale * heightScale
  local width = height --* (1 - magic.FOV) -- Assuming square sprite

  -- Calculate the visible range
  local halfWidth = width / 2
  local startX = math.max(0, math.floor(screenX - halfWidth))
  local endX = math.min(screenWidth - 1, math.floor(screenX + halfWidth))

  -- Skip if sprite is out of screen bounds
  if startX > screenWidth or endX < 0 then return end

  -- Move the sprite down to place it on the ground
  local moveDown = height * (1 / self.scale - 1) * 0.5
  local screenY = (halfScreenHeight) + moveDown
  local imageWidth = self.image:getWidth()
  local imageHeight = self.image:getHeight()

  local quad = love.graphics.newQuad(0, 0, imageWidth, imageHeight, imageWidth, imageHeight)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(self.image, quad, screenX, screenY, 0, width / imageWidth, height / imageHeight,
    imageWidth / 2,
    imageHeight / 2)
end

return sprite
