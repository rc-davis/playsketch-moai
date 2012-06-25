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

	widgets/manipulator.lua

	The k-sketch SRT manipulator.
	
--]]

--constants
local actions = {SCALE=1, ROTATE=2, TRANSLATE=3, PIVOTADJUST=4}
--local pivotAdjustDiameterPcnt = 0.2 --as percentage of the width of the box
local translateDiameterPcnt = 0.5
local rotationDiameterPcnt = 0.9
local defaultWidth = 250
local ROOT_2 = 1.414213562
local scaleHandleBackgroundColor = {0, 0.4, 0.005, 0.5}
local scaleHandleHandleColor = {0, 0.25, 0.005, 0.5}
local rotationBackgroundColor = {0.23, 0.21, 0.35, 0.5}
local rotationHandleColor = {0.5, 0.5, 0.5, 0.5}
local rotationStrokeColor = {0.160, 0.122, 0.772, 1.000}
local translateHandleColor = {0.5, 0.5, 0.5, 0.5}
local pivotAdjustHandleColor = {0.1, 0.5, 0.1, 0.5}
local highlightColor = {7.0, 0, 0, 0.7}

local function newManipulator(	keyframeUpdateCallback, recordingUpdateCallback, 
								startRecordingCallback, doneRecordingCallback)

	assert(widgets.layer, "must call widgets.init() before creating widgets")

	local scriptDeck = MOAIScriptDeck.new ()
	scriptDeck:setRect ( -defaultWidth/2, -defaultWidth/2, defaultWidth/2, defaultWidth/2 )
	
	local prop = MOAIProp2D.new ()
	prop:setDeck ( scriptDeck )	
	widgets.layer:insertProp(prop)

	--set instance variables
	prop.visible = true
	prop.touchID = nil
	prop.touchLoc = nil
	prop.currentAction = nil
	prop.keyframeUpdateCallback = keyframeUpdateCallback
	prop.recordingUpdateCallback = recordingUpdateCallback
	prop.startRecordingCallback = startRecordingCallback
	prop.doneRecordingCallback = doneRecordingCallback

	scriptDeck:setDrawCallback(
		function ( index, xOff, yOff, xFlip, yFlip )

			local worldScale = prop:getAttr(MOAIProp2D.ATTR_WORLD_X_SCL)
			local scaledWidth = defaultWidth/worldScale
			
			scriptDeck:setRect ( -scaledWidth/2, -scaledWidth/2, scaledWidth/2, scaledWidth/2 )
	
			MOAIGfxDevice.setPenWidth(2)

			--draw background
			MOAIGfxDevice.setPenColor (unpack(scaleHandleBackgroundColor))
			MOAIDraw.fillRect( -scaledWidth/2, -scaledWidth/2, scaledWidth/2, scaledWidth/2 )

			--draw scale handles
			if prop.currentAction == actions.SCALE then
				MOAIGfxDevice.setPenColor (unpack(highlightColor))
			else
				MOAIGfxDevice.setPenColor (unpack(scaleHandleHandleColor))			
			end
			local scaleLoc = (scaledWidth/2)*(rotationDiameterPcnt/ROOT_2) -- x/y for the handle corner
			for _,i in ipairs({1,-1}) do for _,j in ipairs({1,-1}) do
				MOAIDraw.fillRect( i*scaledWidth/2, j*scaledWidth/2, i*scaleLoc, j*scaleLoc)
			end end
			
			--draw the rotation background
			MOAIGfxDevice.setPenColor (unpack(rotationBackgroundColor))			
			MOAIDraw.fillCircle(0,0, scaledWidth/2*rotationDiameterPcnt, 50)
			MOAIGfxDevice.setPenColor (unpack(rotationStrokeColor))			
			MOAIDraw.drawCircle(0,0, scaledWidth/2*rotationDiameterPcnt, 50)

			-- draw the rotation handles
			local rotHandleRad = scaledWidth/2*(rotationDiameterPcnt-translateDiameterPcnt)/2
			local rotHandleX = (scaledWidth/2*rotationDiameterPcnt - rotHandleRad)/ROOT_2

			if prop.currentAction == actions.ROTATE then
				MOAIGfxDevice.setPenColor (unpack(highlightColor))	
			else
				MOAIGfxDevice.setPenColor (unpack(rotationHandleColor))
			end			
			for _,i in ipairs({1,-1}) do for _,j in ipairs({1,-1}) do
				MOAIDraw.fillCircle( i*rotHandleX, j*rotHandleX, rotHandleRad, 50)
			end end
			MOAIGfxDevice.setPenColor (unpack(rotationStrokeColor))
			for _,i in ipairs({1,-1}) do for _,j in ipairs({1,-1}) do
				MOAIDraw.drawCircle( i*rotHandleX, j*rotHandleX, rotHandleRad, 50)
			end end

			-- draw the translation handle
			if prop.currentAction == actions.TRANSLATE then
				MOAIGfxDevice.setPenColor (unpack(highlightColor))	
			else
				MOAIGfxDevice.setPenColor (unpack(translateHandleColor))	
			end
			MOAIDraw.fillCircle(0, 0, translateDiameterPcnt*scaledWidth/2, 50)
			MOAIGfxDevice.setPenColor (unpack(rotationStrokeColor))	
			MOAIDraw.drawCircle(0, 0, translateDiameterPcnt*scaledWidth/2, 50)

			-- draw the pivot adjustment handle
			--[[
			if prop.currentAction == actions.PIVOTADJUST then
				MOAIGfxDevice.setPenColor (unpack(highlightColor))	
			else
				MOAIGfxDevice.setPenColor (unpack(pivotAdjustHandleColor))	
			end
			MOAIDraw.fillCircle(0, 0, pivotAdjustDiameterPcnt*scaledWidth/2, 50)
			MOAIGfxDevice.setPenColor (unpack(rotationStrokeColor))	
			MOAIDraw.drawCircle(0, 0, pivotAdjustDiameterPcnt*scaledWidth/2, 50)
			--]]

		end)

	-- Add our input response callbacks
	
	input.manager.addDownCallback(input.manager.UILAYER, 
		function (id,px,py)

			if not prop:inside(px,py) or not prop.visible then return false end

			if prop.touchID == nil then

				assert(prop.currentAction == nil, 
					"There should be no currentAction when we are starting one")

				prop.touchID = id
				prop.touchLoc = {x=px,y=py}
				local x,y = prop:modelToWorld(prop:getLoc())
			
				-- figure out which widget we are interacting with
				local distanceFromCenterSq = math.sqrt((px-x)*(px-x)+(py-y)*(py-y))

				--[[if distanceFromCenterSq < pivotAdjustDiameterPcnt*defaultWidth/2 then
					-- touching the translate manipulator
					prop.currentAction = actions.PIVOTADJUST
				else--]]if distanceFromCenterSq < translateDiameterPcnt*defaultWidth/2 then
					-- touching the translate manipulator
					prop.currentAction = actions.TRANSLATE
				elseif distanceFromCenterSq < rotationDiameterPcnt*defaultWidth/2 then
					-- touching the rotate manipulator
					prop.currentAction = actions.ROTATE
				else
					--touching the scale rectangle
					prop.currentAction = actions.SCALE
				end
				
				if controllers.interfacestate.state() == STATES.RECORDING_BUTTON_DOWN then
				
					prop:setInheritsFromPath(nil) -- so the manipulator doesn't jump around while we're using it
					
					controllers.interfacestate.setState(STATES.RECORDING)
					
					if prop.startRecordingCallback then
						prop.startRecordingCallback(controllers.timeline.currentTime())
					end
				else
					controllers.undo.startGroup("Manipulator Keyframe Drag")
				end
			end
			return true
		end)
		
		
	--moved callback
	input.manager.addMovedCallback(input.manager.UILAYER, 
		function (id,px,py)
			if prop.touchID == id then
			
				local data = {time = controllers.timeline.currentTime()}

				local xCenter,yCenter
				if controllers.interfacestate.state() == STATES.RECORDING then
					xCenter,yCenter = prop:getLoc()
				else
					xCenter,yCenter = prop:modelToWorld(prop:getLoc())
				end
			
			
				if prop.currentAction == actions.TRANSLATE then
					--update the translation deltas
					local dx,dy = px-prop.touchLoc.x, py-prop.touchLoc.y
					prop.touchLoc = {x=px, y=py}
					data.dx,data.dy = dx,dy

				elseif prop.currentAction == actions.ROTATE then				
					--update the rotation deltas
					local angleLast = math.atan2(prop.touchLoc.y - yCenter, 
												prop.touchLoc.x - xCenter)
					local angleNew = math.atan2(py - yCenter, 
												px - xCenter)
					--calculate the angle between current touch and touchLoc
					local dAngleRad = angleNew - angleLast
					if dAngleRad > math.pi then dAngleRad = dAngleRad - 2*math.pi end
					if dAngleRad < -math.pi then dAngleRad = dAngleRad + 2*math.pi end
					local dAngle = math.deg(dAngleRad)
					prop.touchLoc = {x=px, y=py}
					data.dAngle = dAngle

				elseif prop.currentAction == actions.SCALE then

					--calculate distances from the center
					local distLast = math.sqrt( (xCenter-prop.touchLoc.x)*(xCenter-prop.touchLoc.x) +
												(yCenter-prop.touchLoc.y)*(yCenter-prop.touchLoc.y))
					local distNew  = math.sqrt( (xCenter-px)*(xCenter-px) +
												(yCenter-py)*(yCenter-py))

					local dScale = (distNew/distLast - 1)
					prop.touchLoc = {x=px, y=py}
					data.dScale = dScale
					
				elseif prop.currentAction == actions.PIVOTADJUST then
					--calculate the deltas travelled
					local dx,dy = px-prop.touchLoc.x, py-prop.touchLoc.y
					prop.touchLoc = {x=px, y=py}
					prop:addLoc(dx,dy)
					data.pivotDx,data.pivotDy = dx,dy
				end
				
				if controllers.interfacestate.state() == STATES.RECORDING then
					prop:repositionManually(data)
					
					if prop.recordingUpdateCallback then
						prop.recordingUpdateCallback(data)
					end
				else
					prop.keyframeUpdateCallback(data)
				end
				
				return true
			end

		end)	
		
	input.manager.addUpCallback(input.manager.UILAYER, 
		function (id,px,py)
		
			if prop.touchID == id then
				prop.touchID = nil
				prop.currentAction = nil
				prop.touchLoc = nil
				if controllers.interfacestate.state() == STATES.RECORDING then

					controllers.interfacestate.setState(STATES.RECORDING_BUTTON_DOWN)
					prop:setInheritsFromPath(controllers.interfacestate.currentPath())

					if prop.doneRecordingCallback then
						prop.doneRecordingCallback(controllers.timeline.currentTime())
					end
				else
					controllers.undo.endGroup("Manipulator Keyframe Drag")
				end
				return true
			end

		end)
		
	function prop:setInheritsFromPath(path)
	
		if path then
			-- reset everything back to zero
			self:setLoc(0,0)
			self:setRot(90)
		
			--Find any one of the path's drawables that we can inherit from to keep the motion in sync
			local anyDrawable = util.anyItem(path:allDrawables())
			assert(anyDrawable ~= nil, "We need a drawable to attach to!")
			local drawablePathProp = anyDrawable.paths[path]
	
			-- TODO: This is a terrible way of doing this. INHERIT_TRANSFORM inherits EVERYTHING
			-- We'd really rather inherit the location and rotation and not the scale
			-- That doesn't work, so we'll inherit everything, then adjust the scale we are drawing at.
			self:clearAttrLink ( MOAIProp2D.INHERIT_TRANSFORM )
			self:setAttrLink(MOAIProp2D.INHERIT_TRANSFORM, drawablePathProp, MOAIProp2D.TRANSFORM_TRAIT)
		else		
			-- copy position information from current path
			local newx,newy = self:modelToWorld(self:getLoc())
			local newrot = self:getWorldRot()
			self:clearAttrLink ( MOAIProp2D.INHERIT_TRANSFORM )
			self:setLoc(newx,newy)
			self:setRot(90-newrot)
		end
	end


	function prop:attachToPath(path)
		self:setInheritsFromPath(path)
		self.visible = true
		self:setVisible(true)
	end

	function prop:hide()
		self:setInheritsFromPath(nil)	
		self.visible = false
		self:setVisible(false)
	end
	
	function prop:repositionManually(data)
		if data.dx and data.dy then prop:addLoc(data.dx,data.dy) end
		if data.dScale then prop:addScl(data.dScale) end
		if data.dAngle then prop:addRot(data.dAngle) end
	end

	function prop:inUse()
		return (self.touchID ~= nil)
	end

	prop:hide()
	return prop
end


widgets.manipulator = newManipulator(	function(d) interactormodel.updateKeyframe(d) end,
										function(d) interactormodel.recordingUpdate(d) end,
										function(t) interactormodel.recordingStarts(t) end,
										function(t) interactormodel.recordingFinished(t) end)

return widgets.manipulator
