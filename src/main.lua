local map = require "map"
local player = require "player"

function love.load()
  -- love.graphics.setDefaultFilter("nearest", "nearest")
  Map = map.load("level-1")

  Player = player.new(2.5, 2.5, 45)
end

function love.update()
  local keyHeld = love.keyboard.isDown("left", "right", "up", "down")

  if love.keyboard.isDown("left") then
    Player.facing:rotate(-5)
  elseif love.keyboard.isDown("right") then
    Player.facing:rotate(5)
  end

  if love.keyboard.isDown("up") then
    print(Player.pos)
    Player.speed = Player.speed + (Player.acceleration * love.timer.getDelta())
    if Player.speed >= Player.maxSpeed then
      Player.speed = Player.maxSpeed
    end
  elseif love.keyboard.isDown("down") then
    Player.speed = Player.speed - (Player.acceleration * love.timer.getDelta())
    if Player.speed <= -Player.maxSpeed then
      Player.speed = -Player.maxSpeed
    end
  end

  if Player.speed ~= 0 and not keyHeld then
    if Player.speed > 0 then
      Player.speed = Player.speed - (Player.acceleration * love.timer.getDelta() * 5)
      if Player.speed < 0 then
        Player.speed = 0
      end
    elseif Player.speed < 0 then
      Player.speed = Player.speed + (Player.acceleration * love.timer.getDelta() * 5)
      if Player.speed > 0 then
        Player.speed = 0
      end
    end
  end

  Player.pos = Player.pos + Player.facing * Player.speed * love.timer.getDelta()

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
  love.graphics.scale(2, 2)

  local image = Map.tiles["wall_1"]
  local tileWidth = image:getWidth()
  local tileHeight = image:getHeight()
  love.graphics.translate(-tileWidth, -tileHeight)

  -- Draw the map
  for i = 1, Map.width do
    for j = 1, Map.height do
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

  -- Show the FPS
  love.graphics.scale(0.5, 0.5)
  love.graphics.setColor(1, 1, 1)
  love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 10)
end
