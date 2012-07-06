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

ui.view.layer = nil

local touchRecipient = {}

local ViewObject = util.objects.defineType("ViewObject", util.objects.BaseObject)

function ui.view.class()
	return ViewObject
end

-- Call this once to initialize the view system
function ui.view.initViewSystem(viewport, width, height)

	-- set up a layer to draw to
	print("Creating drawing layer")
	ui.view.layer = MOAILayer2D.new ()
	ui.view.layer:setViewport ( viewport )
	MOAISim.pushRenderPass ( ui.view.layer )
	
	ui.view.window = ui.view.new(ui.rect.new(-width/2, -height/2, width, height))
	ui.view.layer:insertProp(ui.view.window.prop) -- Have to do this one manually since there's no superview
	ui.view.window.inRootedHierarchy = true

	--Register the base window for touch events! (This gets ugly)
	if MOAIInputMgr.device.mouseLeft and MOAIInputMgr.device.pointer then
	
		MOAIInputMgr.device.mouseLeft:setCallback(
		
			function ()
		
				x,y = ui.view.layer:wndToWorld (MOAIInputMgr.device.pointer:getLoc ())
		
				if MOAIInputMgr.device.mouseLeft:down() then
		
					touchRecipient[1] = ui.view.window:internalTouchEventStart(1, MOAITouchSensor.TOUCH_DOWN, x, y)
		
				elseif touchRecipient[1] then
		
					touchRecipient[1]:touchEvent(1, MOAITouchSensor.TOUCH_UP, touchRecipient[1].prop:worldToModel(x, y))
					touchRecipient[1] = nil
		
				end
			end)
	
		MOAIInputMgr.device.pointer:setCallback(
		
			function ()
		
				if touchRecipient[1] then
		
					x,y = ui.view.layer:wndToWorld ( MOAIInputMgr.device.pointer:getLoc () )
					touchRecipient[1]:touchEvent(1, MOAITouchSensor.TOUCH_MOVE, touchRecipient[1].prop:worldToModel(x, y))
		
				end
		
			end)

	elseif MOAIInputMgr.device.touch then
	
		MOAIInputMgr.device.touch:setCallback(
		
			function ( eventType, id, x_wnd, y_wnd, tapCount )
		
				x,y = ui.view.layer:wndToWorld ( x_wnd, y_wnd  )
		
				if eventType == MOAITouchSensor.TOUCH_DOWN then 
				
					assert(touchRecipient[id] == nil, "shouldn't have a touch input for this id")
					touchRecipient[id] = ui.view.window:internalTouchEvent ( id, eventType, x, y )

				elseif touchRecipient[id] then 
				
					touchRecipient[id]:touchEvent(1, eventType, touchRecipient[id].prop:worldToModel(x, y))

					--clear it if needed
					if eventType ~= MOAITouchSensor.TOUCH_MOVE then
						touchRecipient[id] = nil
					end

				end

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
		
	self.children = {}
	self:setReceivesTouches(true)

	-- Set its location
	self.frame = ui.rect.new(0,0,0,0)
	self:setFrame(frameRect)
	
	self.inRootedHierarchy = false
	


end


function ViewObject:setFrame(frameRect)

	util.copyIntoTable( frameRect, self.frame )
	self.prop:setLoc(self.frame.origin.x, self.frame.origin.y)
	self.deck:setRect(0,0,self.frame.size.width, self.frame.size.height)

end


function ViewObject:getFrame()

	return util.clone(self.frame)
	
end


-- Private function for fixing our attr-links in subviews after changing the hierarchy
local function recursively_setAttrLink(subview)

	if subview.parent and subview.parent.inRootedHierarchy then

		ui.view.layer:insertProp(subview.prop) -- Have to do this one manually since there's no superview
		subview.prop:setAttrLink(MOAIProp2D.INHERIT_TRANSFORM, subview.parent.prop, MOAIProp2D.TRANSFORM_TRAIT)
		subview.inRootedHierarchy = true

	else

		subview.prop:clearAttrLink(MOAIProp2D.INHERIT_TRANSFORM)
		ui.view.layer:removeProp(subview.prop)
		subview.inRootedHierarchy = false

	end
	
	for _,child in pairs(subview.children) do 

		recursively_setAttrLink(child)

	end
	
end




function ViewObject:addSubview(subviewObject)

	assert( subviewObject:isa( ViewObject:class( ) ), "Need to add things that descend from ViewObject" )
	assert( subviewObject.parent == nil, "Shouldn't be already added to a parent!" )
	assert( subviewObject ~= self, "can't add a view to itself!" )

	-- Remove our subview from any pre-existing hierarchies
	if subviewObject.inRootedHierarchy == true then
		subviewObject:removeFromSuperview()
	end

	subviewObject.parent = self
	table.insert(self.children, subviewObject)

	recursively_setAttrLink(subviewObject)

end


function ViewObject:removeFromSuperview()

	util.tableDelete(self.parent.children, self)
	self.parent = nil
	
	recursively_setAttrLink(self)

end


function ViewObject:setBackgroundColor( color )

	self.backgroundColor = color
	self.deck:setDrawCallback( function () self:onDraw() end )

end

function ViewObject:setBorderColor( color )

	self.borderColor = color
	self.deck:setDrawCallback( function () self:onDraw() end )

end


function ViewObject:onDraw()
-- Only called AFTER we have set a background color

	if self.backgroundColor then
		MOAIGfxDevice.setPenColor ( unpack ( self.backgroundColor ) )
		MOAIDraw.fillRect ( 0, 0, self.frame.size.width, self.frame.size.height )
	end

	if self.borderColor then
		MOAIGfxDevice.setPenColor ( unpack ( self.borderColor ) )
		MOAIDraw.drawRect ( 0, 0, self.frame.size.width, self.frame.size.height )
	end

end


function ViewObject:setReceivesTouches(receivesTouches)

	self.receivesTouches = receivesTouches
	
end


function ViewObject:touchEvent(id, eventType, x, y)

	--This should be overridden by a subclass that wants touch events!
	if eventType == MOAITouchSensor.TOUCH_DOWN then
		print ( "TOUCHED", self, x, y)
	end
end


function ViewObject:internalTouchEventStart(id, eventType, x, y)
	
	-- Find the top-most subview that it hits
	-- If there isn't one, then it must hit us, so call our own :touchEvent()
	-- Return the view that is handling the event

	local hit = nil
		
	if self.prop:inside(x,y) then	

		local i = #self.children

		while i > 0 and hit == nil do

			if self.children[i].prop:inside(x,y) and self.children[i].receivesTouches then
				hit = self.children[i]:internalTouchEventStart(id, eventType, x, y)
			end
			i = i - 1
			
		end
		
		if hit == nil and self.receivesTouches then

			-- Pass the actual event on to the view that matches it, translating the points
			self:touchEvent(id, eventType, self.prop:worldToModel(x, y))
			hit = self

		end
		
	end

	return hit
end