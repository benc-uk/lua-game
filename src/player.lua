local Vec2 = require "vector"

local function new(x, y, angle)
  local player = {
    pos = Vec2:new(x, y),
    facing = Vec2:new(0, -1),
    angle = angle or 0,
    speed = 0,
    maxSpeed = 3,
    acceleration = 4,
  }

  player.facing:rotate(player.angle)

  return player
end

return {
  new = new,
}
