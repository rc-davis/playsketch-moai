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

	ui/rect.lua
	
	A simple Rectangle type

--]]

ui.rect = {}

local Rect = util.objects.defineType("Rect", util.objects.BaseType)

function ui.rect.new(originX, originY, width, height)

	local r = Rect:create()
	r:init(originX, originY, width, height)
	return r
	
end


function Rect:init(originX, originY, width, height)

	self.origin = { x = originX, y = originY }
	self.size = { width = width, height = height }

end


function Rect:toString()

	return "{ origin = {" .. self.origin.x .. ", " .. self.origin.y .. "}, size = {"..self.size.width .. ", ".. self.size.height .. "} }"

end


return ui.rect
