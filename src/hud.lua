local player = require("player")

local function dropShadowText(x, y, message, size, scale)
  local offset = size * 0.1
  love.graphics.setFont(love.graphics.newFont(size))
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.print(message, x + offset, y + offset, 0, scale, scale)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print(message, x, y, 0, scale, scale)
end

local function debug()
  local fps = love.timer.getFPS()
  local playerPos = player.getPosition()
  local playerPosStr = string.format("Pos: %.2f, %.2f", playerPos.x, playerPos.y)

  dropShadowText(5, 5, "FPS: " .. fps, 16, 1)
  dropShadowText(5, 25, playerPosStr, 16, 1)
  dropShadowText(5, 45, string.format("Angle: %.2f", math.deg(player.getAngle())), 16, 1)
  dropShadowText(5, 65, string.format("Speed: %.2f", player.getSpeed()), 16, 1)
end

return {
  titleText = function() end,
  dropShadowText = dropShadowText,
  debug = debug,
}
