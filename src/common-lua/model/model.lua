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
	getTransform(time, drawablesSet)
	newInterpolatedUserTransform(drawablesSet)

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


function model.deleteDrawable(drawable)
	drawable:delete()
	all_drawables[drawable] = nil
end

function model.deleteUserTransform(usertransform)
	usertransform:delete()
	all_user_transforms[usertransform] = nil
end

function model.deleteAll()
	for _,d in pairs(all_drawables) do
		model.deleteDrawable(d)
	end
	
	for _,ut in pairs(all_user_transforms) do
		model.deleteUserTransform(d)
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


function model.getTransform(time, drawablesSet)

	assert(#drawablesSet > 0, "a transform needs to refer to at least one drawable")

	--find any transforms that contain the *exact* same set
	--todo: might want to relax this restriction?
	--pick one drawable in the set and walk up its list of transforms to look for a match

	for i = #drawablesSet[1].transforms,2,-1 do
		local transform = drawablesSet[1].transforms[i].usertransform
		
		-- skip this transform if the time span doesn't overlap
		-- or if the sets are different sizes
		if time >= transform.span.start and time <= transform.span.stop and
			#transform.drawables == #drawablesSet then

			-- compare their actual elements
			local sets_match = true
			for _,drawable in pairs(drawablesSet) do
				if not transform:appliesTo(drawable) then 
					sets_match = false
					break
				end
			end
			
			if sets_match then return transform end
		end
	end

	-- no pre-existing matches, so let's make a new one
	return model.newInterpolatedUserTransform(drawablesSet, time)

end


function model.newInterpolatedUserTransform(drawablesSet, baseTime)

	-- Figure out the extents this transform should assume
	-- Since this is an interpolated transform (rather than recorded), we need to guess
	-- at when it should start and end
	local startTime = 0
	for _,drawable in pairs(drawablesSet) do
		startTime = math.max(startTime, drawable:lastActionTimeBefore(baseTime))
	end

	--Create a new transform
	local ut = model.usertransform.new(drawablesSet, startTime, true)
	all_user_transforms[ut] = ut

	return ut
end

return model
