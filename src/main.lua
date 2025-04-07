-- Imports
local map = require "map"
local player = require "player"
local utils = require "utils"

local MAX_DISTANCE = 7

function love.load()
  -- love.graphics.setDefaultFilter("nearest", "nearest")
  Map = map.load("level-1")

  Player = player:new(2.5, 2.5)
  Player:rotate(0)

  Floor = utils.gradientMesh("vertical",
    { 0, 0, 0 },
    { 0, 0.6, 0 }
  )

  Sky = utils.gradientMesh("vertical",
    { 0.7, 0.7, 1 },
    { 0.2, 0.2, 0.6 },
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

-- Brute-force raycasting algorithm
-- This is a simple implementation of raycasting that checks for wall collisions
local function castRay(pos, dir)
  local step = 0.02
  local x, y = pos.x, pos.y
  local dx, dy = dir.x, dir.y

  local distance = 0
  while distance < MAX_DISTANCE do
    x = x + dx * step
    y = y + dy * step
    distance = distance + step

    local cellX = math.floor(x)
    local cellY = math.floor(y)

    -- Check if the cell is a wall
    if Map[cellX] and Map[cellX][cellY] and Map[cellX][cellY].isWall then
      return distance
    end
  end

  return -1
end


function love.draw()
  love.graphics.setColor(1, 1, 1)
  love.graphics.clear()

  local image = Map.tiles["wall_1"]
  local tileWidth = image:getWidth()
  local tileHeight = image:getHeight()

  -- draw a floor
  love.graphics.draw(Floor, 0, love.graphics.getHeight() / 2, 0, love.graphics.getWidth(), love.graphics.getHeight() / 2)
  -- draw a sky
  love.graphics.draw(Sky, 0, 0, 0, love.graphics.getWidth(), love.graphics.getHeight() / 2)

  -- draw walls using raycasting
  for screenX = 0, love.graphics.getWidth() do
    local ray = Player:getRay(screenX)

    local dist = castRay(Player.pos, ray)
    if dist > 0 then
      -- correct the distance to the wall for the fish-eye effect
      local wallHeightDist = dist * math.cos(math.atan2(ray.y, ray.x) - math.atan2(Player.facing.y, Player.facing.x))

      -- the height of the wall on the screen is inversely proportional to the distance
      -- also correct for aspect ratio
      local wallHeight = love.graphics.getHeight() / wallHeightDist
      wallHeight = wallHeight * (love.graphics.getWidth() / love.graphics.getHeight()) * 0.75

      local wallY = (love.graphics.getHeight() - wallHeight) / 2

      -- logarithmic color gradient for walls
      local c = 1 - math.log(dist) / math.log(MAX_DISTANCE)
      c = c * 0.75
      love.graphics.setColor(c, c + 0.05, c + 0.05)

      love.graphics.rectangle("fill", screenX, wallY, love.graphics.getWidth() / love.graphics.getWidth(), wallHeight)
    end
  end

  love.graphics.setColor(1, 1, 1)

  -- Draw the map
  love.graphics.scale(0.75, 0.75)
  for i = 1, Map.height do
    for j = 1, Map.width do
      local cell = Map[i][j]
      if cell.isWall then
        local x = i * tileWidth
        local y = j * tileHeight
        love.graphics.draw(image, x, y)
      end
    end
  end

  -- Draw red circle at player position
  love.graphics.setColor(1, 0, 0)
  love.graphics.circle("fill", Player.pos.x * tileWidth, Player.pos.y * tileHeight, 5)

  -- Draw a line in the direction the player is facing
  love.graphics.setColor(0, 1, 0)
  love.graphics.setLineWidth(2)
  love.graphics.line(
    Player.pos.x * tileWidth,
    Player.pos.y * tileHeight,
    (Player.pos.x + Player.facing.x) * tileWidth,
    (Player.pos.y + Player.facing.y) * tileHeight
  )
  love.graphics.scale(1.3333, 1.3333)

  -- Show the FPS
  love.graphics.setColor(0, 0, 0)
  love.graphics.setFont(love.graphics.newFont(22))
  love.graphics.print("FPS: " .. love.timer.getFPS(), love.graphics.getWidth() - 85, 5)
end
