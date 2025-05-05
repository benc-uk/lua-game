local conf = require "conf"

local footsteps = {}
footsteps[1] = love.audio.newSource("assets/sound/foot_1.wav", "static")
footsteps[2] = love.audio.newSource("assets/sound/foot_2.wav", "static")
footsteps[3] = love.audio.newSource("assets/sound/foot_3.wav", "static")

-- set all footstep sounds to use the same effect
for _, foot in ipairs(footsteps) do
  foot:setEffect("verb")
  foot:setVolume(0.1)
end

local lastFootPlayed = 0

local sounds = {
  bgLoop = love.audio.newSource("assets/sound/bg_loop.wav", "static"),
  door = love.audio.newSource("assets/sound/door.wav", "static"),
  doorOpen = love.audio.newSource("assets/sound/door_open.wav", "static"),
  doorClosed = love.audio.newSource("assets/sound/door_closed.wav", "static"),

  playFoot = function()
    local currentTime = love.timer.getTime()
    if currentTime - lastFootPlayed < 0.45 then
      return
    end

    local foot = footsteps[math.random(1, #footsteps)]
    foot:stop()
    foot:play()

    lastFootPlayed = currentTime
  end,
}

love.audio.setEffect("verb", {
  type = "reverb"
})

love.audio.setVolume(conf.settings.SOUND_VOLUME)

sounds.bgLoop:setLooping(true)
sounds.bgLoop:setPitch(0.6)

sounds.door:setEffect("verb")
sounds.doorClosed:setEffect("verb")
sounds.doorOpen:setEffect("verb")

return sounds
