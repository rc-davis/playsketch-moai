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
