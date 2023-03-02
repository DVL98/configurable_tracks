local collection = require "ctracks/collection"

local script = {
  modParams = {},
}

local state = {
  use = false,
  tunnelType = "normal",
  speedLimit = 120,
  ptracks_use = false,
  fn = {},
  newSegments = {}
}

local translations = {
    USE_CONFIGURABLE_TRACKS = "Use configurable tracks",
    TUNNEL_TYPE = "Tunnel walls",
    NORMAL = "Normal",
    TRANSPARENT = "Transparent",
    CONCRETE = "Concrete",
    SPEEDLIMIT = "Speedlimit",
    NO = "No",
    YES = "Yes"
}

local firstToUpper = function(str)
    return (str:gsub("^%l", string.upper))
end

local createWindow = function()
  if not api.gui.util.getById("ctracks.use") then
    debugPrint(script.modParams)
    local menu = api.gui.util.getById("menu.construction.rail.settings")
    local menuLayout = menu:getLayout()
    
    local useComp = api.gui.comp.Component.new("ParamsListComp::ButtonParam")
    local useLayout = api.gui.layout.BoxLayout.new("VERTICAL")
    useComp:setLayout(useLayout)
    useComp:setId("ctracks.use")
    
    local use = api.gui.comp.TextView.new(translations.USE_CONFIGURABLE_TRACKS)
    
    local useButtonComp = api.gui.comp.ToggleButtonGroup.new(0, 0, false)
    local useNo = api.gui.comp.ToggleButton.new(api.gui.comp.TextView.new(translations.NO))
    local useYes = api.gui.comp.ToggleButton.new(api.gui.comp.TextView.new(translations.YES))
    useButtonComp:setName("ToggleButtonGroup")
    useButtonComp:add(useNo)
    useButtonComp:add(useYes)
    useButtonComp:setOneButtonMustAlwaysBeSelected(true)

    useLayout:addItem(use)
    useLayout:addItem(useButtonComp)
    
    local tunnelTypeComp = api.gui.comp.Component.new("ParamsListComp::ListParam")
    local tunnelTypeLayout = api.gui.layout.BoxLayout.new("HORIZONTAL")
    tunnelTypeComp:setLayout(tunnelTypeLayout)
    tunnelTypeComp:setId("ctracks.tunnelType")

    local tunnelType = api.gui.comp.TextView.new(translations.TUNNEL_TYPE)
    
    local tunnelTypeBox = api.gui.comp.ComboBox.new()
    tunnelTypeBox:addItem(translations.NORMAL)

    local tunnelTypeListItems = { "normal" }
    for tunnelType, __ in pairs(collection.tunnelTypes) do
      tunnelTypeBox:addItem(firstToUpper(tunnelType))
      local index = tunnelTypeBox:getNumItems()

      if (state.tunnelType == tunnelType) then
        tunnelTypeBox:setSelected(index - 1, false)
      end

      tunnelTypeListItems[index] = tunnelType
    end
  
    tunnelTypeLayout:addItem(tunnelType)
    tunnelTypeLayout:addItem(tunnelTypeBox)
    
    local speedLimitComp = api.gui.comp.Component.new("ParamsListComp::SliderParam")
    local speedLimitLayout = api.gui.layout.BoxLayout.new("VERTICAL")
    speedLimitComp:setLayout(speedLimitLayout)
    speedLimitComp:setId("ctracks.speedlimit")
    speedLimitLayout:setName("ParamsListComp::SliderParam::Layout")
    
    local speedLimitText = api.gui.comp.TextView.new(translations.SPEEDLIMIT)
    local speedLimitValue = api.gui.comp.TextView.new(tostring(state.speedLimit))
    local speedLimitSlider = api.gui.comp.Slider.new(true)
    local speedLimitSliderLayout = api.gui.layout.BoxLayout.new("HORIZONTAL")
    
    speedLimitValue:setName("ParamsListComp::SliderParam::SliderLabel")

    local minSpeed = tonumber(collection.minSpeed[script.modParams.minSpeed + 1])
    local maxSpeed = tonumber(collection.maxSpeed[script.modParams.maxSpeed + 1])
    
    speedLimitSlider:setStep(1)
    speedLimitSlider:setMinimum(minSpeed / 20)
    speedLimitSlider:setMaximum(maxSpeed / 20)
    speedLimitSlider:setValue(state.speedLimit / 20, false)
    speedLimitSlider:setName("Slider")
    
    speedLimitSliderLayout:addItem(speedLimitSlider)
    speedLimitSliderLayout:addItem(speedLimitValue)
    speedLimitLayout:addItem(speedLimitText)
    speedLimitLayout:addItem(speedLimitSliderLayout)
    
    menuLayout:addItem(useComp)
    menuLayout:addItem(tunnelTypeComp)
    menuLayout:addItem(speedLimitComp)
    
    speedLimitSlider:onValueChanged(function(value)
      table.insert(state.fn, function()
        speedLimitValue:setText(tostring(value * 20))
        game.interface.sendScriptEvent("__ctracks__", "speedLimit", {speedLimit = value * 20})
      end)
    end)

    tunnelTypeBox:onIndexChanged(function(index)
      local tunnelType = tunnelTypeListItems[index + 1]

      table.insert(state.fn, function()
        game.interface.sendScriptEvent("__ctracks__", "tunnelType", {tunnelType = tunnelType})
      end)
    end)
    
    useNo:onToggle(function()
      table.insert(state.fn, function()
        game.interface.sendScriptEvent("__ctracks__", "use", {use = false})
        game.interface.sendScriptEvent("__ptracks__", "agent", {agent = false})

        tunnelTypeComp:setVisible(false, false)
        speedLimitComp:setVisible(false, false)
      end)
    end)
    
    useYes:onToggle(function()
      table.insert(state.fn, function()
        game.interface.sendScriptEvent("__ctracks__", "use", {use = true})
        game.interface.sendScriptEvent("__ptracks__", "agent", {agent = true})

        tunnelTypeComp:setVisible(true, false)
        speedLimitComp:setVisible(true, false)
      end)
    end)
    
    if state.use then useYes:setSelected(true, true) else useNo:setSelected(true, true) end
    
    if state.tunnelType == "normal" then tunnelTypeBox:setSelected(0, false) end
  end
end

local replaceTrack = function(newSegments)
	local proposal = api.type.SimpleProposal.new()
 
	local trackEdge = api.engine.getComponent(newSegments[1], api.type.ComponentType.BASE_EDGE_TRACK)
  local variant = state.tunnelType ~= "normal" and state.tunnelType .. "_" or ""
  local trackFileName = "ctracks_" .. state.speedLimit .. "_" .. variant .. api.res.trackTypeRep.getName(trackEdge.trackType)
  local trackType = api.res.trackTypeRep.find(trackFileName)

  local segmentOrder = {}

  for n, segment in ipairs(newSegments) do
    local baseEdge = api.engine.getComponent(segment, api.type.ComponentType.BASE_EDGE)
    local entity = api.type.SegmentAndEntity.new()
    
    entity.entity = -n
    entity.playerOwned = {player = api.engine.util.getPlayer()}
    entity.type = 1

    entity.comp.type = baseEdge.type
    entity.comp.typeIndex = baseEdge.typeIndex

    entity.comp.node0 = baseEdge.node0
    entity.comp.node1 = baseEdge.node1
    entity.comp.tangent0 = baseEdge.tangent0
    entity.comp.tangent1 = baseEdge.tangent1

    entity.trackEdge = trackEdge
    entity.trackEdge.trackType = trackType
    entity.trackEdge.catenary = trackEdge.catenary

    proposal.streetProposal.edgesToRemove[n] = segment
    proposal.streetProposal.edgesToAdd[n] = entity

    segmentOrder[n] = { node0 = baseEdge.node0, node1 = baseEdge.node1}
  end

	local build = api.cmd.make.buildProposal(proposal, nil, true)

	api.cmd.sendCommand(build, function(x, success)
    if (success and state.ptracks_use) then
      local filteredNewSegments = {}
      
      for entityId, segment in pairs(x.resultProposalData.entity2tn) do
        if #segment.edges > 0 then
          for index, value in pairs(segmentOrder) do
            if segment.edges[1].conns[1].entity == value.node0 then
              filteredNewSegments[index] = entityId
            end
          end
        end
      end

      state.newSegments = filteredNewSegments
    end
  end)
end

script.handleEvent = function(src, id, name, param)
  if (id == "__ctracks__") then
    if (name == "replace") then
      replaceTrack(param.newSegments)
    elseif (name == "use") then
      state.use = param.use
    elseif (name == "tunnelType") then
      state.tunnelType = param.tunnelType
    elseif (name == "speedLimit") then
      state.speedLimit = param.speedLimit
    end
  elseif (id == "__ptracks__" and name == "use") then
    state.ptracks_use = param.use
  end
end

script.save = function()
  return state
end

script.load = function(data)
  if data then
    state.use = data.use or false
    state.tunnelType = data.tunnelType or "normal"
    state.speedLimit = data.speedLimit or 120
  end
end

script.update = function()
  if (#state.newSegments > 0) then
    local buildParallel = api.cmd.make.sendScriptEvent("ctracks.lua", "__ptracks__", "build", {newSegments = state.newSegments})
    api.cmd.sendCommand(buildParallel, function(x) end)
    state.newSegments = {}
  end
end

script.guiUpdate = function()
  for _, fn in ipairs(state.fn) do fn() end
  state.fn = {}
end

script.guiHandleEvent = function(source, name, param)
  if source == "trackBuilder" then
    createWindow()

    if name == "builder.apply" then
      local proposal = param.proposal.proposal
      local toRemove = param.proposal.toRemove
      local toAdd = param.proposal.toAdd
      
      if state.use
        and (not toAdd or #toAdd == 0)
        and (not toRemove or #toRemove == 0)
        and proposal.addedSegments
        and proposal.new2oldSegments
        and proposal.removedSegments
        and #proposal.addedSegments > 0
        and #proposal.new2oldSegments == 0
        and #proposal.removedSegments == 0
      then
        local newSegments = {}
        for i = 1, #proposal.addedSegments do
          local seg = proposal.addedSegments[i]
          if seg.type == 1 then
            table.insert(newSegments, seg.entity)
          end
        end
        
        if #newSegments > 0 then
          game.interface.sendScriptEvent("__ctracks__", "replace", {newSegments = newSegments})
        end
      end
    end
  end
end


function data()
  return script
end