local sounds = {
  bgLoop = love.audio.newSource("assets/sound/bg-loop.wav", "static"),
  door = love.audio.newSource("assets/sound/door-openclose.wav", "static"),
  doorOpen = love.audio.newSource("assets/sound/door-open.wav", "static"),
  doorClosed = love.audio.newSource("assets/sound/door-closed.wav", "static")
}

love.audio.setEffect("verb", {
  type = "reverb"
})

love.audio.setEffect("delay", {
  type = "echo",
  delay = 0.2,
  tapdelay = 0.4,
  feedback = 0.03,
  damping = 0.99,
})

sounds.bgLoop:setLooping(true)
sounds.bgLoop:setPitch(0.6)

sounds.door:setEffect("verb")
sounds.doorClosed:setEffect("verb")
sounds.doorOpen:setEffect("verb")

return sounds
