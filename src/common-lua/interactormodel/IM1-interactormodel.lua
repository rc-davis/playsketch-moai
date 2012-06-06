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

local selectedDrawables = nil
local currentPath = nil



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
	assert(selectedDrawables == nil, "Shouldn't be selecting when we already have a selection")
	assert(currentPath == nil, "shouldn't be selecting if we already have a path!")
	selectedDrawables = set

	--! Because this interactor model is for debugging, we create a NEW path on any selection
	currentPath = basemodel.createNewPath(selectedDrawables, nil, true)
	
	return currentPath
end

function interactormodel.selectionCleared()
	selectedDrawables = nil
	currentPath = nil
	
	return nil
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

return interactormodel