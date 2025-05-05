local vec2         = require "vector"
local consts       = require "consts"
local stateMachine = require "state"
local sounds       = require "sounds"

local moveForce    = 0.1285
local turnSpeed    = math.rad(0.19) -- radians per second

local facing       = vec2:new(1, 0)
local camPlane     = vec2:new(0, consts.FOV) -- Camera plane perpendicular to the facing direction
local angle        = 0

local state        = stateMachine:new()
local shape        = love.physics.newCircleShape(0.15)
local body         = nil

local function create(x, y, world)
  body = love.physics.newBody(world, x, y, "dynamic")
  body:setMass(1)
  body:setLinearDamping(9)
  body:setInertia(0)
  body:setAngularDamping(18)
  local fix = love.physics.newFixture(body, shape, 1)
  fix:setFriction(0)
  fix:setCategory(1)

  state:addState("idle", {})
  state:changeState("idle")
end

local function setAngle(a)
  angle = a
  if angle < 0 then
    angle = angle + math.pi * 2
  end
  if angle > math.pi * 2 then
    angle = angle - math.pi * 2
  end

  facing.x = math.cos(angle)
  facing.y = math.sin(angle)
  camPlane.x = -facing.y * consts.FOV
  camPlane.y = facing.x * consts.FOV
end

local function update(dt)
  state:update(dt)

  if body == nil then
    return
  end

  setAngle(body:getAngle())
end

local function move(dt, dir)
  if body == nil then
    return
  end

  body:applyForce(
    facing.x * dir * dt * moveForce,
    facing.y * dir * dt * moveForce
  )
  sounds.playFoot()
end

local function turn(dt, dir)
  if body == nil then
    return
  end

  body:applyTorque(dir * dt * turnSpeed)
end

local function strafe(dt, dir)
  if body == nil then
    return
  end

  body:applyForce(
    facing.y * dir * dt * moveForce,
    -facing.x * dir * dt * moveForce
  )
end

-- Gets the player's position in world coordinates as a vec2
local function getPosition()
  if body == nil then
    return vec2:new(0, 0)
  end

  local x, y = body:getPosition()
  return vec2:new(x, y)
end

-- Constructs a ray from the player's position to the screen coordinates
local function getRay(screenX)
  local cameraX = 2 * screenX / love.graphics.getWidth() - 1 -- X-coordinate in camera space

  local ray = vec2:new(
    facing.x + camPlane.x * cameraX,
    facing.y + camPlane.y * cameraX
  )

  return ray:normalizeNew()
end

-- Fires a ray from the player's position and returns any cell within a distance of 1
local function getCellFacing(map)
  if body == nil then
    return
  end

  local x, y = body:getPosition()
  local ray = vec2:new(facing.x, facing.y)
  local cellX = math.floor(x + ray.x * 0.8)
  local cellY = math.floor(y + ray.y * 0.8)

  return map:get(cellX, cellY)
end

local function getSpeed()
  if body == nil then
    return 0
  end

  local vx, vy = body:getLinearVelocity()
  return math.sqrt(vx * vx + vy * vy)
end

return {
  create = create,
  update = update,
  setAngle = setAngle,
  move = move,
  turn = turn,
  strafe = strafe,
  getPosition = getPosition,
  getRay = getRay,
  getCellFacing = getCellFacing,
  getSpeed = getSpeed,
  getAngle = function()
    return angle
  end,
  getBody = function()
    return body
  end,
  getCamPlane = function()
    return camPlane
  end,
  getFacing = function()
    return facing
  end,
}
