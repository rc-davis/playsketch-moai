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

	util/objects.lua

	This defines OO concepts like classes and inheritance
	We are following the approach suggested at: http://lua-users.org/wiki/InheritanceTutorial	

	To create a new class type called "NewClass" which inherits from the baseClass, do:
	
	NewClass = util.objects.defineType("NewClass", util.objects.BaseClass)
	
	
--]]

util.objects = {}

function util.objects.defineType(className, superClass)

	assert(className ~= nil, "Every class needs a name")

	local new_class = {}
	local class_mt = { __index = new_class } -- define the metatable for the class

	function new_class:create()
		local newinst = {}
		setmetatable( newinst, class_mt )
		return newinst
	end

	if superClass ~= nil then
		setmetatable( new_class, { __index = superClass } )
    end

	-- Return the class object of the instance
	function new_class:class()
		return new_class
	end

	-- Return the string name for the class of the instance
	function new_class:className()
		return className
	end

	-- Return the super class object of the instance
	function new_class:superClass()
		return superClass
	end

	-- Return true if the caller is an instance of theClass
	function new_class:isa( theClass )
		local b_isa = false
		local cur_class = new_class
		while ( nil ~= cur_class ) and ( false == b_isa ) do
			if cur_class == theClass then
				b_isa = true
			else
				cur_class = cur_class:superClass()
			end
		end
		return b_isa
	end

	return new_class
end

-- Create our baseclass type
util.objects.BaseClass = util.objects.defineType("BaseClass", nil)

return util.objects