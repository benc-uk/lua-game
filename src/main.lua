local mapLib   = require "map"
local player   = require "player"
local render   = require "render"
local sounds   = require "sounds"
local controls = require "controls"
local hud      = require "hud"

local map      = {}
local world    = love.physics.newWorld(0, 0, true)

function love.load()
  print("🚀 Starting game...")

  map = mapLib:load("level-2", world)

  player.create(map.playerStartCell.x + 0.5, map.playerStartCell.y + 0.5, world)
  player.setAngle(map.playerStartDir * (math.pi / 2))
  print("🙍‍♂️ Player created and placed: " .. player.getPosition())

  render.init(map.tileSetName, map.tileSet.size.width)

  print("♻️ Starting game loop...")

  sounds.bgLoop:play()
end

function love.update(dt)
  for _, fsm in ipairs(map.stateMachines) do
    fsm:update(dt)
  end

  controls.update(dt, player, map)
  world:update(dt)
  player.update(dt)
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
  if player.getBody() == nil then
    return
  end

  love.graphics.clear(0, 0, 0, 1, true, true)

  render.floorCeil(player)

  render.walls(player, map)

  render.sprites(player, map)

  hud.debug()
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

function love.mousemoved(_, _, dx, _)
  if love.mouse.isGrabbed() then
    controls.mouseMove(player, dx)
  end
end
