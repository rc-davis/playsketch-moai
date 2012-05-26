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

	basemodel/path.lua
	
	Encapsulates a path for transforming Drawables

--]]


basemodel.path = {}

local Path = {}

-- Clone the Path prototype
function basemodel.path.newPath()
	p = {}
	for i, v in pairs(Path) do
		p[i]=v
	end
	p:init()
	return p
end


--Path methods

function Path:init(prop)
	self.class = "Path"

	self.timelists = {	scale=model.timelist.new(),
						rotate=model.timelist.new(),
						translate=model.timelist.new()	}

	self.span = {start=1e99,stop=-1e99}
	self.dependentTransforms = {}	
	self.activeThreads = {}
	self.activeAnimations = {}
	self.keyframes = {}

end

return basemodel.path
