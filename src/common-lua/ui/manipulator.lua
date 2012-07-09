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

	ui/manipulator.lua

	The k-sketch SRT manipulator.
	NOTE!!! This does NOT inherit from ui.view like everything else in this directory.
	This is because it needs to attach directly to the Paths being drawn and so it isn't 
	a part of the view hierarchy!
	
--]]


ui.manipulator = {}

local Manipulator = util.objects.defineType("Manipulator", util.objects.BaseType)

function ui.manipulator.new(keyframeUpdateCallback, recordingUpdateCallback, 
								startRecordingCallback, doneRecordingCallback)

	local r = Manipulator:create()
	r:init(keyframeUpdateCallback, recordingUpdateCallback, 
								startRecordingCallback, doneRecordingCallback)
	return r
	
end


--constants
local actions = {SCALE='scale', ROTATE='rotate', TRANSLATE='translate', PIVOTADJUST='pivotadjust'}
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


function Manipulator:init(keyframeUpdateCallback, recordingUpdateCallback, 
								startRecordingCallback, doneRecordingCallback)

	assert(ui.drawing.animationLayer, "UI.drawing.animationLayer must be initialized first")

	self.scriptDeck = MOAIScriptDeck.new ()
	self.scriptDeck:setRect ( -defaultWidth/2, -defaultWidth/2, defaultWidth/2, defaultWidth/2 )
	
	self.prop = MOAIProp2D.new ()
	self.prop:setDeck (self.scriptDeck )	
	ui.drawing.animationLayer:insertProp(self.prop)

	--set instance variables
	self.visible = true
	self.touchID = nil
	self.touchLoc = nil
	self.currentAction = nil
	self.keyframeUpdateCallback = keyframeUpdateCallback
	self.recordingUpdateCallback = recordingUpdateCallback
	self.startRecordingCallback = startRecordingCallback
	self.doneRecordingCallback = doneRecordingCallback

	self.scriptDeck:setDrawCallback(
		function ( index, xOff, yOff, xFlip, yFlip )
			self:drawCallback ( index, xOff, yOff, xFlip, yFlip )
		end )

end


function Manipulator:drawCallback ( index, xOff, yOff, xFlip, yFlip )

	local worldScale = self.prop:getAttr(MOAIProp2D.ATTR_WORLD_X_SCL)
	local scaledWidth = defaultWidth/worldScale
	
	self.scriptDeck:setRect ( -scaledWidth/2, -scaledWidth/2, scaledWidth/2, scaledWidth/2 )

	MOAIGfxDevice.setPenWidth(2)

	--draw background
	MOAIGfxDevice.setPenColor (unpack(scaleHandleBackgroundColor))
	MOAIDraw.fillRect( -scaledWidth/2, -scaledWidth/2, scaledWidth/2, scaledWidth/2 )

	--draw scale handles
	if self.currentAction == actions.SCALE then
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

	if self.currentAction == actions.ROTATE then
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
	if self.currentAction == actions.TRANSLATE then
		MOAIGfxDevice.setPenColor (unpack(highlightColor))	
	else
		MOAIGfxDevice.setPenColor (unpack(translateHandleColor))	
	end
	MOAIDraw.fillCircle(0, 0, translateDiameterPcnt*scaledWidth/2, 50)
	MOAIGfxDevice.setPenColor (unpack(rotationStrokeColor))	
	MOAIDraw.drawCircle(0, 0, translateDiameterPcnt*scaledWidth/2, 50)

	-- draw the pivot adjustment handle
	--[[
	if self.currentAction == actions.PIVOTADJUST then
		MOAIGfxDevice.setPenColor (unpack(highlightColor))	
	else
		MOAIGfxDevice.setPenColor (unpack(pivotAdjustHandleColor))	
	end
	MOAIDraw.fillCircle(0, 0, pivotAdjustDiameterPcnt*scaledWidth/2, 50)
	MOAIGfxDevice.setPenColor (unpack(rotationStrokeColor))	
	MOAIDraw.drawCircle(0, 0, pivotAdjustDiameterPcnt*scaledWidth/2, 50)
	--]]

end


function Manipulator:touchDown(id,px,py)
print("TOUCHED", px, py)

	if not self.prop:inside(px,py) or not self.visible then return false end

	if self.touchID == nil then

		assert(self.currentAction == nil, 
			"There should be no currentAction when we are starting one")

		self.touchID = id
		self.touchLoc = {x=px,y=py}
		local x,y = self.prop:modelToWorld(self.prop:getLoc())
	
		-- figure out which widget we are interacting with
		local distanceFromCenterSq = math.sqrt((px-x)*(px-x)+(py-y)*(py-y))

		--[[if distanceFromCenterSq < pivotAdjustDiameterPcnt*defaultWidth/2 then
			-- touching the translate manipulator
			prop.currentAction = actions.PIVOTADJUST
		else--]]if distanceFromCenterSq < translateDiameterPcnt*defaultWidth/2 then
			-- touching the translate manipulator
			self.currentAction = actions.TRANSLATE
		elseif distanceFromCenterSq < rotationDiameterPcnt*defaultWidth/2 then
			-- touching the rotate manipulator
			self.currentAction = actions.ROTATE
		else
			--touching the scale rectangle
			self.currentAction = actions.SCALE
		end
		
		if controllers.interfacestate.state() == STATES.RECORDING_BUTTON_DOWN then
		
			self:setInheritsFromPath(nil) -- so the manipulator doesn't jump around while we're using it
			
			controllers.interfacestate.setState(STATES.RECORDING)
			
			if self.startRecordingCallback then
				self.startRecordingCallback(controllers.timeline.currentTime(), self.currentAction)
			end
		else
			controllers.undo.startGroup("Manipulator Keyframe Drag")
		end
	end

	return true
end
		
		
function Manipulator:touchMoved(id,px,py)
	if self.touchID == id then

		local data = {time = controllers.timeline.currentTime()}

		local xCenter,yCenter
		if controllers.interfacestate.state() == STATES.RECORDING then
			xCenter,yCenter = self.prop:getLoc()
		else
			xCenter,yCenter = self.prop:modelToWorld(self.prop:getLoc())
		end
	
		if self.currentAction == actions.TRANSLATE then
			--update the translation deltas
			local dx,dy = px-self.touchLoc.x, py-self.touchLoc.y
			self.touchLoc = {x=px, y=py}
			data.dx,data.dy = dx,dy

		elseif self.currentAction == actions.ROTATE then				
			--update the rotation deltas
			local angleLast = math.atan2(self.touchLoc.y - yCenter, 
										self.touchLoc.x - xCenter)
			local angleNew = math.atan2(py - yCenter, 
										px - xCenter)
			--calculate the angle between current touch and touchLoc
			local dAngleRad = angleNew - angleLast
			if dAngleRad > math.pi then dAngleRad = dAngleRad - 2*math.pi end
			if dAngleRad < -math.pi then dAngleRad = dAngleRad + 2*math.pi end
			local dAngle = math.deg(dAngleRad)
			self.touchLoc = {x=px, y=py}
			data.dAngle = dAngle

		elseif self.currentAction == actions.SCALE then

			--calculate distances from the center
			local distLast = math.sqrt( (xCenter-self.touchLoc.x)*(xCenter-self.touchLoc.x) +
										(yCenter-self.touchLoc.y)*(yCenter-self.touchLoc.y))
			local distNew  = math.sqrt( (xCenter-px)*(xCenter-px) +
										(yCenter-py)*(yCenter-py))

			local dScale = (distNew/distLast - 1)
			self.touchLoc = {x=px, y=py}
			data.dScale = dScale
			
		elseif self.currentAction == actions.PIVOTADJUST then
			--calculate the deltas travelled
			local dx,dy = px-self.touchLoc.x, py-self.touchLoc.y
			self.touchLoc = {x=px, y=py}
			self.prop:addLoc(dx,dy)
			data.pivotDx,data.pivotDy = dx,dy
		end
		
		if controllers.interfacestate.state() == STATES.RECORDING then
			self:repositionManually(data)
			
			if self.recordingUpdateCallback then
				self.recordingUpdateCallback(data)
			end
		else
			self.keyframeUpdateCallback(data)
		end
		
		return true
	end
end


function Manipulator:touchUp(id,px,py)

	if self.touchID == id then

		self.touchID = nil
		self.currentAction = nil
		self.touchLoc = nil
		if controllers.interfacestate.state() == STATES.RECORDING then

			controllers.interfacestate.setState(STATES.RECORDING_BUTTON_DOWN)
			self:setInheritsFromPath(controllers.interfacestate.currentPath())

			if self.doneRecordingCallback then
				self.doneRecordingCallback(controllers.timeline.currentTime())
			end
		else
			controllers.undo.endGroup("Manipulator Keyframe Drag")
		end
		return true
	end
end
	
		
function Manipulator:setInheritsFromPath(path)

	if path then
		-- reset everything back to zero
		self.prop:setLoc(0,0)
		self.prop:setRot(90)
		
		print("LOC!!!", self.prop:getLoc())
	
		--Find any one of the path's drawables that we can inherit from to keep the motion in sync
		local anyDrawable = util.anyItem(path:allDrawables())
		assert(anyDrawable ~= nil, "We need a drawable to attach to!")
		local drawablePathProp = anyDrawable.paths[path]

		-- TODO: This is a terrible way of doing this. INHERIT_TRANSFORM inherits EVERYTHING
		-- We'd really rather inherit the location and rotation and not the scale
		-- That doesn't work, so we'll inherit everything, then adjust the scale we are drawing at.
		self.prop:clearAttrLink ( MOAIProp2D.INHERIT_TRANSFORM )
		self.prop:setAttrLink(MOAIProp2D.INHERIT_TRANSFORM, drawablePathProp, MOAIProp2D.TRANSFORM_TRAIT)
		
		
		print("LOC!!!after", self.prop:getLoc())		
	else		
		-- copy position information from current path
		local newx,newy = self.prop:modelToWorld(self.prop:getLoc())
		local newrot = self.prop:getWorldRot()
		self.prop:clearAttrLink ( MOAIProp2D.INHERIT_TRANSFORM )
		self.prop:setLoc(newx,newy)
		self.prop:setRot(90-newrot)
	end
end


function Manipulator:attachToPath(path)
	self:setInheritsFromPath(path)
	self.visible = true
	self.prop:setVisible(true)
end

function Manipulator:hide()
	self:setInheritsFromPath(nil)	
	self.visible = false
	self.prop:setVisible(false)
end

function Manipulator:repositionManually(data)
	if data.dx and data.dy then self.prop:addLoc(data.dx,data.dy) end
	if data.dScale then self.prop:addScl(data.dScale) end
	if data.dAngle then self.prop:addRot(data.dAngle) end
end

function Manipulator:inUse()
	return (self.touchID ~= nil)
end



local _manipulatorSingleton = nil 

function ui.manipulator.get()

	if _manipulatorSingleton == nil then
		_manipulatorSingleton = ui.manipulator.new(	function(d) interactormodel.updateKeyframe(d) end,
													function(d) interactormodel.recordingUpdate(d) end,
													function(t, action) interactormodel.recordingStarts(t, action) end,
													function(t) interactormodel.recordingFinished(t) end)
	end

	return _manipulatorSingleton

end


return ui.manipulator
