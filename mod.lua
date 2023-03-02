local collection = require "ctracks/collection"

function data()
return {
  info = {
    minorVersion = 0,
    severityAdd = "NONE",
    severityRemove = "NONE",
    name = "Configurable Tracks",
    description = "Adds the ability to configure the tracks before building. Options include tunnel type and speedlimit. Compatible with Auto Parallel Tracks",
	  tags = {"Track", "Script Mod"},
	  visible = true,
    params = {
      {
        key = "minSpeed",
        name = "Minimum track speed",
        uiType = "SLIDER",
        values = collection.minSpeed,
        defaultIndex = 0,
        tooltip = "Choose the minimum speed of the configurable tracks",
      },
      {
        key = "maxSpeed",
        name = "Maximum track speed",
        uiType = "SLIDER",
        values = collection.maxSpeed,
        defaultIndex = 0,
        tooltip = "Choose the maximum speed of the configurable tracks",
      },
    },
    authors = {
      {
		    name = "DVL",
		    role = "CREATOR",	
      },
    },    
  },
  runFn = function (settings, params)
    local modParams = params[getCurrentModId()]

    local function paramSetter(fileName, data)
      if fileName == "res/config/game_script/configurable_tracks.lua" then
        data.modParams = modParams
      end
    
      return data
    end
    
    addModifier("loadGameScript", paramSetter)
  end,
  postRunFn = function (settings, params)
    local modParams = params[getCurrentModId()]

    local minSpeed = tonumber(collection.minSpeed[modParams.minSpeed])
    local maxSpeed = tonumber(collection.maxSpeed[modParams.maxSpeed])

    local tracks = api.res.trackTypeRep.getAll()

    for __, trackName in pairs(tracks) do
      local track = api.res.trackTypeRep.get(api.res.trackTypeRep.find(trackName))
      
      local original = {
        speedLimit = track.speedLimit,
        cost = track.cost,
        tunnelWallMaterial = track.tunnelWallMaterial,
        tunnelHullMaterial = track.tunnelHullMaterial
      }

      for speedLimit = 20, 400, 20 do
        local prefix = "ctracks_" .. speedLimit .. "_"

        track.speedLimit = speedLimit / 3.6
        track.cost = original.cost * (speedLimit / (original.speedLimit * 3.6))

        api.res.trackTypeRep.add(prefix .. tostring(trackName), track, false)

        for tunnelType, config in pairs(collection.tunnelTypes) do
          track.tunnelWallMaterial = config.tunnelWallMaterial
          track.tunnelHullMaterial = config.tunnelHullMaterial
          api.res.trackTypeRep.add(prefix .. tunnelType .."_" .. tostring(trackName), track, false)
        end

        track.tunnelWallMaterial = original.tunnelWallMaterial
        track.tunnelHullMaterial = original.tunnelHullMaterial
      end

      -- Reset changed values to original values, otherwise base tracks are influenced
      track.speedLimit = original.speedLimit
      track.cost = original.cost
    end
  end,
}
end