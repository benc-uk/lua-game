-- Imports
local map = require "map"
local player = require "player"
local utils = require "utils"

function love.load()
  love.graphics.setDefaultFilter("nearest", "nearest")
  Map = map.load("level-1")

  Player = player:new(2.5, 2.5)
  Player:rotate(0)

  Floor = utils.gradientMesh("vertical",
    { 0, 0, 0 },
    { 0.4, 0.4, 0.48 }
  )

  Sky = utils.gradientMesh("vertical",
    { 0.48, 0.4, 0.4 },
    { 0, 0, 0 }

  )
end

function love.update()
  if love.keyboard.isDown("left") then
    Player:rotate(-2.5)
  elseif love.keyboard.isDown("right") then
    Player:rotate(2.5)
  end

  local movingKey = false
  if love.keyboard.isDown("up") then
    Player:accel()
    movingKey = true
  elseif love.keyboard.isDown("down") then
    Player:decel()
    movingKey = true
  end

  if not movingKey then
    Player:comeToStop()
  end

  Player:move(love.timer.getDelta())

  -- check inside a wall
  if Map[math.floor(Player.pos.x)][math.floor(Player.pos.y)].isWall then
    -- Move back to the last position
    Player.pos = Player.pos - Player.facing * Player.speed * love.timer.getDelta()
    Player.speed = 0
  end
end

function love.draw()
  love.graphics.setColor(1, 1, 1)
  love.graphics.clear()

  -- draw floor
  love.graphics.draw(Floor, 0, love.graphics.getHeight() / 2, 0, love.graphics.getWidth(), love.graphics.getHeight() / 2)
  -- draw sky
  love.graphics.draw(Sky, 0, 0, 0, love.graphics.getWidth(), love.graphics.getHeight() / 2)


  local tileWidth = Map.tiles.size.width
  local tileHeight = Map.tiles.size.height

  -- draw walls using raycasting
  for screenX = 0, love.graphics.getWidth() do
    local ray = Player:getRay(screenX)

    local hit = Player.pos:castRay(ray, function(x, y)
      local cell = Map:get(x, y)
      if cell and cell.isWall then
        return true
      end
      return false
    end)

    if hit.dist > 0 then
      local index = hit.mapX % 3
      local wallTexture = Map.tiles.images["wall_" .. index + 1]
      -- correct the distance to the wall for the fish-eye effect
      local wallHeightDist = hit.dist * math.cos(math.atan2(ray.y, ray.x) - math.atan2(Player.facing.y, Player.facing.x))

      -- the height of the wall on the screen is inversely proportional to the distance
      -- also correct for aspect ratio and make it a bit squashed
      local wallHeight = love.graphics.getHeight() / wallHeightDist
      wallHeight = wallHeight * (love.graphics.getWidth() / love.graphics.getHeight()) * 0.6

      local wallY = (love.graphics.getHeight() - wallHeight) / 2

      -- light falls off with distance inverse square law and should be clamped to 0 - 1
      local light = (1 / (hit.dist * hit.dist))
      if light > 1 then
        light = 1
      elseif light < 0 then
        light = 0
      end
      light = light * 0.93 + 0.03 -- make it brighter

      -- texture mapping
      local wallX = hit.wallX - math.floor(hit.wallX)

      -- One pixel vertical slice of the texture
      local wallSlice = love.graphics.newQuad(math.floor(wallX * tileWidth), 0, 1,
        tileHeight, tileWidth, tileHeight)
      love.graphics.setColor(light, light, light)
      love.graphics.draw(wallTexture, wallSlice, screenX, wallY, 0, 1, wallHeight / tileHeight, 0, 0)
    end
  end

  -- Show the FPS

  love.graphics.setFont(love.graphics.newFont(22))
  love.graphics.setColor(0, 0, 0)
  love.graphics.print("FPS: " .. love.timer.getFPS(), love.graphics.getWidth() - 90, 5)
  love.graphics.setColor(1, 1, 1)
  love.graphics.print("FPS: " .. love.timer.getFPS(), love.graphics.getWidth() - 92, 3)
end

-- local function overlay()
--   local image = Map.tiles["wall_1"]
--   local tileWidth = image:getWidth()
--   local tileHeight = image:getHeight()

--   -- Draw the map
--   love.graphics.scale(0.75, 0.75)
--   love.graphics.setColor(1, 1, 1, 0.6)

--   for i = 1, Map.height do
--     for j = 1, Map.width do
--       local cell = Map[i][j]
--       if cell.isWall then
--         local x = i * tileWidth
--         local y = j * tileHeight
--         love.graphics.draw(image, x, y)
--       end
--     end
--   end

--   -- Draw red circle at player position
--   love.graphics.setColor(1, 0, 0)
--   love.graphics.circle("fill", Player.pos.x * tileWidth, Player.pos.y * tileHeight, 5)

--   -- Draw a line in the direction the player is facing
--   love.graphics.setColor(0, 1, 0)
--   love.graphics.setLineWidth(2)
--   love.graphics.line(
--     Player.pos.x * tileWidth,
--     Player.pos.y * tileHeight,
--     (Player.pos.x + Player.facing.x) * tileWidth,
--     (Player.pos.y + Player.facing.y) * tileHeight
--   )
--   love.graphics.scale(1.3333, 1.3333)
-- end
