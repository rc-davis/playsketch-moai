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

	basemodel/timelist.lua

	The most basic data structure for holding the animation steps for an object in time.
	It creates a list of nodes with values associated with a time.
	When looking up the value at a point in time, it returns the node immediately <= to the requested time

	-- TODO: REPLACE OUR streams LISTS with some btrees with iterator, for faster lookup

--]]


basemodel.timelist = {}

basemodel.timelist.NEGINFINITY = -1e99

local TimeList = {}

function basemodel.timelist.new(defaultValue)
	return util.clone(TimeList):init(defaultValue)
end

function basemodel.timelist.newFromTable(t)
	local l = basemodel.timelist.new()
	l:loadFromTable(t)
	return l
end


----- TimeList methods -----

function TimeList:init(defaultValue)
	self.class = "TimeList"
	self.firstNode = basemodel.timelistNode.new(basemodel.timelist.NEGINFINITY, defaultValue)
	self.listSize = 0
	self.defaultValue = defaultValue
	return self
end

function TimeList:size()
	return self.listSize
end


-- getNodeForTime(time):	Returns the node with the time <= 'time'
function TimeList:getNodeForTime(time)
	local toReturn = nil
	local it = self:begin()
	while not it:done() and it:current():time() <= time do
		toReturn = it:current()
		it:next()
	end
	return toReturn
end


-- makeNodeForTime(time):	Creates and returns a new node at the right place in the linked list
--							its value is set to self.defaultValue
--							precedingNode is optional and used as a hint
function TimeList:makeNodeForTime(time, precedingNode)

	if not precedingNode then 
		precedingNode = self:getNodeForTime(time)
	end
	
	assert(precedingNode ~= nil, "shouldn't be making a node without a preceding node")

	if precedingNode:time() == time then
		return precedingNode
	else
		assert(precedingNode:time() < time and 
				(not precedingNode:next() or precedingNode:next():time() > time), 
				"inserted nodes must maintain a strict ordering!")
		local newNode = basemodel.timelistNode.new(time, util.clone(self.defaultValue), precedingNode, precedingNode:next())
		if precedingNode:next() then precedingNode:next():setPrevious(newNode) end
		precedingNode:setNext(newNode)
		self.listSize = self.listSize + 1
		controllers.undo.addAction(	"Increment List Size",
								function() self.listSize = self.listSize - 1 end,
								function() self.listSize = self.listSize + 1 end )

		return newNode
	end
end

function TimeList:deleteNode(node)

	assert(node ~= self.firstNode, "Shouldn't delete root node")

	node:previous():setNext(node:next())
	if node:next() then 
		node:next():setPrevious(node:previous())
	end
	--TODO: We are assuming that node actually belongs to self!
	self.listSize = self.listSize - 1
	controllers.undo.addAction(	"Decrement List Size",
							function() self.listSize = self.listSize + 1 end,
							function() self.listSize = self.listSize - 1 end )

	
end

-- setValueForTime(time, value): Sets 'value' at 'time', replacing a pre-existing value at the EXACT same time
-- precedingNode is an optional hint
function TimeList:setValueForTime(time, value, precedingNode)
	local node = self:makeNodeForTime(time, precedingNode)
	assert(node ~= nil, "must retrieve a non-nil node when making a new node")
	node:setValue(value)
	return node
end

-- getValueForTime(time): returns the value from the node immediately <= 'time'
function TimeList:getValueForTime(time)
	local node = self:getNodeForTime(time)
	assert(node ~= nil, "must retrieve a non-nil node for any given time")
	return node:value()
end


-- getInterpolatedValueForTime(time): interpolates the value between the nodes around 'time' 
function TimeList:getInterpolatedValueForTime(time)
	local node_before = self:getNodeForTime(time)
	assert(node_before ~= nil, "must retrieve a non-nil node for any given time")
	local node_after = node_before:next()
	
	local valueBefore = node_before:value()
	local timeBefore = node_before:time()
	local valueAfter = node_after and node_after:value() or nil
	local timeAfter = node_after and node_after:time() or nil
	
	return util.interpolate(time, 
							valueBefore, timeBefore,
							valueAfter, timeAfter)
end

-- Get an iterator for the TimeList
-- use:	local it = list:begin()
--		while not it:done() do
--			local node = it:current()
--			it:next()
--		end
function TimeList:begin()
	
	local it = {}
	it._current = self.firstNode

	function it:current()
		return it._current
	end

	function it:next()
		if it._current ~= nil then
			it._current = it._current:next()
		end
	end
	
	function it:done()
		return it._current == nil
	end

	return it
end		

-- dump(): For debugging, dump the lists for o.
function TimeList:dump()
	print("====DUMP: ", o)
	local it = self:begin()
	while not it:done() do
		print("time:",it:current():time())
		print("\tvalue:")
		print_deep(it:current():value(), 2)
		print("\tmetadata:")
		print_deep(it:current():metadata(), 2)
		it:next()
	end
	print("====/DUMP")	
end


function TimeList:tableToSave()
	--TODO
end


function TimeList:loadFromTable(table)
	--TODO
end


return basemodel.timelist
