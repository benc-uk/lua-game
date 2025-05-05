local scale = 3
local titleShownDuration = 0

local function titleText(message, duration)
  if titleShownDuration > duration then
    return
  end

  local x = love.graphics.getWidth() / 2
  local y = love.graphics.getHeight() / 2
  local textWidth = love.graphics.getFont():getWidth(message) * scale
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.print(message, x - textWidth / 2, y - 10, 0, scale, scale)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print(message, x - 4 - textWidth / 2, y - 14, 0, scale, scale)

  titleShownDuration = titleShownDuration + love.timer.getDelta()
end

return {
  titleText = titleText,
}
