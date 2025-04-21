local sounds = {
  bgLoop = love.audio.newSource("assets/sound/bg_loop.wav", "static"),
  door = love.audio.newSource("assets/sound/door.wav", "static"),
  doorOpen = love.audio.newSource("assets/sound/door_open.wav", "static"),
  doorClosed = love.audio.newSource("assets/sound/door_closed.wav", "static")
}

love.audio.setEffect("verb", {
  type = "reverb"
})

sounds.bgLoop:setLooping(true)
sounds.bgLoop:setPitch(0.6)

sounds.door:setEffect("verb")
sounds.doorClosed:setEffect("verb")
sounds.doorOpen:setEffect("verb")

return sounds
