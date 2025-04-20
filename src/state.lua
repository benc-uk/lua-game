-- A generic finite state machine implementation

local StateMachine = {}
StateMachine.__index = StateMachine

-- Create a new state machine instance
function StateMachine.new()
  local self = setmetatable({}, StateMachine)

  self.states = {}         -- Table of all defined states
  self.currentState = nil  -- Current active state
  self.previousState = nil -- Previous state (for returning)
  self.stateData = {}      -- Persistent data for each state

  return self
end

-- Register a new state with callbacks
-- @param name: String identifier for the state
-- @param callbacks: Table with onEnter, onExit, onUpdate, onDraw, onEvent functions
function StateMachine:addState(name, callbacks)
  self.states[name] = {
    name = name,
    onEnter = callbacks.onEnter or function() end,
    onExit = callbacks.onExit or function() end,
    onUpdate = callbacks.onUpdate or function() end,
    onDraw = callbacks.onDraw or function() end,
    onEvent = callbacks.onEvent or function() return false end
  }

  -- Initialize state data if not exists
  if not self.stateData[name] then
    self.stateData[name] = {}
  end

  return self
end

-- Change to a different state
-- @param stateName: Name of the state to change to
-- @param ...: Additional parameters to pass to onExit/onEnter
function StateMachine:changeState(stateName, ...)
  local newState = self.states[stateName]

  if not newState then
    error("StateMachine: State '" .. tostring(stateName) .. "' does not exist")
    return self
  end

  if self.currentState then
    self.currentState.onExit(self, self.stateData[self.currentState.name], ...)
    self.previousState = self.currentState
  end

  self.currentState = newState
  self.currentState.onEnter(self, self.stateData[stateName], ...)

  return self
end

-- Return to the previous state
-- @param ...: Additional parameters to pass to onExit/onEnter
function StateMachine:goBack(...)
  if self.previousState then
    return self:changeState(self.previousState.name, ...)
  end
  return self
end

-- Update the current state
-- @param dt: Delta time
-- @param ...: Additional parameters to pass to onUpdate
function StateMachine:update(dt, ...)
  if self.currentState then
    self.currentState.onUpdate(self, self.stateData[self.currentState.name], dt, ...)
  end
  return self
end

-- Draw the current state
-- @param ...: Additional parameters to pass to onDraw
function StateMachine:draw(...)
  if self.currentState then
    self.currentState.onDraw(self, self.stateData[self.currentState.name], ...)
  end
  return self
end

-- Send an event to the current state
-- @param eventName: Name of the event
-- @param ...: Additional parameters for the event
-- @return: Boolean value indicating if event was handled
function StateMachine:handleEvent(eventName, ...)
  if self.currentState and self.currentState.onEvent then
    return self.currentState.onEvent(self, self.stateData[self.currentState.name], eventName, ...)
  end
  return false
end

-- Get the current state name
-- @return: String name of the current state or nil
function StateMachine:getState()
  return self.currentState and self.currentState.name
end

-- Check if in a specific state
-- @param stateName: Name of state to check
-- @return: Boolean indicating if machine is in the specified state
function StateMachine:isInState(stateName)
  return self.currentState and self.currentState.name == stateName
end

-- Get data for a specific state
-- @param stateName: Optional name of state (defaults to current state)
-- @return: Table containing state data
function StateMachine:getStateData(stateName)
  stateName = stateName or (self.currentState and self.currentState.name)
  return stateName and self.stateData[stateName]
end

return StateMachine
