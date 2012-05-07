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

	model/model.lua
	
	The interface point for ALL logic on creating/grouping objects and
	interacting with the model.
	
	addProp(prop)
	addFromTable(table)
	deleteDrawble(drawable)
	deleteAll()
	allDrawables()
	allUserTransforms()
	tableToSave()
	startUserTransformSinglePoint(propset)

--]]


model = {}

require "model/timelist"
require "model/usertransform"
require "model/drawableobject"
require "model/dependenttransform"

local all_drawables = {}
local all_user_transforms = {}

function model.addProp(prop)
	local d = model.drawableobject.newFromProp(prop)
	--todo: ensure added to layer?
	all_drawables[d] = d
end	
	
function model.addFromTable(table)
--TODO: should be analogue to tableToSave(), but this might help:
--[[
	assert(objecttable.prop and objecttable.prop.proptype and objecttable.model,
		"To restore a prop, it needs a proptype, model, and prop tables")

	if objecttable.prop.proptype == "DRAWING" then
		local o = controllers.drawing.loadSavedProp(objecttable.prop)
		o:loadSavedModel(objecttable.model)
	else
		assert(false, "attempting to load unknown object type: "..objecttable.prop.proptype)
		--todo: load other proptypes here
	end
--]]
end


function model.deleteDrawble(drawable)
	drawable:delete()
	all_drawables[drawable] = nil
end

function model.deleteAll()
	for _,d in pairs(all_drawables) do
		model.delete(d)
	end
end

function model.allDrawables()
	return all_drawables
end

function model.allUserTransforms()
	return all_user_transforms
end

function model.tableToSave()
	return all_drawables
	--TODO: might need others as well?
end

-- Responding to selection updates (main logic for building and updating transforms!)
function model.startUserTransformSinglePoint(propset)

	-- Figure out the extents of this user transform
	-- starts at either 0 or the end of the previous transform
	-- ends at either now or the start of the next transform
	local startTime = 0 --TODO!!
	local endTime = 10 --TODO!!
	
	--todo: smarter logic here. check for an existing one to add on to?
	--todo: or do it at the commit?

	local ut = model.usertransform.new(propset)
	ut:setSpan(startTime, stopTime)
	all_user_transforms[ut] = ut
	return ut
end


return model
