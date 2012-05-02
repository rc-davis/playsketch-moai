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

	util/pickle.lua
	
	Turn a table into a string for persistence to disk:
	- pickle(table)
	- unpickle(pickled_string)
	
	based off: http://lua-users.org/wiki/TableSerialization
	
--]]

util.pickle = {}

function util.pickle.pickle(t)
	return Pickle:clone():pickle_(t)
end

Pickle = {
	clone =	function (t) 
				local nt={}
				for i, v in pairs(t) do
					nt[i]=v
				end 
				return nt 
			end 
}

function Pickle:pickle_(root)
	assert(type(root) == "table", "pickle operates on tables")

	self._tableToRef = {}
	self._refToTable = {}
	local savecount = 0
	self:ref_(root)
	local s = ""

	while table.getn(self._refToTable) > savecount do
		savecount = savecount + 1
		local t = self._refToTable[savecount]
		s = s.."{\n"
		for i, v in pairs(t) do
			s = string.format("%s[%s]=%s,\n", s, self:value_(i), self:value_(v))
		end
		s = s.."},\n"
	end

	return string.format("{%s}", s)
end


function Pickle:value_(v)
	local vtype = type(v)
	if vtype == "string" then
		return string.format("%q", v)
	elseif vtype == "number" then 
		return v
	elseif vtype == "table" then
		return "{"..self:ref_(v).."}"
	else 
		assert(false, "can't pickle :"..vtype)
	end  
end

function Pickle:ref_(t)
	local ref = self._tableToRef[t]
	if not ref then 
		assert(t ~= self, "can't pickle the pickle class")
		table.insert(self._refToTable, t)
		ref = table.getn(self._refToTable)
		self._tableToRef[t] = ref
	end
	return ref
end

function util.pickle.unpickle(s)
	assert(type(s) == "string", "can only unpickle strings")

	local gentables = loadstring("return "..s)
	local tables = gentables()

	for tnum = 1, table.getn(tables) do
		local t = tables[tnum]
		local tcopy = {}; 
		for i, v in pairs(t) do 
			tcopy[i] = v 
		end
		for i, v in pairs(tcopy) do
			local ni, nv
			if type(i) == "table" then 
				ni = tables[i[1]] 
			else 
				ni = i 
			end
			if type(v) == "table" then 
				nv = tables[v[1]] 
			else
				nv = v 
			end
	
			t[i] = nil
			t[ni] = nv
		end
	end
	return tables[1]
end

return util.pickle
