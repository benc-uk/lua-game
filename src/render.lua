---@diagnostic disable: missing-fields

local magic      = require "magic"
local utils      = require "utils"
local lume       = require "lib.rxi.lume"

local pixelcode  = [[
  uniform vec2 playerPos;
  uniform vec2 playerDir;
  uniform vec2 camPlane;
  uniform sampler2D floorTex;
  uniform sampler2D ceilTex;
  uniform float heightScale;

  vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
  {
    // Calculate ray directions for the left and right edges of the screen
    float rayDirX0 = playerDir.x - camPlane.x;
    float rayDirY0 = playerDir.y - camPlane.y;
    float rayDirX1 = playerDir.x + camPlane.x;
    float rayDirY1 = playerDir.y + camPlane.y;
    float aspectRatio = love_ScreenSize.x / love_ScreenSize.y;

    // Calculate the vertical position relative to the center of the screen
    float p = love_PixelCoord.y - love_ScreenSize.y / 2.0;

    // Calculate the distance to the row being rendered
    float posZ = 0.5 * love_ScreenSize.y; // Distance from the player to the projection plane

    // Adjust the distance based on the height scale and aspect ratio
    posZ *= heightScale * aspectRatio;
    float rowDistance = posZ / abs(p);    // Use absolute value to handle both top and bottom halves

    // Interpolate the ray direction based on the horizontal screen position
    float screenPosX = love_PixelCoord.x / love_ScreenSize.x;
    float rayDirX = rayDirX0 + screenPosX * (rayDirX1 - rayDirX0);
    float rayDirY = rayDirY0 + screenPosX * (rayDirY1 - rayDirY0);

    // Calculate the world position of the floor/ceiling at this distance
    float floorX = playerPos.x + rowDistance * rayDirX;
    float floorY = playerPos.y + rowDistance * rayDirY;

    // Calculate texture coordinates
    vec2 texCoord = vec2(floorX - floor(floorX), floorY - floor(floorY));
    vec4 texColor;

    // Determine whether to draw the ceiling or the floor
    if (p < 0.0) {
      texColor = texture2D(ceilTex, texCoord);
    } else {
      texColor = texture2D(floorTex, texCoord);
    }

    // Apply distance-based shading for realism
    float brightness = clamp(1.0 / (rowDistance * rowDistance) * 0.95 + 0.05, 0.0, 1.0);
    return vec4(texColor.rgb * brightness, 1);
  }
]]

local vertexcode = [[
  vec4 position(mat4 transform_projection, vec4 vertex_position)
  {
    return transform_projection * vertex_position;
  }
]]

local tileWidth  = 32
local tileHeight = 32

-- Initialize rendering settings here
local function init(tileSetName, tileSize)
  FCShader = love.graphics.newShader(pixelcode, vertexcode)
  FloorImage = love.graphics.newImage("assets/tilesets/" .. tileSetName .. "/floor.png")
  FloorImage:setFilter("nearest", "nearest")
  FloorImage:setWrap("repeat", "repeat")
  CeilImage = love.graphics.newImage("assets/tilesets/" .. tileSetName .. "/ceil.png")
  CeilImage:setFilter("nearest", "nearest")
  CeilImage:setWrap("repeat", "repeat")

  tileHeight = tileSize
  tileWidth = tileSize
end

-- This function draws the floor and ceiling using a GLSL shader
local function floorCeil(player)
  FCShader:send("playerPos", { player.pos.x, player.pos.y })
  FCShader:send("playerDir", { player.facing.x, player.facing.y })
  FCShader:send("camPlane", { player.camPlane.x, player.camPlane.y })
  FCShader:send("heightScale", magic.heightScale)
  FCShader:send("floorTex", FloorImage)
  FCShader:send("ceilTex", CeilImage)

  love.graphics.setShader(FCShader)
  love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
  love.graphics.setShader()
end

-- This function draws the sprites in the order of their distance from the player
local function sprites(player, map, zbuffer)
  -- Order the sprites by distance to the player
  table.sort(map.sprites, function(a, b)
    return (a.pos - player.pos):length() > (b.pos - player.pos):length()
  end)

  -- Draw the sprites
  for s = 1, #map.sprites do
    local sprite = map.sprites[s]
    sprite:draw(player.pos, player.facing, player.camPlane, zbuffer)
  end
end

-- This function draws the walls using raycasting
local function walls(player, map)
  local zbuffer = {}

  -- draw walls using raycasting
  for screenX = 0, love.graphics.getWidth() do
    -- Create a ray from the player position to the screen position
    local ray = player:getRay(screenX)

    -- Cast the ray from player pos, out to find the first wall hit
    local hit = player.pos:castRay(ray, function(x, y)
      local cell = map:get(x, y)
      if cell and cell.isWall then
        return true
      end
      return false
    end)

    if hit.dist > 0 then
      math.randomseed(hit.cellX + hit.cellY)
      local wallTexture = map.tileSet.images["wall_" .. math.random(1, 3)]

      zbuffer[screenX] = hit.dist

      -- Correct the distance to the wall for the fish-eye effect
      local wallHeightDist = hit.dist * math.cos(math.atan2(ray.y, ray.x) - math.atan2(player.facing.y, player.facing.x))

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
      local wallSlice = love.graphics.newQuad(math.floor(texU * tileWidth), 0, 1,
        tileHeight, tileWidth, tileHeight)
      love.graphics.setColor(light, light, light)
      love.graphics.draw(wallTexture, wallSlice, screenX, wallY, 0, 1, wallHeight / tileHeight, 0, 0)
    end
  end

  return zbuffer
end

return {
  init = init,
  walls = walls,
  floorCeil = floorCeil,
  sprites = sprites
}
