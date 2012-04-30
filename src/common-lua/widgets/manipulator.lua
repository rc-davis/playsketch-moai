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
	
	TODO: 
		- No scaling
		- semi-transparent

--]]


--constants
local innerDiameterPcnt = 0.4 --as percentage of the width of the box
local outerDiameterPcnt = 0.8
local defaultWidth = 250
local ROOT_2 = 1.414213562
local scaleHandleFillColor = {0, 0.8, 0.01, 1.0}
local scaleHandleStrokeColor = {0, 0.5, 0.01, 1.0}
local rotationBackgroundColor = {0.452, 0.432, 0.772, 1.000}
local rotationHandleColor = {1.0, 1.0, 1.0, 1.000}
local rotationStrokeColor = {0.160, 0.122, 0.772, 1.000}
local translateHandleColor = {0.95, 0.95, 1.0, 1.000}
local highlightColor = {1.0, 0, 0, 1.0}

local actions = {SCALE=1, ROTATE=2, TRANSLATE=3}

function widgets.newManipulator(translateCallback, rotateCallback)

	assert(widgets.layer, "must call widgets.init() before creating widgets")

	local scriptDeck = MOAIScriptDeck.new ()
	scriptDeck:setRect ( -defaultWidth/2, -defaultWidth/2, defaultWidth/2, defaultWidth/2 )

	local prop = MOAIProp2D.new ()
	prop:setDeck ( scriptDeck )	
	--prop:setBlendMode(MOAIProp.GL_DST_COLOR, MOAIProp.GL_ONE_MINUS_SRC_ALPHA)
	--todo, make translucent
	widgets.layer:insertProp(prop)

	--set instance variables
	prop.visible = true
	prop.touchID = nil
	prop.touchLoc = nil
	prop.currentAction = nil
	prop.translateCallback = translateCallback
	prop.rotateCallback = rotateCallback

	scriptDeck:setDrawCallback(
		function ( index, xOff, yOff, xFlip, yFlip )

			--draw background
			MOAIGfxDevice.setPenColor (unpack(scaleHandleFillColor))
			MOAIDraw.fillRect( -defaultWidth/2, -defaultWidth/2, defaultWidth/2, defaultWidth/2 )

			--draw scale handles
			local scaleLoc = (defaultWidth/2)*(outerDiameterPcnt/ROOT_2) -- x/y for the handle corner
			MOAIGfxDevice.setPenColor (unpack(scaleHandleStrokeColor))
			for _,i in ipairs({1,-1}) do for _,j in ipairs({1,-1}) do
				MOAIDraw.fillRect( i*defaultWidth/2, j*defaultWidth/2, i*scaleLoc, j*scaleLoc)
			end end
			
			--draw the rotation background
			MOAIGfxDevice.setPenColor (unpack(rotationBackgroundColor))			
			MOAIDraw.fillCircle(0,0, defaultWidth/2*outerDiameterPcnt, 50)
			MOAIGfxDevice.setPenColor (unpack(rotationStrokeColor))			
			MOAIDraw.drawCircle(0,0, defaultWidth/2*outerDiameterPcnt, 50)

			-- draw the rotation handles
			local rotHandleRad = defaultWidth/2*(outerDiameterPcnt-innerDiameterPcnt)/2
			local rotHandleX = (defaultWidth/2*outerDiameterPcnt - rotHandleRad)/ROOT_2

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
			MOAIDraw.fillCircle(0, 0, innerDiameterPcnt*defaultWidth/2, 50)
			MOAIGfxDevice.setPenColor (unpack(rotationStrokeColor))	
			MOAIDraw.drawCircle(0, 0, innerDiameterPcnt*defaultWidth/2, 50)
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
				
				if distanceFromCenterSq < innerDiameterPcnt*defaultWidth/2 then			
					-- touching the translate manipulator
					prop.currentAction = actions.TRANSLATE
				elseif distanceFromCenterSq < outerDiameterPcnt*defaultWidth/2 then
					-- touching the rotate manipulator
					prop.currentAction = actions.ROTATE

				end
				--todo: also compare to scale here
				
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
					local dAngle = math.deg(angleNew - angleLast)
					prop.touchLoc = {x=px, y=py}
					prop:addRot(dAngle, dAngle)
					if prop.rotateCallback then prop.rotateCallback(dAngle) end

				end
				
				--TODO: support rotate and scale here as well
				
				return true
			end

		end)	
		
	input.manager.addUpCallback(input.manager.UILAYER, 
		function (id,px,py)
		
			if prop.touchID == id then
				prop.touchID = nil
				prop.currentAction = nil
				prop.touchLoc = nil
				return true
			end

		end)
	
	function prop:show()
		self.visible = true
		self:setVisible(true)
		self:setRot(0,0)
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
