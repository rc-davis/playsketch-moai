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
	
	Uses saveRoot() and dumpValue() to recursively write the points to file
	"<KNOWN_TABLE>" sentinels are used to deal with circular references.
	
--]]

--require "serialize"

controllers.disk = {}


-- dumpValue(): Writes the value of the object to the open file.
--				If o is a table, it will only write it to disk if it isn't in knownTables
local function dumpValue(o, knownTables)
	if type(o) == "number" then io.write(o)
	elseif type(o) == "string" then io.write( string.format("%q", o))
	elseif type(o) == "table" then	
		--check if o is in known tables and return a sentinel if so
		if knownTables[o] ~= nil then
			io.write("<KNOWN_TABLE>:",knownTables[o])
		else
		--otherwise, recurse and dump it out
			knownTables.count = knownTables.count +1
			knownTables[o] = knownTables.count
	
			io.write("{\n")
			for i,v in pairs(o) do
				io.write("[")
				dumpValue(i, knownTables)
				io.write("]=")
				dumpValue(v, knownTables)
				io.write(",\n")
			end
			io.write("},\n")
		end
	else assert(false, "can't pack up "..o)
	end
end


-- saveRoot():	dumps the entire contents of the table o to provided path
local function saveRoot(o, path)
	io.output("out.data", "w")
	local knownTables = {count=0}
	dumpValue(o, knownTables)
	io.output():close()
end


-- saveToDisk():	Queries the model.all_objects for the values needed to reconstruct them
--					This includes propToSave (for the drawable aspects) and modelToSave.
function controllers.disk.saveToDisk()

	local modelstrings = {}
	for _,o in pairs(model.all_objects) do
		modelstrings[o] = {}
		modelstrings[o]['prop'] = o:propToSave()
		modelstrings[o]['model'] = o:modelToSave()
	end

	--Dump modelstrings
	saveRoot(modelstrings, "out.data")
end

return controllers.disk
