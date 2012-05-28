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

	controllers/disk.lua

	Manages saving and loading files from disk
	--TODO: this whole file needs to be redone for the basemodel
	
--]]

require "util/util"

controllers.disk = {}

-- pathToSaveFile(): "out.data" in the current directory, or in the docs directory on iOS
local function pathToSaveFile()
	local path = ""
	if MOAIAppIOS then
		path = MOAIAppIOS.getDirectoryInDomain(MOAIAppIOS.DOMAIN_DOCUMENTS).."/out.data"
	else
		path = "out.data"
	end	
	return path
end


-- saveToDisk():	Queries the all drawables for the values needed to reconstruct them
--					This includes propToSave (for the drawable aspects) and modelToSave.
function controllers.disk.saveToDisk()

	local objectmodels = {}
	for _,o in pairs(model.allToSave()) do
		table.insert(objectmodels, 
			{	prop=o:propToSave(),
				model=o:modelToSave() })
	end

	--Dump to disk
	io.output(pathToSaveFile(), "w")
	io.write(util.pickle.pickle(objectmodels))
	io.output():close()
end


-- loadFromDisk():	Loads out.data and rebuilds the objects using the objects controller
function controllers.disk.loadFromDisk()

	local file = io.open(pathToSaveFile(), 'r')
	if not file then return end
	
	--Load the text from disk
	local objecttables = util.pickle.unpickle(file:read("*all"))
	file:close()
	if not objecttables then return end

	--Clear any objects already there
	model.deleteAll()

	--Rebuild props and model from the file
	for _,objecttable in ipairs(objecttables) do
		model.newDrawableFromTable(objecttable)
	end
end


return controllers.disk
