---@diagnostic disable: missing-fields

local consts          = require "consts"
local utils           = require "utils"
local vec2            = require "vector"

-- Used for rendering the floor & ceiling
local floorVertShader = [[
  vec4 position(mat4 transform_projection, vec4 vertex_position)
  {
    return transform_projection * vertex_position;
  }
]]

-- Used for rendering the floor & ceiling
local floorFragShader = [[
  uniform vec2 playerPos;
  uniform vec2 playerDir;
  uniform vec2 camPlane;
  uniform sampler2D floorTex1;
  uniform sampler2D floorTex2;
  uniform sampler2D ceilTex;
  uniform float heightScale;

  float random (vec2 st) {
    // See: https://thebookofshaders.com/10/
    return fract(sin(dot(st.xy, vec2(12.9898,78.233)))*43758.5453123);
  }

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

    vec3 floorAdjust = vec3(1.0, 1.0, 1.0);
    // Determine whether to draw the ceiling or the floor
    if (p < 0.0) {
      texColor = texture2D(ceilTex, texCoord);
    } else {
      // Randomly select between two floor textures based on the position
      float r = random(floor(vec2(floorX, floorY)));
      if (r < 0.3) {
        texColor = texture2D(floorTex2, texCoord);
      } else {
        texColor = texture2D(floorTex1, texCoord);
      }

      // Adjust brightness randomly for variety
      if(mod(r * 10.0, 4.0) < 1.0) {
        floorAdjust = vec3(0.75, 0.8, 0.8);
      }
    }

    // Apply distance-based shading
    float brightness = clamp(1.5 / (rowDistance * rowDistance), 0.0, 1.5);
    return vec4(texColor.rgb * floorAdjust * brightness, 1);
  }
]]

-- Used for rendering the walls & sprites as vertical slices, hitDist used to set depth in z-buffer
local mainVertShader  = [[
  uniform highp float hitDist;
  uniform highp float maxDist;

  vec4 position(mat4 transform_projection, vec4 vertex_position)
  {
    vec4 outpos = transform_projection * vertex_position;
    outpos.z = hitDist / maxDist;
    return outpos;
  }
]]

-- Used for rendering the walls & sprites as vertical slices, hitDist used to set depth in z-buffer
local mainFragShader  = [[
  uniform highp float hitDist;
  uniform highp float maxDepth;

  vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
  {
    vec4 texColor = texture2D(tex, texture_coords);

    if (texColor.a < 0.1) { discard; }

    float brightness = clamp(2.0 / (hitDist * hitDist),0.0, 2.0);
    return vec4(texColor.rgb * brightness, texColor.a) * color;
  }
]]

local tileWidth       = 32
local tileHeight      = 32

-- Initialize rendering settings here
local function init(tileSetName, tileSize)
  love.graphics.setDefaultFilter("nearest", "nearest")

  FCShader = love.graphics.newShader(floorFragShader, floorVertShader)
  WallShader = love.graphics.newShader(mainFragShader, mainVertShader)

  WallShader:send("maxDist", consts.maxDDA)

  FloorImage1 = love.graphics.newImage("assets/tilesets/" .. tileSetName .. "/floor_1.png")
  FloorImage2 = love.graphics.newImage("assets/tilesets/" .. tileSetName .. "/floor_2.png")
  CeilImage = love.graphics.newImage("assets/tilesets/" .. tileSetName .. "/ceil.png")

  tileHeight = tileSize
  tileWidth = tileSize
end

-- This function draws the floor and ceiling using a GLSL shader
local function floorCeil(player)
  love.graphics.setDepthMode("always", false)

  local playPos = player.getPosition()
  FCShader:send("playerPos", { playPos.x, playPos.y })
  FCShader:send("playerDir", { player.getFacing().x, player.getFacing().y })
  FCShader:send("camPlane", { player.getCamPlane().x, player.getCamPlane().y })
  FCShader:send("heightScale", consts.heightScale)
  FCShader:send("floorTex1", FloorImage1)
  FCShader:send("floorTex2", FloorImage2)
  FCShader:send("ceilTex", CeilImage)

  love.graphics.setShader(FCShader)
  love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
  love.graphics.setShader()
end

-- This function draws the sprites
local function sprites(player, map)
  local playerPos = player.getPosition()

  -- Sort the sprites by distance to the player
  -- NOTE: This could be removed if it becomes slow, and we rely on the depth buffer
  -- But sorting allows for semi opaque & alpha in sprites to render correctly
  table.sort(map.sprites, function(a, b)
    return (a.pos - playerPos):length() > (b.pos - playerPos):length()
  end)

  love.graphics.setShader(WallShader)
  love.graphics.setDepthMode("lequal", false) -- would be true if removed sort

  for s = 1, #map.sprites do
    local sprite = map.sprites[s]
    sprite:draw(playerPos, player.getFacing(), player.getCamPlane(), WallShader)
  end

  love.graphics.setShader()
end

-- Cast a ray from the player position in the direction of facing
-- And update the hit list with the cells we hit
local function castRay(pos, dir, map, hitList)
  -- Current grid position
  local gridPos = { x = math.floor(pos.x), y = math.floor(pos.y) }

  -- Length of ray from current position to next x or y-side
  local sideDistX, sideDistY

  -- Length of ray from one x or y-side to next x or y-side
  local deltaDistX = math.abs(1 / dir.x)
  local deltaDistY = math.abs(1 / dir.y)
  local hitDist

  -- What direction to step in x or y direction (either +1 or -1)
  local stepX, stepY

  -- Determine step direction and initial sideDist
  if dir.x < 0 then
    stepX = -1
    sideDistX = (pos.x - gridPos.x) * deltaDistX
  else
    stepX = 1
    sideDistX = (gridPos.x + 1.0 - pos.x) * deltaDistX
  end
  if dir.y < 0 then
    stepY = -1
    sideDistY = (pos.y - gridPos.y) * deltaDistY
  else
    stepY = 1
    sideDistY = (gridPos.y + 1.0 - pos.y) * deltaDistY
  end

  -- Perform DDA
  local hit = false
  local side
  local steps = 0 -- A simple counter to limit the number of DDA loops
  local thinWallMove = 0
  local doorSide = false
  while not hit and steps < consts.maxDDA do
    -- Jump to next grid square, either in x-direction, or in y-direction
    if sideDistX < sideDistY then
      sideDistX = sideDistX + deltaDistX
      gridPos.x = gridPos.x + stepX
      side = 0
    else
      sideDistY = sideDistY + deltaDistY
      gridPos.y = gridPos.y + stepY
      side = 1
    end

    -- Check if ray has hit something
    local cell = map:get(gridPos.x, gridPos.y)
    if cell ~= nil and cell.render then
      hit = true

      -- Code for thin walls, if we hit a wall, we need to make some more checks & adjustments
      if cell ~= nil and cell.thin then
        local offsetPos = vec2:new(pos.x, pos.y)
        local shiftAmount = 0.5

        -- Next pos is checking ahead 0.5 units in the direction of the ray
        local nextPos = vec2:new()
        if side == 0 then
          nextPos.x = offsetPos.x + dir.x * (sideDistX - deltaDistX * (1 - shiftAmount))
          nextPos.y = offsetPos.y + dir.y * (sideDistX - deltaDistX * (1 - shiftAmount))
        else
          nextPos.x = offsetPos.x + dir.x * (sideDistY - deltaDistY * (1 - shiftAmount))
          nextPos.y = offsetPos.y + dir.y * (sideDistY - deltaDistY * (1 - shiftAmount))
        end

        -- This is the *next* cell we hit, we need to check if it matches the current cell
        local nextCellPos = vec2:new(math.floor(nextPos.x), math.floor(nextPos.y))

        -- If we're still in the same cell, we've hit the thin wall, so adjust the hit distance
        if nextCellPos.x == gridPos.x and nextCellPos.y == gridPos.y then
          if side == 0 then
            if dir.x > 0 then
              thinWallMove = ((gridPos.x + shiftAmount) - pos.x) / dir.x - ((gridPos.x) - pos.x) / dir.x
            else
              thinWallMove = ((gridPos.x) - pos.x) / dir.x - ((gridPos.x + shiftAmount) - pos.x) / dir.x
            end
          else
            if dir.y > 0 then
              thinWallMove = ((gridPos.y + shiftAmount) - pos.y) / dir.y - ((gridPos.y) - pos.y) / dir.y
            else
              thinWallMove = ((gridPos.y) - pos.y) / dir.y - ((gridPos.y + shiftAmount) - pos.y) / dir.y
            end
          end
        end

        -- If we're in a different cell, we hit the side of the wall next to the thin wall
        -- NOTE: Thin walls should *ALWAYS* have walls either side of them, so this should be safe
        if (nextCellPos.x ~= gridPos.x or nextCellPos.y ~= gridPos.y) then
          cell = map:get(gridPos.x, gridPos.y)
          if cell then
            doorSide = true
          end

          if side == 0 then
            side = 1
            if (dir.y > 0) then
              gridPos.y = gridPos.y + 1
            else
              gridPos.y = gridPos.y - 1
            end
          else
            side = 0
            if (dir.x > 0) then
              gridPos.x = gridPos.x + 1
            else
              gridPos.x = gridPos.x - 1
            end
          end
        end
      end
      -- END of thin wall code
    elseif cell == nil then
      -- Check for out of bounds, should not happen in a closed map
      hit = true
    end

    -- This is a simple counter to put a max distance on the ray
    steps = steps + 1
    if steps >= consts.maxDDA then
      return { worldPos = nil, side = nil, cell = nil }
    end
  end

  -- Finally, calculate distance projected on camera direction
  if side == 0 then
    hitDist = (gridPos.x - pos.x + (1 - stepX) / 2) / dir.x + thinWallMove
  else
    hitDist = (gridPos.y - pos.y + (1 - stepY) / 2) / dir.y + thinWallMove
  end

  -- World position of the hit
  local worldPos = vec2:new(pos.x + dir.x * hitDist, pos.y + dir.y * hitDist)
  local cellHitPos = vec2:new(utils.frac(worldPos.x), utils.frac(worldPos.y))
  local cell = map:get(gridPos.x, gridPos.y)

  -- Check if the cell is thin, we might need to carry on
  if cell ~= nil and cell.thin then
    hitList[#hitList + 1] = {
      worldPos = worldPos,
      side = side,
      cell = cell,
      cellHitPos = cellHitPos,
      doorSide = doorSide,
    }

    return castRay(worldPos, dir, map, hitList)
  end

  -- If we hit a wall, return the cell and the side we hit
  hitList[#hitList + 1] = {
    worldPos = worldPos,
    side = side,
    cell = cell,
    cellHitPos = cellHitPos,
    doorSide = doorSide,
  }
end

-- This function draws the walls using raycasting
local function walls(player, map)
  love.graphics.setDepthMode("lequal", true)
  love.graphics.setShader(WallShader)

  local playerPos = player.getPosition()

  -- Draw walls using raycasting
  for screenX = 0, love.graphics.getWidth() do
    -- Create a ray from the player position to the screen position
    local ray = player.getRay(screenX)

    -- Cast the ray from player pos, out to find the list of hits
    local hitList = {}
    castRay(playerPos, ray, map, hitList)

    for i = #hitList, 1, -1 do
      local hit = hitList[i]

      if hit.cell and hit.cell.render and #hit.cell.textures > 0 then
        local hitDist = hit.worldPos - playerPos
        hitDist = hitDist:length()

        -- Correct the distance to the wall for the fish-eye effect
        local wallHeightDist = hitDist *
            math.cos(math.atan2(ray.y, ray.x) - math.atan2(player.getFacing().y, player.getFacing().x))

        -- The height of the wall on the screen is inversely proportional to the distance
        local wallHeight = love.graphics.getHeight() / wallHeightDist
        -- Correct for the aspect ratio of the screen
        wallHeight = wallHeight * (love.graphics.getWidth() / love.graphics.getHeight()) * consts.heightScale
        local wallY = (love.graphics.getHeight() - wallHeight) / 2

        -- Texture mapping, get fraction of the world pos to use as the u coordinate of the texture
        local texU
        if hit.side == 0 then
          texU = hit.cellHitPos.y
        else
          texU = hit.cellHitPos.x
        end

        -- Special texture overrides for doors and animated textures
        local tex = hit.cell.textures[1]
        if hit.doorSide then
          tex = map.tileSet.images["door_sides"]
        end

        -- Handle animated textures
        if #hit.cell.textures > 1 and hit.cell.animateSpeed > 0 then
          -- loop through the textures using timer
          local texIndex = math.floor(love.timer.getTime() * hit.cell.animateSpeed * #hit.cell.textures) %
              #hit.cell.textures + 1
          tex = hit.cell.textures[texIndex]
        end

        if hit.cell.state then
          -- If the cell has a fsm, use the current texture
          tex = hit.cell.state:getStateData().currentTexture
        end

        -- Call the shader to draw the wall slice (1 px wide) at the correct position & distance
        WallShader:send("hitDist", hitDist)
        local wallStrip = love.graphics.newQuad(texU * tileWidth, 0, 1, tileHeight, tileWidth, tileHeight)
        love.graphics.draw(tex, wallStrip, screenX, wallY, 0, 1, wallHeight / tileHeight, 0, 0)
      end
    end
  end
end

return {
  init = init,
  walls = walls,
  floorCeil = floorCeil,
  sprites = sprites
}
