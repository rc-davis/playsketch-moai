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

	widgets/slider.lua

	The timeline slider
	
--]]

widgets.slider = {}

function widgets.slider:init(centerX, centerY, width, height, scrubberWidth, 
			imgBackground, imgSlider, imgSliderDown, callbackMoved, callbackMoveFinished)

	assert(widgets.layer, "widgets.layer must be initialized before creating buttons")

	self.minvalue = 0
	self.maxvalue = 1
	self.value = 0
	self.callbackMoved = callbackMoved
	self.callbackMoveFinished = callbackMoveFinished
	self.center = {x=centerX, y=centerY}
	self.size = {width=width, height=height}
	self.currentAnimation = nil

	self.background = widgets.newSimpleButton( centerX, centerY, width, height, 
					imgBackground, imgBackground, nil, nil, nil)
	
	self.scrubber = widgets.newSimpleDragableButton( centerX, centerY, scrubberWidth, height, 
						imgSlider, imgSliderDown, nil, nil)
	
	--jump to a time when 
	self.background.callbackUp = 
		function (button, px, py)
			self:setAtX(x, 0, true)
			if self.callbackMoveFinished then self.callbackMoveFinished(self, self.value) end
		end

	self.scrubber.callbackDrag = 
		function (button, dx, dy)
			local px,_ = self.scrubber:getLoc()
			self:setAtX(px, 0, true)
		end
	self.scrubber.callbackUp = 
		function (_,_,_)
			if self.callbackMoveFinished then self.callbackMoveFinished(self, self.value) end
		end

			
			
end


function widgets.slider:xToValue(x)
	assert(x >= self.center.x - self.size.width/2 + self.scrubber.size.width/2 and x <= self.center.x + self.size.width/2 - self.scrubber.size.width/2, 
		"converting x should go to a valid value")
	local new_pcnt_value = (x + self.size.width/2 - self.scrubber.size.width/2 - self.center.x)/(self.size.width - self.scrubber.size.width)
	return new_pcnt_value*(self.maxvalue - self.minvalue)+self.minvalue
end

function widgets.slider:setAtValue(v, duration)
	local pcnt = self.minvalue + (v - self.minvalue)/(self.maxvalue - self.minvalue)
	pcnt = math.max(0, math.min(1, pcnt))
	local new_x = self.center.x - self.size.width/2 + self.scrubber.size.width/2 + pcnt*(self.size.width - self.scrubber.size.width)
	self:setAtX(new_x, duration, false)
end

function widgets.slider:setAtX(px, duration, shouldCallback)
	
	--scrubber location
	px = math.min(px, self.center.x + self.size.width/2 - self.scrubber.size.width/2)
	px = math.max(px, self.center.x - self.size.width/2 + self.scrubber.size.width/2)

	if duration == 0 then
		self.scrubber:setLoc(px, self.center.y)
		self.value = self:xToValue(px)
	else
		self.currentAnimation = self.scrubber:seekLoc(px, self.center.y, duration, MOAIEaseType.LINEAR)
	end

	--callback
	if self.callbackMoved and shouldCallback then
		self.callbackMoved(self, self.value)
	end
end

function widgets.slider:currentValue()
	return self.value
end

function widgets.slider:setValueSpan(min,max)
	local currentValue = self:currentValue()	
	self.minvalue = min
	self.maxvalue = max
	self:setAtValue(currentValue, 0)
	if self.callbackMovied and shouldCallback then
		self.callbackMoved(self, currentValue)
	end
end

function widgets.slider:stop()
	if self.currentAnimation ~= nil then
		self.currentAnimation:stop()
		local x,_ = self.scrubber:getLoc()
		self.value = self:xToValue(x)
	end
end


return widgets.slider
