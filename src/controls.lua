local consts   = require "consts"
local player   = require "player"

local controls = {
  up = "fwd",
  w = "fwd",
  down = "back",
  s = "back",
  left = "turnLeft",
  a = "turnLeft",
  right = "turnRight",
  d = "turnRight",
  q = "strafeLeft",
  e = "strafeRight",
  space = "action",
  ctrl = "action",
}

local inputs   = {
  fwd = false,
  back = false,
  strafeLeft = false,
  strafeRight = false,
  turnLeft = false,
  turnRight = false,
  action = false,
}

local function keyDown(keyPressed)
  for ctrlKey, inputName in pairs(controls) do
    if keyPressed == ctrlKey then
      inputs[inputName] = true
      return
    end
  end
end

local function keyUp(keyPressed)
  for ctrlKey, inputName in pairs(controls) do
    if keyPressed == ctrlKey then
      inputs[inputName] = false
      return
    end
  end
end

local function mouseMove(dx)
  player.getBody():setAngle(player.getAngle() + dx * consts.mouseSensitivity)
end

local function update(dt)
  if inputs.fwd then
    player.move(dt, 1)
  end

  if inputs.back then
    player.move(dt, -1)
  end

  if inputs.turnLeft then
    player.turn(dt, -1)
  end

  if inputs.turnRight then
    player.turn(dt, 1)
  end

  if inputs.strafeLeft then
    player.strafe(dt, 1)
  end

  if inputs.strafeRight then
    player.strafe(dt, -1)
  end

  if inputs.action then
    inputs.action = false

    local c = player.getCellFacing()

    if c ~= nil and c.door and c.state then
      if c.state.currentState.name == "closed" then
        c.state:changeState("opening")
      elseif c.state.currentState.name == "open" then
        c.state:changeState("closing")
      end
    end
  end
end

return {
  keyDown = keyDown,
  keyUp = keyUp,
  update = update,
  mouseMove = mouseMove,
}
