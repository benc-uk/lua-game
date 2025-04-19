local IS_DEBUG = os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" and arg[2] == "debug"

if IS_DEBUG then
  print("Debugging with Lua Debugger in VSCode")

  require("lldebugger").start()

  function love.errorhandler(msg)
    error(msg, 2)
  end
end

math.randomseed(os.time())

function love.conf(conf)
  conf.window.width = 1280
  conf.window.height = 720
  conf.window.depth = 24
  conf.window.title = "Lua Dungeon"
  conf.window.icon = "assets/icons/main.png"
  conf.window.resizable = false
  conf.window.fullscreentype = "exclusive"
  conf.gammacorrect = false
  conf.window.vsync = 0

  if IS_DEBUG then
    conf.window.x = 20
    conf.window.y = 40
  end
end
