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

	ui/drawing.lua
	
	The view that captures strokes and turns it into drawing or selection.
	This is a singleton, which creates the animation layer to accompany it
	TODO: this muddles up some controller logic when this should be more purely a view.

--]]

ui.drawing = {}
ui.drawing.animationLayer = nil

local Drawing = util.objects.defineType("Drawing", ui.view.class())


function ui.drawing.class()

	return Drawing

end


function ui.drawing.init( frame )

	-- Create our drawing capture view
	ui.drawing.captureView = Drawing:create()
	ui.drawing.captureView:init(frame)
	ui.view.window:addSubview ( ui.drawing.captureView )
	
	-- Create a new moai layer to be used for our animation
	ui.drawing.animationLayer = MOAILayer2D.new ()
	ui.drawing.animationLayer:setViewport ( ui.viewport )
	MOAISim.pushRenderPass ( ui.drawing.animationLayer )

	-- Calculate the camera that will give us a coordinate system that matches frame
	local newCamera = MOAICamera2D.new()
	local x,y,s = ui.drawing.animationLayer:getFitting(	-frame.origin.x,
														-frame.origin.y,
														ui.scaledWidth - frame.origin.x,
														ui.scaledHeight - frame.origin.y)
	newCamera:setLoc(x,y)
	newCamera:setScl(s)
	ui.drawing.animationLayer:setCamera(newCamera)
	
end


function Drawing:init ( frame )

	self:superClass().init ( self, frame )
	
	self.currentStroke = nil
	self.currentStrokeID = nil
	self.selecting = false

end


function Drawing:touchEvent(id, eventType, x, y)

	local state = controllers.interfacestate.state()

	if eventType == MOAITouchSensor.TOUCH_DOWN then
		
		if	state == STATES.NEUTRAL or state == STATES.DRAWING and self.currentStroke == nil then
		
			--start drawing
			self.currentStroke = controllers.stroke.new()
			self.currentStrokeID = id
			controllers.interfacestate.setState(STATES.DRAWING)
			
		elseif state ==  STATES.SELECT_BUTTON_DOWN and self.currentStroke == nil then
		
			--start SELECTING
			self.currentStroke = controllers.selection.startStroke()
			self.currentStrokeID = id
			self.selecting = true	
			controllers.interfacestate.setState(STATES.SELECTING)
			
		elseif	state == STATES.SELECTING or state == STATES.RECORDING then
		
			--ignore since we are busy doing something else!
			
		elseif	state == STATES.DRAWABLES_SELECTED or 
				state == STATES.PATH_SELECTED or 
				state == STATES.RECORDING_BUTTON_DOWN or 
				state == STATES.MANIPULATOR_IN_USE then
				
			--clear out and go back to NEUTRAL
			controllers.interfacestate.setState(STATES.NEUTRAL)
		
		end
		
	elseif eventType == MOAITouchSensor.TOUCH_UP then

		if self.currentStroke and id == self.currentStrokeID then

			ui.drawing.animationLayer:removeProp (self.currentStroke)
			self.currentStroke:doneStroke()

			if self.selecting then

				if controllers.selection.selectionIsEmpty() then
					controllers.interfacestate.setState(STATES.SELECT_BUTTON_DOWN)
				else
					controllers.interfacestate.setState(STATES.DRAWABLES_SELECTED)
				end
			
			elseif not util.tableIsEmpty(self.currentStroke.points) then

				interactormodel.newDrawableCreated(	self.currentStroke )
				controllers.interfacestate.setState(STATES.NEUTRAL)
					
			end
			
			self.currentStroke = nil
			self.currentStrokeID = nil
			self.selecting = false
		
		end
	
	elseif eventType == MOAITouchSensor.TOUCH_MOVE then

		-- Remember this point
		if self.currentStroke and id == self.currentStrokeID then
			self.currentStroke:addPoint(x,y)	
		end
	
	elseif eventType == MOAITouchSensor.TOUCH_CANCEL then
	
		if self.currentStroke and id == self.currentStrokeID then
			self.currentStroke:cancel()
			self.currentStroke = nil
			self.currentStrokeID = nil
			self.selecting = false
		end

	end
	
end

return ui.drawing
