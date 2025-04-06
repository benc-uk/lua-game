local map = require "map"

function love.load()
  -- love.graphics.setDefaultFilter("nearest", "nearest")
  Map = map.load("level-1")
end

function love.update()
  -- Nothing here for now
end

function love.draw()
  love.graphics.setColor(1, 1, 1)
  love.graphics.clear()

  local image = Map.tileSet[1]
  local tileWidth = image:getWidth()
  local tileHeight = image:getHeight()

  -- Draw the map
  for i = 1, Map.width do
    for j = 1, Map.height do
      local cell = Map[i][j]
      if cell.isWall then
        local x = (i - 1) * tileWidth * 3
        local y = (j - 1) * tileHeight * 3
        love.graphics.draw(image, x, y, 0, 3, 3)
      end
    end
  end

  -- Show the FPS
  love.graphics.setColor(1, 1, 1)
  love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 10)
end
