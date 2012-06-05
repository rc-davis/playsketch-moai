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

	widgets/buttons.lua

	-

--]]


-- newButtonInternal(): Common base for all of our other buttons
-- 						flips through the images in imgUpPathList and passes the index of 
--						the current image to the callbacks
local function newButtonInternal( centerX, centerY, width, height, 
					imgUpPathList, imgDownPath, imgDisabled,
					callbackDown, callbackUp, callbackMoved)

	assert(widgets.layer, "must call widgets.init() before creating new buttons")

	-- Build a prop
	local b = MOAIProp2D.new ()
	b:setLoc ( centerX, centerY )
	widgets.layer:insertProp ( b )	

	-- load up down images
	local graphicsDown = MOAIGfxQuad2D.new ()
	graphicsDown:setTexture (imgDownPath)
	graphicsDown:setRect ( -width/2, -height/2, width/2, height/2 )
	
	local graphics = {}
	for i=1,#imgUpPathList do
		graphics[i] = MOAIGfxQuad2D.new ()
		graphics[i]:setTexture (imgUpPathList[i])
		graphics[i]:setRect ( -width/2, -height/2, width/2, height/2 )
	end

	--load up disabled image
	if imgDisabled then
		graphics['disabled'] = MOAIGfxQuad2D.new ()
		graphics['disabled']:setTexture (imgDisabled)
		graphics['disabled']:setRect ( -width/2, -height/2, width/2, height/2 )
	end

	b.touchID = nil
	b.index = 1
	b.isEnabled = true
	b:setDeck(graphics[1])
	b.callbackDown = callbackDown
	b.callbackUp = callbackUp
	b.callbackMoved = callbackMoved
	
	function b:setIndex(i)
		assert(i <= #graphics, "must be a valid index to the list of button images")
		self.index = i
		if self.isEnabled then
			self:setDeck(graphics[i])
		else
			self:setDeck(graphics['disabled'])
		end
	end
	
	function b:getIndex()
		return self.index
	end
	
	function b:setEnabled(enabled)
		b.isEnabled = enabled
		if not enabled then
			self:setDeck(graphics['disabled'])
		else
			self:setDeck(graphics[self.index])
		end
	end

	--Set up callback for down events
	input.manager.addDownCallback(input.manager.UILAYER, 
		function (id,px,py)
			if b.touchID == nil and b:inside(px,py) then
				if not b.isEnabled then return true end
				b.touchID = id
				b.touchX,b.touchY = px,py				
				b:setDeck(graphicsDown)
				if b.callbackDown then
					b.callbackDown(b, px, py)
				end
				return true
			end
			return false
		end)

	--Add a callback for when we move
	input.manager.addMovedCallback(input.manager.UILAYER, 
		function (id,px,py)
			if b.touchID == id then
				b.touchID = id
				local dx,dy = (px-b.touchX),(py-b.touchY)
				b.touchX,b.touchY = px,py
				if b.callbackMoved then
					b.callbackMoved(b, dx, dy, px, py)
				end
			end
			return false
		end)

	--input manager callback for finishing a touch
	input.manager.addUpCallback(input.manager.UILAYER, 
		function (id,px,py)
			if b.touchID ~= nil and id == b.touchID then
				b:setDeck(graphics[b.index])
				if b:inside(px,py) and b.callbackUp then
					b.callbackUp(b, px, py)
				end
				b.touchID = nil
				return true
			else
				return false
			end
		end)

	return b
end



-- newSimpleButton(): 	A plain pushbutton, which calls the callback after being pushed
-- 						the callback has the form: callback(button)
function widgets.newSimpleButton( centerX, centerY, width, height, 
					imgUpPath, imgDownPath, imgDisabled, callbackUp, callbackDown)

	local b = newButtonInternal(centerX, centerY, width, height,
					{imgUpPath}, imgDownPath, imgDisabled,
					nil, nil, nil)
	b.callbackUp =	function(_, _, _) 
						if b.callbackUp_Simple then b.callbackUp_Simple(b) end
					end
	b.callbackDown =function(_, _, _) 
						if b.callbackDown_Simple then b.callbackDown_Simple(b) end
					end

	b.callbackUp_Simple = callbackUp
	b.callbackDown_Simple = callbackDown	
	return b
end									


-- newToggleButton(): 	Flips through the images in imgUpPathList
-- 						the callback has the form: callback(button)
function widgets.newToggleButton( centerX, centerY, width, height, 
					imgUpPathList, imgDownPath, imgDisabled, callbackUp )
					
	local b = newButtonInternal( centerX, centerY, width, height, 
					imgUpPathList, imgDownPath, imgDisabled,
					nil, nil, nil)

	b.state = 1	
	b.callbackUp = 	function(_,_,_) 
						if b.callbackUp_Toggle then b.callbackUp_Toggle(b) end
					end
	b.callbackUp_Toggle = callbackUp
	return b
end

-- newSimpleDragableButton(): 	a sprite that can be dragged around the screen
--		 						the callback has the form: callback(button,dx,dy)
function widgets.newSimpleDragableButton( centerX, centerY, width, height, 
					imgUpPath, imgDownPath, imgDisabled, callbackDrag)

	local b = newButtonInternal(centerX, centerY, width, height,
					{imgUpPath}, imgDownPath, imgDisabled, nil, nil, nil)
	b.callbackMoved = function (_,dx,dy,px,py) 
						b:moveLoc(dx,dy,0)
						if b.callbackDrag then b.callbackDrag(b,dx,dy) end
					end
	b.callbackDrag = callbackDrag
	return b
end									


