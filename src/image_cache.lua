local function load(path)
  -- count files in the directory
  local files = love.filesystem.getDirectoryItems(path)
  print("Caching images: " .. path)
  assert(#files > 0, "No files found in directory: " .. path)

  local cache = {}

  -- loop over files and load images
  for _, file in ipairs(files) do
    local ok, image = pcall(love.graphics.newImage, path .. "/" .. file)
    if ok then
      local fileName = file:match("(.+)%..+")
      cache[fileName] = image
    end
  end

  return cache
end

return {
  load = load,
}
