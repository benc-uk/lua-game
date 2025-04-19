local sprite = require "sprite"

local item   = {}

function item:new(cell, name, scale)
  local i = {
    id = math.random(1000),
    name = name,
    description = "An item",
    sprite = nil,
    cell = cell,
  }

  i.sprite = sprite:new(cell.x + 0.5, cell.y + 0.5, name)
  i.sprite.scale = scale or 1

  setmetatable(i, self)
  self.__index = self

  return i
end

return item
