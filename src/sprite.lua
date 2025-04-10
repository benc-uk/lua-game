local vec2 = require "vector"
local sprite = {}

function sprite:new(x, y, name, cache)
  local obj = {
    pos = vec2:new(x, y),
    name = "bob",
    image = cache.images[name],
  }

  setmetatable(obj, self)
  self.__index = self

  return obj
end

-- Draw the sprite on the screen projected on the 2D plane
function sprite:draw(camPos, camDir, camPlane)
  -- Calculate sprite position relative to camera
  -- Sprites are anchored to the floor (bottom of the sprite is at y=0)
  local spritePos = self.pos - camPos

  -- Transform sprite with the inverse camera matrix
  local invDet = 1.0 / (camPlane.x * camDir.y - camDir.x * camPlane.y)
  local transformX = invDet * (camDir.y * spritePos.x - camDir.x * spritePos.y)
  local transformY = invDet * (-camPlane.y * spritePos.x + camPlane.x * spritePos.y)

  -- Don't draw sprites behind the camera
  if transformY <= 0 then return end

  -- Calculate screen position
  local spriteScreenX = (love.graphics.getWidth() / 2) * (1 + transformX / transformY)

  -- Calculate sprite dimensions on screen
  local spriteHeight = math.abs(love.graphics.getHeight() / transformY)
  local spriteWidth = spriteHeight -- Assuming square sprite

  -- draw sprie as if it's on he floor, with the bottom of the sprite at y=0
  -- Calculate the starting y position for drawing the sprite
  local drawStartY = (love.graphics.getHeight() / 2) + (spriteHeight * 0.20) - (spriteHeight / 2)

  -- Draw the sprite
  love.graphics.draw(
    self.image,
    spriteScreenX - spriteWidth / 2,
    drawStartY,
    0,
    spriteWidth / self.image:getWidth(),
    spriteHeight / self.image:getHeight()
  )
end

return sprite
