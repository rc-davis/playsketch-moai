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

	controllers/recording.lua
	
	Displays the manipulator widget and responds to its actions to create new recordings.
	This includes the need to maintain which transform is being manipulated.
	
	initManipulator()
	selectedSetChanged()
	getCurrentTransform()
	recordingButtonDown()
	recordingButtonUp()
	startRecording()
	stopRecording()
	
--]]


controllers.recording = {}

local currentTransform = nil
local currentObjectSet = nil
local manipulator = nil
local currentlyRecording = false
local erasingThread = nil
local erasingType = nil

--forward declarations for local functions:
local	manipulatorTranslated, 
		manipulatorRotated,
		manipulatorScaled,
		manipulatorPivotChanged,
		manipulatorStartedChanging,
		manipulatorDoneChanging,		
		manipulatorUpdateLoop,
		hideManipulator,
		showManipulator


function controllers.recording.initManipulator()
	manipulator = widgets.newManipulator(
		manipulatorTranslated,
		manipulatorRotated,
		manipulatorScaled,
		manipulatorPivotChanged,
		manipulatorStartedChanging,
		manipulatorDoneChanging)
		
	-- start a thread to keep the manipulator in sync with the transforms it manipulates
	MOAIThread.new ():run ( manipulatorUpdateLoop, nil )
end


-- selectedSetChanged(): inform the recording controller that there's a new selection
function controllers.recording:selectedSetChanged(selectedSet)

	if #selectedSet == 0 then
		hideManipulator()
		g_recButton:setEnabled(false)
	else
		currentObjectSet = selectedSet
		showManipulator()
		g_recButton:setEnabled(true)
	end
end

-- getCurrentTransform(): return the transform that is currently being manipulated
function controllers.recording.getCurrentTransform()
	return currentTransform
end

function controllers.recording.getCurrentlyRecording()
	return currentlyRecording
end


-- we have to hold it down if we are using a touch screen, click if we are using a mouse
function controllers.recording.recordingButtonDown()
	if input.hasTouch then
		controllers.recording.startRecording()
	end
end

-- we have to hold it down if we are using a touch screen, click if we are using a mouse
function controllers.recording.recordingButtonUp()
	if input.hasTouch or currentlyRecording then
		controllers.recording.stopRecording()
	else
		controllers.recording.startRecording()
	end
end



function controllers.recording.startRecording()
	print("Start Recording")
	assert(currentObjectSet and #currentObjectSet > 0, "need objects to record with")
	assert(currentTransform, "need a transform to manipulate for recording")	
	currentlyRecording = true
	controllers.timeline.playButton:setEnabled(false)
		
	--start a new thread to keep erasing the space in front of us while we record
	erasingThread = MOAIThread.new():run (
		function ()
			local last_erase = -1e100
			while currentlyRecording do
				local now = controllers.timeline.currentTime()
				if now - last_erase > 0.25 then
					currentTransform:erase(now, 0.5, erasingType)
					last_erase = now
				end
				coroutine.yield()
			end
		end, nil)

	controllers.timeline.play()	
end

function controllers.recording.stopRecording()
	print("Stop Recording")
	controllers.timeline.pause()
	currentlyRecording = false
	controllers.timeline.playButton:setEnabled(true)
end



--------------
-- locals

hideManipulator = function ()
	manipulator:hide()

	if currentTransform and 
	currentTransform.isIdentity then
		currentTransform:delete()
	end
	currentTransform = nil
	g_keyframeWidget:setUserTransform(nil)
end


showManipulator = function ()
	
	assert(currentTransform == nil, "Shouldn't have a current transform still active")
	
	-- First! Pick a default center point for the manipulator widgets
	-- (averaging the centres of all the objects)
	local avgX,avgY = 0,0
	for i,o in ipairs(currentObjectSet) do
		local x,y = o:getCorrectedLocAtCurrentTime()
		avgX = avgX + x
		avgY = avgY + y
	end
	avgX = avgX/#currentObjectSet
	avgY = avgY/#currentObjectSet			
	--ensure we are still on the screen
	avgX = math.min(SCALED_WIDTH/2, math.max(-SCALED_WIDTH/2, avgX))
	avgY = math.min(SCALED_HEIGHT/2, math.max(-SCALED_HEIGHT/2, avgY))

	--Create a new user transform at this location
	currentTransform = model.getTransform(controllers.timeline.currentTime(),
											currentObjectSet) 
	g_keyframeWidget:setUserTransform(currentTransform)

	if currentTransform.isIdentity then 
		currentTransform:setPivot(avgX,avgY) 
	end
	manipulator:show()

end


-- keep the manipulator in sync with the current transform
manipulatorUpdateLoop = function()
	while true do
		if not currentlyRecording and manipulator and currentTransform then
			manipulator:moveTo(currentTransform:getCorrectedLocAtCurrentTime())
		end
		coroutine.yield ()
	end
end


---------- responding to manipulator actions:

manipulatorTranslated = function(dx,dy) 
	currentTransform:addTranslateFrame(controllers.timeline.currentTime(), dx,dy, currentlyRecording)
end

manipulatorRotated = function(dRot) 
	currentTransform:addRotateFrame(controllers.timeline.currentTime(), dRot, currentlyRecording)
end

manipulatorScaled = function(dScale) 
	currentTransform:addScaleFrame(controllers.timeline.currentTime(), dScale, currentlyRecording)
end

manipulatorPivotChanged = function(pivot_dx, pivot_dy)
	-- We need to start a new transform if the pivot has moved
	local old_pivot = currentTransform.pivot
	local old_loc = currentTransform.timelists['translate']:
				getInterpolatedValueForTime(controllers.timeline.currentTime())

	--unless the current transform doesn't contain any rotation or scaling information
	if not currentTransform.isIdentity then
		--todo: this will cause problems since it violates the uniqueness of the transform for a given set at a given time!
		currentTransform = 
				model.newTransform(controllers.timeline.currentTime(), currentObjectSet)
		
		g_keyframeWidget:setUserTransform(currentTransform)
	end				
	currentTransform:setPivot(	old_loc.x + old_pivot.x + pivot_dx, 
								old_loc.y + old_pivot.y + pivot_dy)
end

manipulatorStartedChanging = function(name)
	erasingType = name
end

manipulatorDoneChanging = function()
	erasingType = nil
end



return controllers.recording

