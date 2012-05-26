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
--require "basemodel/timelist"
--require "basemodel/keyframe"


local allDrawables = {}
local allPaths = {}

function basemodel.allPaths()
	return allPaths
end

function basemodel.allDrawables()
	return allDrawables
end

function basemodel.addNewDrawable(drawable, time, location)

	-- add to the scene
	
	-- create new path
	
	-- set path to location
	
	-- set visibility


end


function basemodel.addNewDrawables(drawableList, timeList, locationList)

	assert(#drawableList == #timeList and #drawableList == #locationList, 
		"addNewDrawables() requires three lists of the same length")

	local addedDrawables = {}
	for i=1,#drawableList do
		local newDrawable = basemodel.addNewDrawable(drawablesList[i], timeList[i], locationList[i])
		table.insert(addedDrawables, newDrawable)
	end
	return addedDrawables
end


--[[



- basemodel.removeDrawable(drawable) -> success
- basemodel.removeDrawables(drawableList) -> success
- basemodel.movePathBeforePathAtIndex(path, index) -> new index
- basemodel.movePathToTop(path) -> new index
- basemodel.createNewPath(index, drawablesSet) -> path
- basemodel.drawablesVisibleAtTime(time) -> drawableList
- basemodel.drawablesForPath(path) -> drawableList
- basemodel.pathsForDrawable(drawable) -> pathList
--]]





return basemodel
