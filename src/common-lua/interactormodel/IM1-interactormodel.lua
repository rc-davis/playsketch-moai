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
end


function interactormodel.selectionCleared()
	g_pathList:setSelected(nil)
end


local recordedMotionSession = nil
local recordingState = { loc={} }

function interactormodel.recordingStarts(time)
	assert(recordedMotionSession == nil, "no other recording sessions going on")
	recordedMotionSession = currentPath:startRecordedMotion(time)
	recordingState.s,
	recordingState.r,
	recordingState.t,
	recordingState.v = currentPath:stateAtTime(time)
	controllers.playback.setPathToNotAnimate(currentPath)

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
		updateS = recordingState.s
	end
	if data.dAngle then
		recordingState.r = recordingState.r + data.dAngle
		updateR = recordingState.r
	end
	if data.dx and data.dy then 
		recordingState.t.x = recordingState.t.x + data.dx
		recordingState.t.y = recordingState.t.y + data.dy
		updateT = recordingState.t
	end
	--todo: visibility?

	recordedMotionSession:addMotion(data.time, updateS, updateR, updateT)
	
end

function interactormodel.recordingFinished(time)

	assert(recordedMotionSession, "Need an motion session to apply finish recording")

	controllers.timeline.pause()	
	recordedMotionSession:endSession(time)
	recordedMotionSession = nil
	controllers.playback.setPathToNotAnimate(nil)

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

function interactormodel.clearAll()
	basemodel.clearAll()
	g_pathList:clearAll()
end


------------------ /INTERACTOR MODEL API ----------------------


------------------ HELPERS FOR THIS SPECIFIC INTERFACE --------
function interactormodel.makeNewUserPath()

	 -- arbitrarily limit us to 9 paths to fit in the UI
	if #interactormodel.getUserPaths() >= 9 then return end

	local drawableArray = util.dictionaryValuesToArray(controllers.selection.selectedSet)
	local path = basemodel.createNewPath(drawableArray, nil, controllers.timeline.currentTime(), true)
	path.isUserPath = true --HACK
	path.id = nextId
	nextId = nextId + 1
	
	local label =	"Path " .. path.id ..
					" (" .. util.tableCount(path:allDrawables()) .. ")"
	g_pathList:addItem(label, path)
end


function interactormodel.setSelectedPath(path)

	-- Remove any pre-existing paths
	if currentPath ~= nil then 

		currentPath = nil

		--update the UI
		g_addPathButton:setEnabled(false)
		g_deletePathButton:setEnabled(false)
		widgets.manipulator:hide()
		widgets.keyframes:setCurrentPath(nil)
		widgets.modifierButton:setState(widgets.modifierButton.states.SELECT_UP)			
		input.strokecapture.setMode(input.strokecapture.modes.MODE_DRAW)
	end
	
	-- set the new path
	if path ~= nil then
	
		currentPath = path
	
		--Replace the selection with the drawables in path
		controllers.selection.selectedSet = {}	
		for _,d in pairs(path:allDrawables()) do
			controllers.selection.selectedSet[d.stroke] = d
		end
		
		-- Update UI
		g_addPathButton:setEnabled(true)
		g_deletePathButton:setEnabled(true)
		widgets.manipulator:attachToPath(currentPath)
		widgets.keyframes:setCurrentPath(currentPath)
		widgets.modifierButton:setState(widgets.modifierButton.states.RECORD_UP)
		input.strokecapture.setMode(input.strokecapture.modes.MODE_RECORD )
	end
end


function interactormodel.deleteSelectedPath()

	local pathToDelete = currentPath
	basemodel.deletePath(pathToDelete)
	
	--refresh interface
	rebuildPathList()

end


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