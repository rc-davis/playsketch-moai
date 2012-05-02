--[[
	--------------
	Copyright 2012 Singapore Management University
	 
	This Source Code Form is subject to the terms of the
	Mozilla Public License, v. 2.0. If a copy of the MPL was
	not distributed with this file, You can obtain one at
	http://mozilla.org/MPL/2.0/.
	--------------
--]]

util.debugging = {}


-- recursivePrint(): a print function that recurses into tables
function util.debugging.recursivePrint(t, depth)
	depth = depth or 0
	local prefix = "" for i=1,depth,1 do prefix = prefix .. "  " end

	if type(t) == "table" then
		print(prefix.."{")
		for k,v in pairs(t) do
			print(prefix..k.."=")
			util.debugging.recursivePrint(v, depth+1)
		end
		print(prefix.."}")		
	else
		print(prefix..type(t)..tostring(t))
	end
end

return util.debugging