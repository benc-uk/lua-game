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

  if love.keyboard.isDown("space") then
    local c = player:getCellFacing(map)
    if c ~= nil and c.door then
      c.blocking = not c.blocking
    end
  end

  player:move(love.timer.getDelta())

  -- Check inside a wall or out of bounds
  local cell = map:get(player.pos.x, player.pos.y)
  if (cell == nil or cell.blocking) then
    -- Move back to the last position
    player.pos = player.pos - player.facing * player.speed * love.timer.getDelta()
    player.speed = 0
  end
end

function love.mousepressed(_, _, button)
  if button == 1 then
    if love.mouse.isGrabbed() then
      love.mouse.setGrabbed(false)
      love.mouse.setRelativeMode(false)
      return
    end

    love.mouse.setGrabbed(true)
    love.mouse.setRelativeMode(true)
  end
end

function love.mousemoved(_, _, dx)
  if love.mouse.isGrabbed() then
    player:rotate(dx * 0.1)
  end
end

function love.draw()
  love.graphics.clear(0, 0, 0, 1, true, true)

  render.floorCeil(player)

  render.walls(player, map)

  render.sprites(player, map)

  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setShader()

  -- Show the FPS
  love.graphics.setFont(love.graphics.newFont(22))
  love.graphics.setColor(0, 0, 0)
  love.graphics.print("FPS: " .. love.timer.getFPS(), love.graphics.getWidth() - 120, 5)
  love.graphics.setColor(1, 1, 1)
  love.graphics.print("FPS: " .. love.timer.getFPS(), love.graphics.getWidth() - 122, 3)
end

function love.keypressed(key)
  if key == "escape" then
    love.event.quit()
  end

  if key == "f" then
    if love.window.getFullscreen() then
      love.window.setFullscreen(false)
    else
      love.window.setFullscreen(true)
    end
  end
end
