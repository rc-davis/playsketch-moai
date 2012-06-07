--[[
	--------------
	Copyright 2012 Singapore Management University
	 
	This Source Code Form is subject to the terms of the
	Mozilla Public License, v. 2.0. If a copy of the MPL was
	not distributed with this file, You can obtain one at
	http://mozilla.org/MPL/2.0/.
	--------------
--]]

--[[

	interactormodel/IM1-interactormodel.lua
	
	IM1 is for testing/experimenting purposes and evaluating the interface with the base model.
	This should perform ALL of the interactions with the base model.
	See: https://github.com/richardcd73/playsketch2/wiki/Interactor-Model-1-Spec
	
	
--]]

require "basemodel/basemodel"

interactormodel = {}

local currentPath = nil
local userPaths = {} -- paths that correspond to the user's creations



------------------ INTERACTOR MODEL API ----------------------

function interactormodel.newDrawableCreated(prop, time, location)
	basemodel.addNewDrawable(prop, time, location)
end

function interactormodel.selectableDrawables(time)
	assert(time == controllers.timeline.currentTime(),
		"assuming that we are only trying to select drawables at the current time for"..
		"efficiency. This can be updated if this assumption stops being true")
	local selectable = {}
	for _,o in pairs(basemodel.allDrawables()) do
		if o:visibleAtCurrentTime() then table.insert(selectable, o) end
	end
	return selectable
end

function interactormodel.selectionMade(set)

	-- Update the user interface to this state!
	g_addPathButton:setEnabled(true)
end


function interactormodel.selectionStarted()
	g_addPathButton:setEnabled(false)
	widgets.manipulator:hide()
end


function interactormodel.selectionCleared()
	currentPath = nil
	g_addPathButton:setEnabled(false)
	g_pathList:setSelected(nil)
	widgets.manipulator:hide()
	widgets.keyframes:setCurrentPath(nil)
	widgets.modifierButton:setState(widgets.modifierButton.states.SELECT_UP)			
	input.strokecapture.setMode(input.strokecapture.modes.MODE_DRAW)
end


function interactormodel.recordingStarts(time)
	print("STARTING RECORDING")
end


function interactormodel.recordingUpdate(data)
end

function interactormodel.recordingFinished(time)
end

function interactormodel.updateKeyframe(data)
	assert(currentPath, "can't update keyframe without a current Path")
	local s,r,t,v = currentPath:stateAtTime(data.time)
	if data.dScale then s = s + data.dScale else s = nil end
	if data.dAngle then r = r + data.dAngle else r = nil end
	if data.dx and data.dy then t.x,t.y = t.x + data.dx, t.y + data.dy else t = nil end
	currentPath:addKeyframedMotion(data.time, s, r, t, nil, nil)
end

function interactormodel.updateVisibility(time, newValue)
end

------------------ /INTERACTOR MODEL API ----------------------


------------------ HELPERS FOR THIS SPECIFIC INTERFACE --------
function interactormodel.makeNewUserPath()

	 -- arbitrarily limit us to 10 paths to fit in the UI
	if #interactormodel.getUserPaths() >= 10 then return end

	local drawableArray = util.dictionaryValuesToArray(controllers.selection.selectedSet)
	local path = basemodel.createNewPath(drawableArray, nil, true)
	table.insert(userPaths, path)
	
	local label =	"Path " .. #interactormodel.getUserPaths() ..
					" (" .. util.tableCount(path:allDrawables()) .. ")"
	g_pathList:addItem(label, path)
end


function interactormodel.setSelectedPath(path)

	currentPath = path

	if path == nil then 
		interactormodel.selectionCleared()
	else
		--Replace the selection with the drawables in path
		controllers.selection.selectedSet = {}	
		for _,d in pairs(path:allDrawables()) do
			controllers.selection.selectedSet[d.prop] = d
		end
		
		-- Update UI
		g_addPathButton:setEnabled(path ~= nil)
		widgets.manipulator:show()
		widgets.keyframes:setCurrentPath(currentPath)
		widgets.modifierButton:setState(widgets.modifierButton.states.RECORD_UP)
		input.strokecapture.setMode(input.strokecapture.modes.MODE_RECORD )
	end
end

function interactormodel.getUserPaths()
	return userPaths
end


return interactormodel