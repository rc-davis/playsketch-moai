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

	model/dependenttransform.lua

	This is the scene-graph Moai transform to back a user transform.
	It applies to a *single* drawable object, but contains a reference to the user 
	transform, which keeps the collection of all objects affected.
	
	This should only be touched through the user transform.

--]]


model.dependenttransform = {}

local DependentTransform = {}

function model.dependenttransform.new(drawable, usertransform)
	local l = {}
	for i,v in pairs(DependentTransform) do
		l[i] = v
	end
	l:init(drawable, usertransform)
	return l
end

----- DependentTransform methods -----
function DependentTransform:init(drawable, usertransform)
	self.class = "DependentTransform"
	self.drawable = drawable
	self.usertransform = usertransform


	-- create a prop2d?
	self.prop = MOAIProp2D.new ()
	
	-- add it to the current hierarchy
	self.drawable:addTopLevelTransform(self)

end

function DependentTransform:refresh(absScale, absRot, absLocX, absLocY)
	if absScale ~= nil then
		self.prop:setScl(absScale)
	end

	if absRot ~= nil then
		self.prop:setRot(absRot)
	end
	
	if absLocX ~= nil and absLocY ~= nil then
		self.prop:setLoc(absLocX, absLocY)
	end
end
