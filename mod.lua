local tunnelTypes = require "ctracks/tunnel_types"

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
    authors = {
      {
		    name = "DVL",
		    role = "CREATOR",	
      },
    },    
  },
  postRunFn = function (settings, params)
    local tracks = api.res.trackTypeRep.getAll()

    for __, trackName in pairs(tracks) do
      local track = api.res.trackTypeRep.get(api.res.trackTypeRep.find(trackName))
      
      local original = {
        speedLimit = track.speedLimit,
        cost = track.cost,
        tunnelWallMaterial = "track/tunnel_rail_ug.mtl",
        tunnelHullMaterial = "track/tunnel_hull.mtl"
      }

      for speedLimit = 20, 360, 20 do
        local prefix = "ctracks_" .. speedLimit .. "_"

        track.speedLimit = speedLimit / 3.6
        track.cost = original.cost * (speedLimit / (original.speedLimit * 3.6))

        api.res.trackTypeRep.add(prefix .. tostring(trackName), track, false)

        for tunnelType, config in pairs(tunnelTypes) do
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