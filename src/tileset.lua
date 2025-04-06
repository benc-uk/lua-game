local function load(name)
  -- count files in the directory
  local path = "assets/tilesets/" .. name .. "/"
  local files = love.filesystem.getDirectoryItems(path)
  print("Loading tileset: " .. name)
  assert(#files > 0, "No files found in tileset directory: " .. path)

  local tileset = {}
  tileset.name = name

  -- loop over files and load images
  for i, file in ipairs(files) do
    local fileName = file:match("(.+)%..+")
    if fileName then
      local imagePath = "assets/tilesets/" .. name .. "/" .. file
      local image = love.graphics.newImage(imagePath)
      if image then
        tileset[i] = image
      else
        print("Warning, failed to load image: " .. imagePath)
      end
    end
  end

  return tileset
end

return {
  load = load,
}
