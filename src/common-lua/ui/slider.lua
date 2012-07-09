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

	ui/slider.lua
	
	A slider we will use for our timeline

--]]

ui.slider = {}


local Slider = util.objects.defineType("Slider", ui.view.class())


function ui.slider.class()

	return Slider

end


function ui.slider.new( frame, min, max, backgroundImgPath, knobImgPath, knobDownImgPath, knobWidth )

	local o = Slider:create()
	o:init( frame, min, max, backgroundImgPath, knobImgPath, knobDownImgPath, knobWidth )
	return o
	
end


function Slider:init( frame, min, max, backgroundImgPath, knobImgPath, knobDownImgPath, knobWidth )

	self:superClass().init(self, frame)

	-- load up background image
	self.backgroundImage = ui.image.new( ui.rect.new(0, 0, frame.size.width, frame.size.height), backgroundImgPath )
	self:addSubview(self.backgroundImage)
	
	-- load up knob images
	self.knobImage = ui.image.new( ui.rect.new(0, 0, knobWidth, frame.size.height), knobImgPath )
	self:addSubview(self.knobImage)
	self.knobDownImg = ui.image.new( ui.rect.new(0, 0, knobWidth, frame.size.height), knobDownImgPath )
	self.state = MOAITouchSensor.TOUCH_UP
	
	-- initialize value
	self.value = min
	self.min = min
	self.max = max
	
end


function Slider:setValueChangedCallback( func )

	self.valueChangedCallback = func

end


function Slider:setValueChangeFinishedCallback( func )

	self.valueChangeFinishedCallback = func

end


function Slider:currentValue ( )

	if self.playingAnimation then
		local x,_ = self.knobImage.prop:getLoc() + self.knobDownImg.frame.size.width/2
		return self:valueForXvalue ( x )
	else
		return self.value
	end
end

function Slider:touchEvent(id, eventType, x, y)

	if	eventType == MOAITouchSensor.TOUCH_DOWN and 
		self.state == MOAITouchSensor.TOUCH_UP then
		
		self:addSubview ( self.knobDownImg )
		self.knobImage:removeFromSuperview ( )
		self.state = MOAITouchSensor.TOUCH_DOWN

		self:setValue ( nil, x )
		if self.valueChangedCallback then self.valueChangedCallback ( self.value ) end
				
	elseif	eventType == MOAITouchSensor.TOUCH_UP and 
		self.state == MOAITouchSensor.TOUCH_DOWN then
		
		self:addSubview ( self.knobImage )
		self.knobDownImg:removeFromSuperview ( )
		self.state = MOAITouchSensor.TOUCH_UP

		self:setValue ( nil, x )
		if self.valueChangeFinishedCallback then self.valueChangeFinishedCallback ( self.value ) end
		
	elseif	eventType == MOAITouchSensor.TOUCH_MOVE and 
		self.state == MOAITouchSensor.TOUCH_DOWN then

		self:setValue ( nil, x )
		if self.valueChangedCallback then self.valueChangedCallback ( self.value ) end

	end
	
end


function Slider:setValue ( value, xValue ) --ONE can be nil

	assert ( value ~= nil or xValue ~= nil, "setValue needs either a value or an xValue" )

	local xMin = self.knobImage.frame.size.width/2
	local xMax = self.frame.size.width - self.knobImage.frame.size.width/2

	if value then -- Calculate the xValue based on the value
	
		xValue = self:xValueForValue ( value )

	else -- Calculate the value based on xValue!

		value = self:valueForXvalue ( xValue )

	end
	
	-- bounds check
	value = math.min ( self.max, math.max ( self.min, value ) )
	xValue = math.min ( xMax, math.max ( xMin, xValue ) )

	-- Now set everything
	local newFrame = util.clone ( self.knobImage.frame )
	newFrame.origin.x = xValue - newFrame.size.width/2
	self.knobImage:setFrame ( newFrame )
	self.knobDownImg:setFrame ( newFrame )

	self.value = value
	
end

function Slider:valueForXvalue( xValue )
	local xMin = self.knobImage.frame.size.width/2
	local xMax = self.frame.size.width - self.knobImage.frame.size.width/2

	--calculate as a percent across & convert to a value
	local pcnt = ( xValue - xMin ) / ( xMax - xMin )
	return pcnt * ( self.max - self.min ) + self.min

end

function Slider:xValueForValue ( value )

	local xMin = self.knobImage.frame.size.width/2
	local xMax = self.frame.size.width - self.knobImage.frame.size.width/2

	--calculate as a percent across & convert to an x-value
	local pcnt = ( value - self.min ) / ( self.max - self.min )
	return pcnt * ( xMax - xMin ) + xMin

end


function Slider:play ( )

	assert(self.playingAnimation == nil, "should have no existing play animation")

	--Figure out the desired location in global coordinates
	local finalX = self.frame.size.width - self.knobImage.frame.size.width
	local duration = self.max - self.value
	self.playingAnimation = self.knobImage.prop:seekLoc( finalX, 0 , duration, MOAIEaseType.LINEAR)

end


function Slider:stop ( )

	if self.playingAnimation ~= nil then
		local val = self:currentValue()
		self.playingAnimation:stop ()
		self.playingAnimation = nil
		self:setValue( val )
	end

end


return ui.slider
