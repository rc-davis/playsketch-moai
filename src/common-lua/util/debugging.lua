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


-- Override the the default assert to give a stacktrace and better message
assert = function (stmt, msg)
	if not stmt then
		print("\n\n!!ASSERTION FAILED:", msg)
		print(debug.traceback())
		os.exit()
	end
end


-- print_deep(): a print function that recurses into tables
function print_deep(t, depth, followed)
	if followed == nil then followed = {} end
	depth = depth or 0
	local prefix = "" for i=1,depth,1 do prefix = prefix .. "  " end

	if type(t) == "table" then
		print(prefix.."{")
		for k,v in pairs(t) do
			print(prefix..k.."=")
			if followed[v] == nil then
				followed[v] = true
				print_deep(v, depth+1, followed)
			else print(v) end
		end
		print(prefix.."}")		
	else
		print(prefix..type(t)..":\t"..tostring(t))
	end
end

return util.debugging