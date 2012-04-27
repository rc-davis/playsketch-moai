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
	
	TODO: JUST A SKELETON RIGHT NOW

--]]

--constants
local innerDiameterPcnt = 0.4 --as percentage of the width of the box
local outerDiameterPcnt = 0.8
local defaultWidth = 200 --todo: ??
local ROOT_2 = 1.414213562
local scaleHandleFillColor = {0, 0.8, 0.01, 1.0}
local scaleHandleStrokeColor = {0, 0.5, 0.01, 1.0}
local rotationBackgroundColor = {0.452, 0.432, 0.772, 1.000}
local rotationHandleColor = {1.0, 1.0, 1.0, 1.000}
local rotationStrokeColor = {0.160, 0.122, 0.772, 1.000}
local translateHandleColor = {0.95, 0.95, 1.0, 1.000}

function widgets.newManipulator(x,y, movedCallback)

	assert(widgets.layer, "must call widgets.init() before creating widgets")

	local scriptDeck = MOAIScriptDeck.new ()
	scriptDeck:setRect ( -defaultWidth/2, -defaultWidth/2, defaultWidth/2, defaultWidth/2 )

	local prop = MOAIProp2D.new ()
	prop:setDeck ( scriptDeck )	
	--prop:setBlendMode(MOAIProp.GL_DST_COLOR, MOAIProp.GL_ONE_MINUS_SRC_ALPHA)
	--todo, make translucent

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

			MOAIGfxDevice.setPenColor (unpack(rotationHandleColor))
			for _,i in ipairs({1,-1}) do for _,j in ipairs({1,-1}) do
				MOAIDraw.fillCircle( i*rotHandleX, j*rotHandleX, rotHandleRad, 50)
			end end
			MOAIGfxDevice.setPenColor (unpack(rotationStrokeColor))
			for _,i in ipairs({1,-1}) do for _,j in ipairs({1,-1}) do
				MOAIDraw.drawCircle( i*rotHandleX, j*rotHandleX, rotHandleRad, 50)
			end end

			-- draw the translation handle
			MOAIGfxDevice.setPenColor (unpack(translateHandleColor))	
			MOAIDraw.fillCircle(0, 0, innerDiameterPcnt*defaultWidth/2, 50)
			MOAIGfxDevice.setPenColor (unpack(rotationStrokeColor))	
			MOAIDraw.drawCircle(0, 0, innerDiameterPcnt*defaultWidth/2, 50)

			
		end)


	widgets.layer:insertProp(prop)
	return prop
end
