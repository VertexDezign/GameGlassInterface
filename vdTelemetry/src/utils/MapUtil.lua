MapUtil = {}

---@class PDA
---@field filename string
---@field width number the *world* width in meters (map.xml's `map#width`), not the image's pixel width
---@field height number the *world* height in meters; same caveat as `width`

---@return PDA | nil The filename to the pda or nil if not found.
function MapUtil.getMapPDAFile()
  for _, item in pairs(g_mapManager.maps) do
    if item.id == g_currentMission.missionInfo.map.id then
      local mapXMLFilename = item.mapXMLFilename

      if mapXMLFilename:find("$data") then
        mapXMLFilename = getAppBasePath() .. mapXMLFilename:sub(2)
      else
        mapXMLFilename = item.baseDirectory .. mapXMLFilename
      end

      local mapXML = XMLFile.loadIfExists("map", mapXMLFilename)

      local pdaMapFile = mapXML:getString("map#imageFilename")
      -- The engine documents these as the width/height of the *world*, and the overview image is not
      -- the world: the game paints the terrain into the middle half of each axis and fills the rest
      -- with the map's title art (IngameMap's mapExtension* constants). On a stock 2048 m map the
      -- number happens to match half of a 4096 px image, which is why it reads like a pixel size --
      -- it is not one, and the terminal crops the image by proportion instead.
      local width = mapXML:getInt("map#width")
      local height = mapXML:getInt("map#height")

      if pdaMapFile:find("$data") then
        pdaMapFile = getAppBasePath() .. pdaMapFile:sub(2)
      else
        pdaMapFile = item.baseDirectory .. pdaMapFile
      end

      if pdaMapFile:find(".png") then
        pdaMapFile = pdaMapFile:sub(0, pdaMapFile:len() - 4) .. ".dds"
      end
      return {
        filename = pdaMapFile,
        width = width,
        height = height,
      }
    end
  end

  return nil
end
