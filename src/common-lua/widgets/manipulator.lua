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
local pivotAdjustDiameterPcnt = 0.2 --as percentage of the width of the box
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

local function newManipulator(translateCallback, rotateCallback, scaleCallback, pivotAdjustCallback,
								startManipulatingCallback, doneManipulatingCallback)

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
	prop.translateCallback = translateCallback
	prop.rotateCallback = rotateCallback
	prop.scaleCallback = scaleCallback
	prop.pivotAdjustCallback = pivotAdjustCallback
	prop.startManipulatingCallback = startManipulatingCallback
	prop.doneManipulatingCallback = doneManipulatingCallback

	scriptDeck:setDrawCallback(
		function ( index, xOff, yOff, xFlip, yFlip )

			MOAIGfxDevice.setPenWidth(2)

			--draw background
			MOAIGfxDevice.setPenColor (unpack(scaleHandleBackgroundColor))
			MOAIDraw.fillRect( -defaultWidth/2, -defaultWidth/2, defaultWidth/2, defaultWidth/2 )

			--draw scale handles
			if prop.currentAction == actions.SCALE then
				MOAIGfxDevice.setPenColor (unpack(highlightColor))
			else
				MOAIGfxDevice.setPenColor (unpack(scaleHandleHandleColor))			
			end
			local scaleLoc = (defaultWidth/2)*(rotationDiameterPcnt/ROOT_2) -- x/y for the handle corner
			for _,i in ipairs({1,-1}) do for _,j in ipairs({1,-1}) do
				MOAIDraw.fillRect( i*defaultWidth/2, j*defaultWidth/2, i*scaleLoc, j*scaleLoc)
			end end
			
			--draw the rotation background
			MOAIGfxDevice.setPenColor (unpack(rotationBackgroundColor))			
			MOAIDraw.fillCircle(0,0, defaultWidth/2*rotationDiameterPcnt, 50)
			MOAIGfxDevice.setPenColor (unpack(rotationStrokeColor))			
			MOAIDraw.drawCircle(0,0, defaultWidth/2*rotationDiameterPcnt, 50)

			-- draw the rotation handles
			local rotHandleRad = defaultWidth/2*(rotationDiameterPcnt-translateDiameterPcnt)/2
			local rotHandleX = (defaultWidth/2*rotationDiameterPcnt - rotHandleRad)/ROOT_2

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
			MOAIDraw.fillCircle(0, 0, translateDiameterPcnt*defaultWidth/2, 50)
			MOAIGfxDevice.setPenColor (unpack(rotationStrokeColor))	
			MOAIDraw.drawCircle(0, 0, translateDiameterPcnt*defaultWidth/2, 50)

			-- draw the pivot adjustment handle
			if prop.currentAction == actions.PIVOTADJUST then
				MOAIGfxDevice.setPenColor (unpack(highlightColor))	
			else
				MOAIGfxDevice.setPenColor (unpack(pivotAdjustHandleColor))	
			end
			MOAIDraw.fillCircle(0, 0, pivotAdjustDiameterPcnt*defaultWidth/2, 50)
			MOAIGfxDevice.setPenColor (unpack(rotationStrokeColor))	
			MOAIDraw.drawCircle(0, 0, pivotAdjustDiameterPcnt*defaultWidth/2, 50)

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
				local x,y = prop:getLoc()
			
				-- figure out which widget we are interacting with
				local distanceFromCenterSq = math.sqrt((px-x)*(px-x)+(py-y)*(py-y))

				if distanceFromCenterSq < pivotAdjustDiameterPcnt*defaultWidth/2*prop:getScl() then
					-- touching the translate manipulator
					prop.currentAction = actions.PIVOTADJUST
					if prop.startManipulatingCallback then prop.startManipulatingCallback("pivot") end
				elseif distanceFromCenterSq < translateDiameterPcnt*defaultWidth/2*prop:getScl() then
					-- touching the translate manipulator
					prop.currentAction = actions.TRANSLATE
					if prop.startManipulatingCallback then prop.startManipulatingCallback("translate") end					
				elseif distanceFromCenterSq < rotationDiameterPcnt*defaultWidth/2*prop:getScl() then
					-- touching the rotate manipulator
					prop.currentAction = actions.ROTATE
					if prop.startManipulatingCallback then prop.startManipulatingCallback("rotate") end										
				else
					--touching the scale rectangle
					prop.currentAction = actions.SCALE
					if prop.startManipulatingCallback then prop.startManipulatingCallback("scale") end					
				end
			end
			return true
		end)
		
		
	--moved callback
	input.manager.addMovedCallback(input.manager.UILAYER, 
		function (id,px,py)
			if prop.touchID == id then
			
				if prop.currentAction == actions.TRANSLATE then
					--update the translation deltas and inform the callback
					local dx,dy = px-prop.touchLoc.x, py-prop.touchLoc.y
					prop.touchLoc = {x=px, y=py}
					prop:addLoc(dx,dy)				
					if prop.translateCallback then prop.translateCallback(dx,dy) end

				elseif prop.currentAction == actions.ROTATE then				
					--update the rotation deltas and inform the callback
					local xCenter,yCenter = prop:getLoc()
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
					prop:addRot(dAngle, dAngle)
					if prop.rotateCallback then prop.rotateCallback(dAngle) end

				elseif prop.currentAction == actions.SCALE then

					--calculate distances from the center
					local xCenter,yCenter = prop:getLoc()
					local distLast = math.sqrt( (xCenter-prop.touchLoc.x)*(xCenter-prop.touchLoc.x) +
												(yCenter-prop.touchLoc.y)*(yCenter-prop.touchLoc.y))
					local distNew  = math.sqrt( (xCenter-px)*(xCenter-px) +
												(yCenter-py)*(yCenter-py))
					

					local dScale = (distNew/distLast - 1)*prop:getScl()
					prop:addScl(dScale)
					prop.touchLoc = {x=px, y=py}
					if prop.scaleCallback then prop.scaleCallback(dScale) end
				elseif prop.currentAction == actions.PIVOTADJUST then
					--calculate the deltas travelled and inform the callback
					local dx,dy = px-prop.touchLoc.x, py-prop.touchLoc.y
					prop.touchLoc = {x=px, y=py}
					prop:addLoc(dx,dy)
					if prop.pivotAdjustCallback then prop.pivotAdjustCallback(dx,dy) end
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
				if prop.doneManipulatingCallback then prop.doneManipulatingCallback() end
				return true
			end

		end)
	
	function prop:show()
		self.visible = true
		self:setVisible(true)
		self:setRot(0,0)
		self:setScl(1)
	end

	function prop:moveTo(x,y)
		self:setLoc(x,y)
	end

	function prop:hide()
		self.visible = false
		self:setVisible(false)
	end


	prop:hide()
	return prop
end


widgets.manipulator = newManipulator(nil,nil,nil,nil,nil,nil)

return widgets.manipulator
