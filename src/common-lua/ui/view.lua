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

	ui/view.lua

	The ui.view class is responsible for managing screen display and input handling.
	All ui widgets should inherit from this class.

	Before using it must be initialized with ui.view.init(), which will create the root window
	
	A new empty view can be created with:
	ui.view.new(frameRect)

	TODO:
		bounds/frame	
		input passing
	
--]]

require "ui/rect"

ui.view = {}

local ViewObject = util.objects.defineType("ViewObject", util.objects.BaseObject)
local uiLayer

-- Call this once to initialize the view system
function ui.view.initViewSystem(viewport, width, height)

	-- set up a layer to draw to
	print("Creating drawing layer")
	uiLayer = MOAILayer2D.new ()
	uiLayer:setViewport ( viewport )
	MOAISim.pushRenderPass ( uiLayer )
	
	ui.view.window = ui.view.new(ui.rect.new(-width/2, -height/2, width, height))
	
	--Register the base window for touch events! (This gets ugly)
	if MOAIInputMgr.device.mouseLeft and MOAIInputMgr.device.pointer then
	
		MOAIInputMgr.device.mouseLeft:setCallback(
			function ()
				x,y = uiLayer:wndToWorld (MOAIInputMgr.device.pointer:getLoc ())
				if MOAIInputMgr.device.mouseLeft:down() then
					ui.view.window:internalTouchEvent(MOAITouchSensor.TOUCH_DOWN, x, y)
				else
					ui.view.window:internalTouchEvent(MOAITouchSensor.TOUCH_UP, x, y)
				end
			end)
	
		MOAIInputMgr.device.pointer:setCallback(
			function ()
				x,y = uiLayer:wndToWorld ( MOAIInputMgr.device.pointer:getLoc () )
				ui.view.window:internalTouchEvent(MOAITouchSensor.TOUCH_MOVE, x, y)
			end)

	elseif MOAIInputMgr.device.touch then
	
		MOAIInputMgr.device.touch:setCallback(
			function ( eventType, id, x_wnd, y_wnd, tapCount )
				x,y = uiLayer:wndToWorld ( x_wnd, y_wnd  )
				ui.view.window:internalTouchEvent ( eventType, x, y )
			end )
	
	else
		assert(false, "No supported input devices found!")
	end
	
end


function ui.view.new(frameRect)
	
	local v = ViewObject:create()
	v:init(frameRect)
	return v

end


function ViewObject:init(frameRect)

	print("Creating view sized:", frameRect:toString())
	
	-- Create a prop with these bounds
	self.prop = MOAIProp2D.new ()
	self.deck = MOAIScriptDeck.new ()
	self.prop:setDeck ( self.deck )
	uiLayer:insertProp(self.prop)
	
	self.children = {}

	-- Set its location
	self.frame = ui.rect.new(0,0,0,0)
	self:setFrame(frameRect)

end


function ViewObject:setFrame(frameRect)

	util.copyIntoTable( frameRect, self.frame )
	self.prop:setLoc(self.frame.origin.x, self.frame.origin.y)
	self.deck:setRect(0,0,self.frame.size.width, self.frame.size.height)

end


function ViewObject:getFrame()

	return util.clone(self.frame)
	
end


function ViewObject:addSubview(subviewObject)

	assert( subviewObject:isa( self:class( ) ), "Need to add things that descend from ViewObject")
	assert( subviewObject.parent == nil, "Shouldn't be already added to a parent!")
	subviewObject.prop:setAttrLink(MOAIProp2D.INHERIT_TRANSFORM, self.prop, MOAIProp2D.TRANSFORM_TRAIT)
	subviewObject.parent = self
	table.insert(self.children, subviewObject)

end


function ViewObject:setBackgroundColor( r, g, b, a )

	self.backgroundColor = { r, g, b, a }
	self.deck:setDrawCallback( function () self:onDraw() end )

end


function ViewObject:onDraw()
-- Only called AFTER we have set a background color

	if self.backgroundColor then
		MOAIGfxDevice.setPenColor ( unpack ( self.backgroundColor ) )
		MOAIDraw.fillRect ( 0, 0, self.frame.size.width, self.frame.size.height )
	end

end


function ViewObject:touchEvent(eventType, x, y)

	--This should be overridden by a subclass that wants touch events!
	if eventType == MOAITouchSensor.TOUCH_DOWN then
		print ( "TOUCHED", self, x, y)
	end
end


function ViewObject:internalTouchEvent(eventType, x, y)
	
	-- Find the top-most subview that it hits
	-- If there isn't one, then it must hit us, so call our own :touchEvent()

	if self.prop:inside(x,y) then	

		local hit = false
		local i = #self.children

		while i > 0 and hit == false do

			if self.children[i].prop:inside(x,y) then
				self.children[i]:internalTouchEvent(eventType, x, y)
				hit = true
			end
			i = i - 1
			
		end
		
		if hit == false then
			-- Pass the actual event on to the view that matches it, translating the points
			self:touchEvent(eventType, self.prop:worldToModel(x, y))
		end
		
	end

end