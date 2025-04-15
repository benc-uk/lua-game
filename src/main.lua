local mapLib    = require "map"
local playerLib = require "player"
local render    = require "render"

local map       = {}
local player    = {}

function love.load()
  map = mapLib:load("level-1")

  player = playerLib:new(map.playerStartCell[1] + 0.5, map.playerStartCell[2] + 0.5)
  player:rotate(map.playerStartDir * 90)

  render.init(map.tileSetName, map.tileSet.size.width)
end

function love.update()
  if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
    player:rotate(-2)
  elseif love.keyboard.isDown("right") or love.keyboard.isDown("d") then
    player:rotate(2)
  end

  local movingKey = false
  if love.keyboard.isDown("up") or love.keyboard.isDown("w") then
    player:accel()
    movingKey = true
  elseif love.keyboard.isDown("down") or love.keyboard.isDown("s") then
    player:decel()
    movingKey = true
  end

  if not movingKey then
    player:comeToStop()
  end

  player:move(love.timer.getDelta())

  -- Check inside a wall or out of bounds
  local cell = map:get(player.pos.x, player.pos.y)
  if (cell == nil or cell.isWall) then
    -- Move back to the last position
    player.pos = player.pos - player.facing * player.speed * love.timer.getDelta()
    player.speed = 0
  end
end

function love.mousepressed(_, _, button)
  if button == 1 then
    if love.mouse.isGrabbed() then
      love.mouse.setGrabbed(false)
      love.mouse.setVisible(true)
      return
    end

    love.mouse.setGrabbed(true)
    love.mouse.setVisible(false)
  end
end

function love.mousemoved(x)
  if love.mouse.isGrabbed() then
    -- Calculate the angle to turn based on mouse movement
    local sensitivity = 0.1
    local centerXDiff = love.graphics.getWidth() / 2 - x
    local angle = -centerXDiff * sensitivity

    -- Rotate the player based on mouse movement
    player:rotate(angle)

    -- Reset mouse position to the center of the window
    local centerX = love.graphics.getWidth() / 2
    local centerY = love.graphics.getHeight() / 2
    love.mouse.setPosition(centerX, centerY)
  end
end

function love.draw()
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.clear()

  render.floorCeil(player)

  local zBuffer = render.walls(player, map)

  render.sprites(player, map, zBuffer)

  -- Show the FPS
  love.graphics.setFont(love.graphics.newFont(22))
  love.graphics.setColor(0, 0, 0)
  love.graphics.print("FPS: " .. love.timer.getFPS(), love.graphics.getWidth() - 90, 5)
  love.graphics.setColor(1, 1, 1)
  love.graphics.print("FPS: " .. love.timer.getFPS(), love.graphics.getWidth() - 92, 3)
end

function love.keypressed(key)
  if key == "escape" then
    love.event.quit()
  end

  if key == "f" then
    if love.window.getFullscreen() then
      love.window.setFullscreen(false)
    else
      love.window.setFullscreen(true, "exclusive")
    end
  end
end
