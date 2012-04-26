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

function widgets.newManipulator(x,y, movedCallback)

	assert(widgets.layer, "must call widgets.init() before creating widgets")

	-- Build a prop
	local b = MOAIProp2D.new ()
	b:setLoc ( x, y )
	widgets.layer:insertProp ( b )	

	-- load up required images
	local imageGfxNormal = MOAIGfxQuad2D.new ()
	imageGfxNormal:setTexture ("resources/manipulator.png")
	imageGfxNormal:setRect ( -50, -50, 100, 100 )
	b:setDeck(imageGfxNormal)
	
	--initialize state tracking				
	b.touchID = nil
	b.callbackMoved = movedCallback
	
	
	input.manager.addDownCallback(input.manager.UILAYER, function (id,px,py)
		if b.touchID == nil and b:inside(px,py) then
			b.touchID = id
			local bx,by = b:getLoc()
			b.offsetX = (px-bx)
			b.offsetY = (py-by)
			b.startX = px
			b.startY = py
			return true
		end
		return false
	end)
	
	input.manager.addMovedCallback(input.manager.UILAYER, function (id,px,py)
		if b.touchID ~= nil and id == b.touchID then
		
			b:setLoc(px-b.offsetX, py-b.offsetY)

			
			--SET THINGS HERE
			if b.callbackMoved then
				b.callbackMoved(px - b.startX, py - b.startY)
				b.startX = px
				b.startY = py
			end
			
			return true
		end
		return false
	end)
	
	
	--input manager callback for finishing a touch
	input.manager.addUpCallback(input.manager.UILAYER, function (id,px,py)
		if b.touchID ~= nil and id == b.touchID then
			b.touchID = nil

			--if b:inside(px,py) and b.callback then
				
			--	b:callback(
				
				
			--end
			
			return true
		end
		return false
	end)
	


	return b

end
