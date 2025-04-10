local imageCache = {}

function imageCache:load(path)
  local ic = {}

  -- count files in the directory
  local files = love.filesystem.getDirectoryItems(path)
  print("Caching images: " .. path)
  assert(#files > 0, "No files found in directory: " .. path)

  ic.filterMode = "nearest"
  ic.images = {}

  -- loop over files and load images
  for _, file in ipairs(files) do
    local ok, image = pcall(love.graphics.newImage, path .. "/" .. file)
    if ok then
      image:setWrap("repeat", "clampzero")
      image:setFilter("nearest", "nearest")
      local fileName = file:match("(.+)%..+")
      ic.images[fileName] = image
    end
  end

  -- add size field to the cache based on the first image
  -- NOTE: We assume all images are the same size, e.g. a tileset
  local first = next(ic.images)
  if first then
    local image = ic.images[first]
    ic.size = { width = image:getWidth(), height = image:getHeight() }
  else
    ic.size = { width = 0, height = 0 }
  end

  setmetatable(ic, self)
  self.__index = self

  return ic
end

function imageCache:setFilter(mode)
  self.filterMode = mode

  for _, image in pairs(self.images) do
    image:setFilter(mode, mode)
  end
end

return imageCache
