local mapLib    = require "map"
local playerLib = require "player"
local render    = require "render"
local sounds    = require "sounds"
local controls  = require "controls"

local map       = {}
local player    = {}
local world     = love.physics.newWorld(0, 0, true)

function love.load()
  print("🚀 Starting game...")

  map = mapLib:load("level-1")

  player = playerLib:new(map.playerStartCell.x + 0.5, map.playerStartCell.y + 0.5, world)
  player:setAngle(map.playerStartDir * (math.pi / 2))
  print("🙍‍♂️ Player created and placed: " .. player:getPosition())

  render.init(map.tileSetName, map.tileSet.size.width)

  print("♻️ Starting game loop...")

  sounds.bgLoop:play()
end

function love.update(dt)
  for _, fsm in ipairs(map.stateMachines) do
    fsm:update(dt)
  end

  controls.update(dt, player, map)

  -- Update the physics world
  local oldPos = player:getPosition()

  world:update(dt)

  player:update(dt, map, oldPos)
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

function love.draw()
  love.graphics.clear(0, 0, 0, 1, true, true)

  render.floorCeil(player)

  render.walls(player, map)

  render.sprites(player, map)

  -- Show the FPS
  love.graphics.setFont(love.graphics.newFont(22))
  love.graphics.setColor(0, 0, 0)
  love.graphics.print("FPS: " .. love.timer.getFPS(), love.graphics.getWidth() - 120, 5)
  love.graphics.setColor(1, 1, 1)
  love.graphics.print("FPS: " .. love.timer.getFPS(), love.graphics.getWidth() - 122, 3)

  -- Debug player
  local playerPos = player:getPosition()
  love.graphics.setColor(1, 1, 1)
  love.graphics.print("Player: " .. playerPos.x .. ", " .. playerPos.y, 10, 10)
  love.graphics.print("Angle: " .. player.body:getAngle(), 10, 30)
  love.graphics.print("Speed: " .. player.body:getLinearVelocity(), 10, 50)
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

  controls.keyDown(key)
end

function love.keyreleased(key)
  controls.keyUp(key)
end
