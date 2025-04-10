-- Imports
local map        = require "map"
local player     = require "player"
local utils      = require "utils"
local lume       = require "lib.rxi.lume"
local imageCache = require "image-cache"
local sprite     = require "sprite"

function love.load()
  Map = map:load("level-1")

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

  SpriteCache = imageCache:load("assets/sprites")
  TestSprite = sprite:new(4.5, 2.5, "skeleton", SpriteCache)
  TestSprite2 = sprite:new(2.5, 5.5, "barrel", SpriteCache)
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
  if Map:get(Player.pos.x, Player.pos.y).isWall then
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


  local tileWidth = Map.tileSet.size.width
  local tileHeight = Map.tileSet.size.height

  -- draw walls using raycasting
  for screenX = 0, love.graphics.getWidth() do
    -- Genate a ray from the player position to the screen position
    local ray = Player:getRay(screenX)

    -- Cast the ray to find the first wall hit
    local hit = Player.pos:castRay(ray, function(x, y)
      local cell = Map:get(x, y)
      if cell and cell.isWall then
        return true
      end
      return false
    end)

    if hit.dist > 0 then
      local wallTexture = Map.tileSet.images["wall_" .. hit.mapX % 3 + 1]

      -- correct the distance to the wall for the fish-eye effect
      local wallHeightDist = hit.dist * math.cos(math.atan2(ray.y, ray.x) - math.atan2(Player.facing.y, Player.facing.x))

      -- the height of the wall on the screen is inversely proportional to the distance
      -- also correct for aspect ratio and make it a bit squashed
      local wallHeight = love.graphics.getHeight() / wallHeightDist
      wallHeight = wallHeight * (love.graphics.getWidth() / love.graphics.getHeight()) * 0.65

      local wallY = (love.graphics.getHeight() - wallHeight) / 2

      -- light falls off with distance inverse square law and should be clamped to 0 - 1
      local light = lume.clamp(1 / (hit.dist * hit.dist), 0, 1)

      light = light * 0.93 + 0.03 -- make it brighter

      -- texture mapping, get fraction of the world pos to use as the u coordinate of the texture
      local texU
      if hit.side == 0 then
        texU = utils.frac(hit.worldPos.y) -- vertical wall
      else
        texU = utils.frac(hit.worldPos.x) -- horizontal wall
      end

      -- One pixel vertical slice of the texture
      local wallSlice = love.graphics.newQuad(texU * tileWidth, 0, 1,
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

  TestSprite:draw(Player.pos, Player.facing, Player.camPlane)
  TestSprite2:draw(Player.pos, Player.facing, Player.camPlane)
end

function love.keypressed(key)
  if key == "escape" then
    love.event.quit()
  end

  if key == "f" then
    if Map.tileSet.filterMode == "nearest" then
      Map.tileSet:setFilter("linear")
    else
      Map.tileSet:setFilter("nearest")
    end
  end
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
