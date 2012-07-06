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

	ui/list.lua
	
	A simple list of views

--]]

ui.list = {}


local List = util.objects.defineType("List", ui.view.class())


function ui.list.class()

	return List

end


function ui.list.new( frame )

	local o = List:create()
	o:init(frame, text, size, color)
	return o
	
end


function List:init ( frame )

	self:superClass().init ( self, frame )
	
	self.items = {}
	self.selectedButton = nil
	
end


function List:addItem(view, index)

	--validate arguments
	assert( view:isa ( ui.view:class ( ) ) , "view must be a ui.view to be added" )
	if index == nil then index = #self.items + 1 end
	assert ( index > 0 and index <= 1 + #self.items, "AddView requires valid index" )
	
	-- remove a pre-existing one if it exists there?
	-- TODO
	
	-- add in the new one
	self.items[index] = view
	self:addSubview(view)
	self:refreshItemFrames()

end


function List:refreshItemFrames()

	local offset = 0
	
	for i=1,#self.items do
	
		local oldFrame = self.items[i]:getFrame()
		oldFrame.origin.y = offset
		offset = offset + oldFrame.size.height
		self.items[i]:setFrame(oldFrame)
		
	end

end

function List:itemCount()

	return #self.items
	
end

function List:setSelected(button)

	if self.selectedButton then
		self.selectedButton:setHighlighted(false)
	end
	
	if button ~= nil then
		button:setHighlighted(true)
	end
	
	self.selectedButton = button

end


function List:removeIndex(i)

	assert(i > 0 and i <= #self.items, "Need a valid index to remove")
	self.items[i]:removeFromSuperview()
	table.remove(self.items, i)
	self:refreshItemFrames()	

end


function List:removeItem(o)

	assert( o , "We need an object to remove" )
	local i = util.indexOf( self.items, o )
	self:removeIndex(i)

end


function List:clearAll()

	for i=#self.items,1,-1 do
		self:removeIndex(i)
	end
end


return ui.list
