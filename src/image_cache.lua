local function load(path)
  -- count files in the directory
  local files = love.filesystem.getDirectoryItems(path)
  print("Caching images: " .. path)
  assert(#files > 0, "No files found in directory: " .. path)

  local cache = {}
  cache.images = {}

  -- loop over files and load images
  for _, file in ipairs(files) do
    local ok, image = pcall(love.graphics.newImage, path .. "/" .. file)
    if ok then
      local fileName = file:match("(.+)%..+")
      cache.images[fileName] = image
    end
  end

  -- add size field to the cache based on the first image
  local first = next(cache.images)
  if first then
    local image = cache.images[first]
    cache.size = { width = image:getWidth(), height = image:getHeight() }
  else
    cache.size = { width = 0, height = 0 }
  end

  return cache
end

return {
  load = load,
}
