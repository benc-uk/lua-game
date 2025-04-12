local map    = require "map"
local player = require "player"
local utils  = require "utils"
local lume   = require "lib.rxi.lume"
local magic  = require "magic"

function love.load()
  --local spriteCache = imageCache:load("assets/sprites")

  Map = map:load("level-1")

  Player = player:new(Map.playerStartCell[1] + 0.5, Map.playerStartCell[2] + 0.5)
  Player:rotate(Map.playerStartDir * 90)

  FloorImageData = love.image.newImageData("assets/tilesets/dungeon/floor_1.png")
  CeilImageData = love.image.newImageData("assets/tilesets/dungeon/ceil_1.png")
  -- extract the floor texture from the image data as a 32x32 array of rgb values
  FloorRawData = {}
  for y = 0, FloorImageData:getHeight() - 1 do
    FloorRawData[y] = {}
    for x = 0, FloorImageData:getWidth() - 1 do
      local r, g, b, a = FloorImageData:getPixel(x, y)
      FloorRawData[y][x] = { r, g, b, a }
    end
  end

  -- extract the ceil texture from the image data as a 32x32 array of rgb values
  CeilRawData = {}
  for y = 0, CeilImageData:getHeight() - 1 do
    CeilRawData[y] = {}
    for x = 0, CeilImageData:getWidth() - 1 do
      local r, g, b, a = CeilImageData:getPixel(x, y)
      CeilRawData[y][x] = { r, g, b, a }
    end
  end

  BGImageData = love.image.newImageData(love.graphics.getWidth(), love.graphics.getHeight())
end

function love.update()
  if love.keyboard.isDown("left") or love.keyboard.isDown("a") then
    Player:rotate(-2)
  elseif love.keyboard.isDown("right") or love.keyboard.isDown("d") then
    Player:rotate(2)
  end

  local movingKey = false
  if love.keyboard.isDown("up") or love.keyboard.isDown("w") then
    Player:accel()
    movingKey = true
  elseif love.keyboard.isDown("down") or love.keyboard.isDown("s") then
    Player:decel()
    movingKey = true
  end

  if not movingKey then
    Player:comeToStop()
  end

  Player:move(love.timer.getDelta())

  -- check inside a wall
  if Map:get(Player.pos.x, Player.pos.y).isWall then
    -- Move back to the last position
    Player.pos = Player.pos - Player.facing * Player.speed * love.timer.getDelta()
    Player.speed = 0
  end
end

function love.mousepressed(x, y, button)
  if button == 1 then
    if love.mouse.isGrabbed() then
      love.mouse.setGrabbed(false)
      love.mouse.setVisible(true)
      return
    end

    love.mouse.setGrabbed(true)
    love.mouse.setVisible(false)
  end
end

function love.mousemoved(x, y, dx, dy, istouch)
  if love.mouse.isGrabbed() then
    -- Calculate the angle to turn based on mouse movement
    local sensitivity = 0.1
    local centerXDiff = love.graphics.getWidth() / 2 - x
    local angle = -centerXDiff * sensitivity

    -- Rotate the player based on mouse movement
    Player:rotate(angle)

    -- Reset mouse position to the center of the window
    local centerX = love.graphics.getWidth() / 2
    local centerY = love.graphics.getHeight() / 2
    love.mouse.setPosition(centerX, centerY)
  end
end

function love.draw()
  love.graphics.setColor(1, 1, 1)
  love.graphics.clear()

  local tileWidth = Map.tileSet.size.width
  local tileHeight = Map.tileSet.size.height

  -- draw the floor using Y based raycasting, scan the screen from top to bottom
  for y = 0, love.graphics.getHeight() - 1 do
    -- rayDir for leftmost ray (x = 0) and rightmost ray (x = w)
    local rayDirX0 = Player.facing.x - Player.camPlane.x
    local rayDirY0 = Player.facing.y - Player.camPlane.y
    local rayDirX1 = Player.facing.x + Player.camPlane.x
    local rayDirY1 = Player.facing.y + Player.camPlane.y

    -- Current y position compared to the center of the screen (the horizon)
    local p = y - love.graphics.getHeight() / 2

    -- Vertical position of the camera
    local posZ = 0.5 * love.graphics.getHeight()

    -- Horizontal distance from the camera to the floor for the current row
    local rowDistance = posZ / p
    local light = lume.clamp(1 / (rowDistance * rowDistance), 0, 1)
    light = light * 0.93 + 0.03 -- make it brighter

    local floorStepX = rowDistance * (rayDirX1 - rayDirX0) / love.graphics.getWidth()
    local floorStepY = rowDistance * (rayDirY1 - rayDirY0) / love.graphics.getWidth()

    local floorX = Player.pos.x + rowDistance * rayDirX0
    local floorY = Player.pos.y + rowDistance * rayDirY0

    for x = 0, love.graphics.getWidth() - 1 do
      -- Get the texture coordinates for the floor texture
      local tx = tileWidth * utils.frac(floorX)
      local ty = tileHeight * utils.frac(floorY)

      floorX = floorX + floorStepX
      floorY = floorY + floorStepY

      if tx > 0 and tx < tileWidth and ty > 0 and ty < tileHeight then
        local pixF = FloorRawData[math.floor(ty)][math.floor(tx)]
        local pixC = CeilRawData[math.floor(ty)][math.floor(tx)]
        BGImageData:setPixel(x, y, pixF[1] * light, pixF[2] * light, pixF[3] * light, 1)
        BGImageData:setPixel(x, love.graphics.getHeight() - y - 1, pixC[1] * light, pixC[2] * light, pixC[3] * light, 1)
      end
    end
  end

  -- draw the floor texture
  BGImage = love.graphics.newImage(BGImageData)
  love.graphics.draw(BGImage, 0, 0, 0)

  local zbuffer = {}
  -- draw walls using raycasting
  for screenX = 0, love.graphics.getWidth() do
    -- Create a ray from the player position to the screen position
    local ray = Player:getRay(screenX)

    -- Cast the ray from player pos, out to find the first wall hit
    local hit = Player.pos:castRay(ray, function(x, y)
      local cell = Map:get(x, y)
      if cell and cell.isWall then
        return true
      end
      return false
    end)

    if hit.dist > 0 then
      math.randomseed(hit.mapX + hit.mapY)
      local wallTexture = Map.tileSet.images["wall_" .. math.random(1, 3)]

      zbuffer[screenX] = hit.dist

      -- Correct the distance to the wall for the fish-eye effect
      local wallHeightDist = hit.dist * math.cos(math.atan2(ray.y, ray.x) - math.atan2(Player.facing.y, Player.facing.x))

      -- The height of the wall on the screen is inversely proportional to the distance
      local wallHeight = love.graphics.getHeight() / wallHeightDist
      -- Correct for the aspect ratio of the screen
      wallHeight = wallHeight * (love.graphics.getWidth() / love.graphics.getHeight()) * magic.heightScale

      local wallY = (love.graphics.getHeight() - wallHeight) / 2

      -- light falls off with distance inverse square law and should be clamped to 0 - 1
      local light = lume.clamp(1 / (hit.dist * hit.dist), 0, 1)
      light = light * 0.93 + 0.03 -- make it brighter

      -- texture mapping, get fraction of the world pos to use as the u coordinate of the texture
      local texU
      if hit.side == 0 then
        texU = utils.frac(hit.worldPos.y) -- vertical wall
      else
        texU = utils.frac(hit.worldPos.x) -- horizontal wall
      end

      -- One pixel vertical slice of the texture
      local wallSlice = love.graphics.newQuad(texU * tileWidth, 0, 1,
        tileHeight, tileWidth, tileHeight)
      love.graphics.setColor(light, light, light)
      love.graphics.draw(wallTexture, wallSlice, screenX, wallY, 0, 1, wallHeight / tileHeight, 0, 0)
    end
  end

  -- Show the FPS
  love.graphics.setFont(love.graphics.newFont(22))
  love.graphics.setColor(0, 0, 0)
  love.graphics.print("FPS: " .. love.timer.getFPS(), love.graphics.getWidth() - 90, 5)
  love.graphics.setColor(1, 1, 1)
  love.graphics.print("FPS: " .. love.timer.getFPS(), love.graphics.getWidth() - 92, 3)

  -- Order the sprites by distance to the player
  table.sort(Map.sprites, function(a, b)
    return (a.pos - Player.pos):length() > (b.pos - Player.pos):length()
  end)

  -- Draw the sprites
  for s = 1, #Map.sprites do
    local sprite = Map.sprites[s]
    sprite:draw(Player.pos, Player.facing, Player.camPlane, zbuffer)
  end
end

function love.keypressed(key)
  if key == "escape" then
    love.event.quit()
  end

  if key == "f" then
    if Map.tileSet.filterMode == "nearest" then
      Map.tileSet:setFilter("linear")
    else
      Map.tileSet:setFilter("nearest")
    end
  end
end

-- local function overlay()
-- love.graphics.setColor(0, 1, 0)
-- love.graphics.setLineWidth(1)
-- love.graphics.line(love.graphics.getWidth() / 2, 0, love.graphics.getWidth() / 2, love.graphics.getHeight())
-- love.graphics.line(0, love.graphics.getHeight() / 2, love.graphics.getWidth(), love.graphics.getHeight() / 2)

--   local image = Map.tiles["wall_1"]
--   local tileWidth = image:getWidth()
--   local tileHeight = image:getHeight()

--   -- Draw the map
--   love.graphics.scale(0.75, 0.75)
--   love.graphics.setColor(1, 1, 1, 0.6)

--   for i = 1, Map.height do
--     for j = 1, Map.width do
--       local cell = Map[i][j]
--       if cell.isWall then
--         local x = i * tileWidth
--         local y = j * tileHeight
--         love.graphics.draw(image, x, y)
--       end
--     end
--   end

--   -- Draw red circle at player position
--   love.graphics.setColor(1, 0, 0)
--   love.graphics.circle("fill", Player.pos.x * tileWidth, Player.pos.y * tileHeight, 5)

--   -- Draw a line in the direction the player is facing
--   love.graphics.setColor(0, 1, 0)
--   love.graphics.setLineWidth(2)
--   love.graphics.line(
--     Player.pos.x * tileWidth,
--     Player.pos.y * tileHeight,
--     (Player.pos.x + Player.facing.x) * tileWidth,
--     (Player.pos.y + Player.facing.y) * tileHeight
--   )
--   love.graphics.scale(1.3333, 1.3333)
-- end
