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

	basemodel/basemodel.lua
	
	TODO:describe

--]]


basemodel = {}

basemodel.motionTypes = {SCALE=1, ROTATE=2, TRANSLATE=3, VISIBILITY=4}

require "basemodel/drawable"
require "basemodel/path"
require "basemodel/timelist"
--require "basemodel/keyframe"


local allDrawables = {}
local allPaths = {}

function basemodel.allPaths()
	return allPaths
end

function basemodel.allDrawables()
	return allDrawables
end

function basemodel.addNewDrawable(prop, time, location)

	-- create the drawable (& add it to the scene graph)
	local drawable = basemodel.drawable.newFromProp(prop)
	table.insert(allDrawables, drawable)
	
	-- create a new path to contain its location
	local path = basemodel.createNewPath({drawable})
	
	-- set path to location
	path:addKeyframedMotion(time, nil, nil, location, nil, nil)
	
	-- set visibility to come on only at current time
	path:setVisibility(time, true)

	return drawable
end


function basemodel.addNewDrawables(propList, timeList, locationList)

	assert(#propList == #timeList and #propList == #locationList, 
		"addNewDrawables() requires three lists of the same length")

	local addedDrawables = {}
	for i=1,#propList do
		local newDrawable = basemodel.addNewDrawable(propList[i], timeList[i], locationList[i])
		table.insert(addedDrawables, newDrawable)
	end
	return addedDrawables
end


function basemodel.createNewPath(drawablesSet, index)

	local path = basemodel.path.newPath()
	
	if not index then index = #allPaths + 1 end
	assert(index <= #allPaths + 1, "path index must fall within the paths list")
	table.insert(allPaths, index, path)

	return path
end


--[[



- basemodel.removeDrawable(drawable) -> success
- basemodel.removeDrawables(drawableList) -> success
- basemodel.swapPathOrder(index1, index2) -> success
- basemodel.drawablesVisibleAtTime(time) -> drawableList
- basemodel.drawablesForPath(path) -> drawableList
- basemodel.pathsForDrawable(drawable) -> pathList
--]]





return basemodel
