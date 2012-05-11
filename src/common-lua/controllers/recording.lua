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
	
--]]


controllers.recording = {}

local currentTransform = nil
local currentObjectSet = nil
local manipulator = nil

--forward declarations for local functions:
local	manipulatorTranslated, 
		manipulatorRotated,
		manipulatorScaled,
		manipulatorPivotChanged,
		manipulatorUpdateLoop,
		hideManipulator,
		showManipulator


function controllers.recording.initManipulator()
	manipulator = widgets.newManipulator(
		manipulatorTranslated,
		manipulatorRotated,
		manipulatorScaled,
		manipulatorPivotChanged)
		
	-- start a thread to keep the manipulator in sync with the transforms it manipulates
	MOAIThread.new ():run ( manipulatorUpdateLoop, nil )
end


-- selectedSetChanged(): inform the recording controller that there's a new selection
function controllers.recording:selectedSetChanged(selectedSet)

	if #selectedSet == 0 then
		hideManipulator()
	else
		currentObjectSet = selectedSet
		showManipulator()
	end
end

-- getCurrentTransform(): return the transform that is currently being manipulated
function controllers.recording.getCurrentTransform()
	return currentTransform
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
		if manipulator and currentTransform then
			manipulator:moveTo(currentTransform:getCorrectedLocAtCurrentTime())
		end
		coroutine.yield ()
	end
end


---------- responding to manipulator actions:

manipulatorTranslated = function(dx,dy) 
	currentTransform:addTranslateFrame(controllers.timeline.currentTime(), dx,dy)
end

manipulatorRotated = function(dRot) 
	currentTransform:addRotateFrame(controllers.timeline.currentTime(), dRot)
end

manipulatorScaled = function(dScale) 
	currentTransform:addScaleFrame(controllers.timeline.currentTime(), dScale)
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
				model.newInterpolatedUserTransform(currentObjectSet,
											controllers.timeline.currentTime())
		g_keyframeWidget:setUserTransform(currentTransform)
	end				
	currentTransform:setPivot(
								old_loc.x + old_pivot.x + pivot_dx, 
								old_loc.y + old_pivot.y + pivot_dy)
end



return controllers.recording
