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
					imgUpPathList, imgDownPath, 
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

	b.touchID = nil
	b.index = 1
	b:setDeck(graphics[1])
	b.callbackDown = callbackDown
	b.callbackUp = callbackUp
	b.callbackMoved = callbackMoved
	
	function b:setIndex(i)
		assert(i <= #graphics, "must be a valid index to the list of button images")
		self.index = i
		self:setDeck(graphics[i])
	end
	
	function b:getIndex()
		return self.index
	end

	--Set up callback for down events
	input.manager.addDownCallback(input.manager.UILAYER, 
		function (id,px,py)
			if b.touchID == nil and b:inside(px,py) then
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
					imgUpPath, imgDownPath, callbackUp)

	local b = newButtonInternal(centerX, centerY, width, height,
					{imgUpPath}, imgDownPath,
					nil, nil, nil)
	b.callbackUp =	function(_, _, _) 
						if b.callbackUp_Simple then b.callbackUp_Simple(b) end
					end
	b.callbackUp_Simple = callbackUp
	return b
end									


-- newToggleButton(): 	Flips through the images in imgUpPathList
-- 						the callback has the form: callback(button)
function widgets.newToggleButton( centerX, centerY, width, height, 
					imgUpPathList, imgDownPath, callbackUp )
					
	local b = newButtonInternal( centerX, centerY, width, height, 
					imgUpPathList, imgDownPath, 
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
					imgUpPath, imgDownPath, callbackDrag)

	local b = newButtonInternal(centerX, centerY, width, height,
					{imgUpPath}, imgDownPath, nil, nil, nil)
	b.callbackMoved = function (_,dx,dy,px,py) 
						b:moveLoc(dx,dy,0)
						if b.callbackDrag then b.callbackDrag(b,dx,dy) end
					end
	b.callbackDrag = callbackDrag
	return b
end									


-- newSlider(): 	A slider that can be used to select a value (used for timelines)
-- 					the callback has the form: callback(button,value), when the value changes
--					Use :setValueSpan(min,max) to set the allowable range of values
function widgets.newSlider(centerX, centerY, width, height, imgBackground, imgSlider, imgSliderDown, callback)

	assert(widgets.layer, "widgets.layer must be initialized before creating buttons")

	local slider = {}

	slider.minvalue = 0
	slider.maxvalue = 1
	slider.value = 0
	slider.callback = callback
	slider.currentAnimation = nil

	slider.background = newButtonInternal( centerX, centerY, width, height, 
								{imgBackground}, imgBackground, nil, nil, nil)

	slider.scrubber = widgets.newSimpleDragableButton( centerX, centerY, height, height, 
						imgSlider, imgSliderDown, nil)
	
	--jump to a time when 
	slider.background.callbackUp = 
		function (button, px, py)
			slider:setAtX(x, 0)
		end

	slider.scrubber.callbackDrag = 
		function (button, dx, dy)
			local px,_ = slider.scrubber:getLoc()
			slider:setAtX(px, 0)
		end

	function slider:xToValue(x)
		assert(x >= centerX - width/2 + height/2 and x <= centerX + width/2 - height/2, 
			"converting x should go to a valid value")
		local new_pcnt_value = (x + width/2 - height/2 - centerX)/(width - height)
		return new_pcnt_value*(slider.maxvalue - slider.minvalue)+slider.minvalue
	end

	function slider:setAtValue(v, duration)
		local pcnt = self.minvalue + (v - self.minvalue)/(self.maxvalue - self.minvalue)
		pcnt = math.max(0, math.min(1, pcnt))
		local new_x = centerX - width/2 + height/2 + pcnt*(width - height)
		self:setAtX(new_x, duration)
	end

	function slider:setAtX(px, duration)
		
		--scrubber location
		px = math.min(px, centerX + width/2 - height/2)
		px = math.max(px, centerX - width/2 + height/2)

		if duration == 0 then
			self.scrubber:setLoc(px, centerY)
			self.value = self:xToValue(px)
		else
			self.currentAnimation = self.scrubber:seekLoc(px, centerY, duration, MOAIEaseType.LINEAR)
		end

		--callback
		if self.callback and duration == 0 then --todo: should we skip callback?
			self.callback(self, self.value)
		end
	end
	
	function slider:currentValue()
		return self.value
	end

	function slider:setValueSpan(min,max)
		local currentValue = self:currentValue()	
		self.minvalue = min
		self.maxvalue = max
		self:setAtValue(currentValue, 0)
	end
	
	function slider:stop()
		if self.currentAnimation ~= nil then
			self.currentAnimation:stop()
			local x,_ = self.scrubber:getLoc()
			self.value = self:xToValue(x)
		end
	end

	return slider
end

