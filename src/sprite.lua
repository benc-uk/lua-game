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
    scale = 1,
    alpha = 1,
  }

  setmetatable(obj, self)
  self.__index = self

  return obj
end

-- Draw the sprite on the screen projected on the 2D plane
function sprite:draw(camPos, camDir, camPlane, zBuffer)
  -- Calculate sprite position relative to camera
  local spritePos = self.pos - camPos
  local aspect = love.graphics.getWidth() / love.graphics.getHeight()

  -- Precompute inverse determinant and transformed sprite position
  local invDet = 1.0 / (camPlane.x * camDir.y - camDir.x * camPlane.y)
  local transX = invDet * (camDir.y * spritePos.x - camDir.x * spritePos.y)
  local transY = invDet * (-camPlane.y * spritePos.x + camPlane.x * spritePos.y)

  -- Don't draw sprites behind the camera!
  if transY <= 0 then return end

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
  local width = height -- Assuming square sprite

  -- Calculate the visible range
  local halfWidth = width / 2
  local startX = math.max(0, math.floor(screenX - halfWidth))
  local endX = math.min(screenWidth - 1, math.floor(screenX + halfWidth))

  -- Skip if sprite is out of screen bounds
  if startX > screenWidth or endX < 0 then return end

  -- Move the sprite down to place it on the ground
  local moveDown = height * (1 / self.scale - 1) * 0.5
  local screenY = halfScreenHeight - height / 2 + moveDown

  -- Compute brightness factor
  local bright = 1 - (spritePos:length() / 5)
  bright = math.max(0.1, math.min(1, bright))

  -- Draw sprite by vertical slices
  local imageWidth = self.image:getWidth()
  local imageHeight = self.image:getHeight()

  local a = 1
  if self.alpha < 1 then a = self.alpha * bright end
  love.graphics.setColor(bright, bright, bright, a)

  for x = startX, endX do
    -- Calculate which slice of the sprite texture to use
    local texX = math.floor((x - (screenX - halfWidth)) / width * imageWidth)

    -- Check if this vertical line is visible in the z-buffer
    if transY < zBuffer[x] then
      -- Create a quad for the vertical slice
      local quad = love.graphics.newQuad(texX, 0, 1, imageHeight, imageWidth, imageHeight)
      -- Draw the vertical slice of the sprite
      love.graphics.draw(self.image, quad, x, screenY, 0, 1, height / imageHeight, 0, 0)
    end
  end
end

return sprite
