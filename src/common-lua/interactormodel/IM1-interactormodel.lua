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

local nextId = 1


------------------ INTERACTOR MODEL API ----------------------

function interactormodel.newDrawableCreated(prop)
	basemodel.addNewDrawable(prop, controllers.timeline.currentTime())
end

function interactormodel.selectableDrawables(time)
	assert(time == controllers.timeline.currentTime(),
		"assuming that we are only trying to select drawables at the current time for"..
		"efficiency. This can be updated if this assumption stops being true")
	local selectable = {}
	for _,o in pairs(basemodel.allDrawables()) do
		if o:currentlyVisible() then table.insert(selectable, o) end
	end
	return selectable
end

function interactormodel.selectionMade(set)

end


function interactormodel.selectionStarted()

end


function interactormodel.selectionCleared()

end


local recordedMotionSession = nil
local recordingState = { loc={} }

function interactormodel.recordingStarts(time, action)
	assert(recordedMotionSession == nil, "no other recording sessions going on")
	assert(controllers.interfacestate.currentPath() ~= nil, "Shouldn't start recording without a path")
	recordedMotionSession = controllers.interfacestate.currentPath():startRecordedMotion(time, action)
	recordingState.s,
	recordingState.r,
	recordingState.t,
	recordingState.v = controllers.interfacestate.currentPath():stateAtTime(time)

	if not controllers.timeline.playing then
		controllers.timeline.play()
	end
end


function interactormodel.recordingUpdate(data)

	-- make sure we have a session ready
	if not recordedMotionSession then interactormodel.recordingStarts(data.time) end

	--todo: this is a lot of paperwork due to mismatched parameter types and should be cleaner

	--update our cached locations
	local updateS, updateR, updateT = nil,nil,nil
	if data.dScale then
		recordingState.s = recordingState.s + data.dScale
		recordedMotionSession:addMotion(data.time, recordingState.s)
	end
	if data.dAngle then
		recordingState.r = recordingState.r + data.dAngle
		recordedMotionSession:addMotion(data.time, recordingState.r)
	end
	if data.dx and data.dy then 
		recordingState.t.x = recordingState.t.x + data.dx
		recordingState.t.y = recordingState.t.y + data.dy
		recordedMotionSession:addMotion(data.time, recordingState.t)
	end
end

function interactormodel.recordingFinished(time)

	assert(recordedMotionSession, "Need an motion session to apply finish recording")

	controllers.timeline.pause()	
	recordedMotionSession:endSession(time)
	recordedMotionSession = nil

end

function interactormodel.updateKeyframe(data)
	assert(controllers.interfacestate.currentPath(), "can't update keyframe without a current Path")
	local s,r,t,v = controllers.interfacestate.currentPath():stateAtTime(data.time)
	if data.dScale then s = s + data.dScale else s = nil end
	if data.dAngle then r = r + data.dAngle else r = nil end
	if data.dx and data.dy then t.x,t.y = t.x + data.dx, t.y + data.dy else t = nil end
	controllers.interfacestate.currentPath():addKeyframedMotion(data.time, s, r, t, nil, nil)
end

function interactormodel.clearAll()
	basemodel.clearAll()
end


------------------ /INTERACTOR MODEL API ----------------------


------------------ HELPERS FOR THIS SPECIFIC INTERFACE --------
function interactormodel.makeNewUserPath()

	 -- arbitrarily limit us to 8 paths to fit in the UI
	if #interactormodel.getUserPaths() >= 8 then return end

	local drawablesList = controllers.selection.getSelectedDrawables()
	
	-- Make up a (fixed) centerpoint for the new path
	local xSum,ySum = 0,0
	for _,d in pairs(drawablesList) do
		local x,y = d:correctedLocAtCurrentTime()
		xSum,ySum = xSum+x,ySum+y
	end
	local centerPoint = { x = xSum/#drawablesList, y = ySum/#drawablesList }	
	local path = basemodel.createNewPath(drawablesList, nil, controllers.timeline.currentTime(), true, centerPoint)
	path.isUserPath = true --HACK
	path.id = nextId
	nextId = nextId + 1
	return path
end

function interactormodel.deleteSelectedPath()

	assert(controllers.interfacestate.currentPath(), "Need a current path to delete")
	basemodel.deletePath(controllers.interfacestate.currentPath())
	controllers.interfacestate.setCurrentPath(nil)
end


function interactormodel.toggleSelectedPathVisibility()

	assert(controllers.interfacestate.currentPath(), "Need a current path to toggle visibility for")
	local time = controllers.timeline:currentTime()
	local _,_,_,v = controllers.interfacestate.currentPath():stateAtTime(time)
	controllers.interfacestate.currentPath():setVisibility(time, not v)
	controllers.playback.refresh()
end


-- These are just the subset of paths that have been explicitly created in our interface
function interactormodel.getUserPaths()
	local allPaths = basemodel.allPaths()
	local userPaths = {}
	for _,p in pairs(allPaths) do
		if p.isUserPath then
			table.insert(userPaths, p)
		end
	end
	return userPaths
end


return interactormodel