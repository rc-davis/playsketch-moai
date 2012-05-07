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

	model/usertransform.lua

	This models a transform at a level that should correspond to a user's input or 
	intentions. It captures a span of time and a set of SRT actions (three timelists).
	
	It is applied to Drawable objects by creating Transforms in the draw hierarchy.
	Each object a user transform applies to gets its own transform for simplicity.

--]]


model.usertransform = {}

local UserTransform = {}

function model.usertransform.new()
	local l = {}
	for i,v in pairs(TimeList) do
		l[i] = v
	end
	l:init()
	return l
end


----- UserTransform methods -----
function UserTransform:init()

	self.span = {start=1e100,stop=-1e100}
	--TODO: self.objects = {} track the objects this applies to!
	
	self.scaleTimelist = model.timelist.new()
	self.rotateTimelist = model.timelist.new()
	self.translateTimelist = model.timelist.new()	

end


--TODO: what format does this information arrive in??
--function UserTransform:setSpan(start, stop)
--	self.span.start = start
--	self.span.stop = stop
--end


return model.usertransform
