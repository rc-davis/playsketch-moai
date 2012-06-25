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

	controllers/undo.lua

	Global controller for managing undo/redo state.
	
	- All actions that change model state should push their undo & redo state with:
		contollers.undo.addAction('name', undoFunction(), redoFunction())
	
	- Actions can be grouped (and nested) by being surrounded with: 
		controllers.undo.startGroup('name')
		controllers.undo.endGroup('name')

	- Note: To use this properly, you want to call addAction for ALL actions that modify
	  		the state of a primitive (number, or table value), and not for calls into our
	  		own code.
	
	- TODO: need to cull when the list of past actions gets too long 
	  (especially since it maintains references to so much memory!)

--]]

require "util/util"

if not controllers then controllers = {} end

controllers.undo = {}

local pastActionStack = {} 		-- actions to be 'undone'
local futureActionStack = {} 	-- actions that have been undone that can be redone
local currentGroupStack = {}	-- The stack of currently active groups, so we can nest actions
local recordUndos = true

function controllers.undo.startGroup(groupname)

	if not recordUndos then return end

	table.insert(currentGroupStack, groupname)
	table.insert(pastActionStack, { startGroup=true, name=groupname })
	futureActionStack = {} --clear out any redos sitting on the stack

end


function controllers.undo.endGroup(groupname)

	if not recordUndos then return end

	assert(groupname == currentGroupStack[#currentGroupStack], 
			"Should only be ending the top-most group")
	currentGroupStack[#currentGroupStack] = nil
	table.insert(pastActionStack, { endGroup=true, name=groupname })
	futureActionStack = {} --clear out any redos sitting on the stack

end


function controllers.undo.addAction(name, undoFunction, redoFunction)

	if not recordUndos then return end

	table.insert(pastActionStack, {	name=name,
									undoFunction=undoFunction,
									redoFunction=redoFunction } )

	futureActionStack = {} --clear out any redos sitting on the stack

end

function controllers.undo.canPerformUndo()
	return not util.tableIsEmpty(pastActionStack)
end

function controllers.undo.canPerformRedo()
	return not util.tableIsEmpty(futureActionStack)
end

function controllers.undo.performUndo()

	--disable saving undo actions
	recordUndos = false

	local seenGroups = {}
	local i = #pastActionStack
	local processedCount = 0
	
	while i > 0 and (#seenGroups > 0 or processedCount == 0) do
	
		if pastActionStack[i].endGroup then
			table.insert(seenGroups, pastActionStack[i].name)
		elseif pastActionStack[i].startGroup then
			assert(pastActionStack[i].name == seenGroups[#seenGroups], "groups should be well-nested")
			seenGroups[#seenGroups] = nil
		else
			pastActionStack[i].undoFunction()
		end
	
		table.insert(futureActionStack, pastActionStack[i])
		pastActionStack[i] = nil
		i = i - 1
		processedCount = processedCount + 1
	end
	
	--re-enable saving undo actions
	recordUndos = true

	assert(refreshAfterUndo, "Your interface file should define refreshAfterUndo() to clean up after an undo/redo")
	refreshAfterUndo(path)
	
end


function controllers.undo.performRedo()

	--disable saving undo actions
	recordUndos = false

	local seenGroups = {}
	local i = #futureActionStack
	local processedCount = 0
	
	while i > 0 and (#seenGroups > 0 or processedCount == 0) do
	
		if futureActionStack[i].startGroup then
			table.insert(seenGroups, futureActionStack[i].name)
		elseif futureActionStack[i].endGroup then
			assert(futureActionStack[i].name == seenGroups[#seenGroups], "groups should be well-nested")
			seenGroups[#seenGroups] = nil
		else
			futureActionStack[i].redoFunction()
		end
	
		table.insert(pastActionStack, futureActionStack[i])
		futureActionStack[i] = nil
		i = i - 1
		processedCount = processedCount + 1
	end
	
	--re-enable saving undo actions
	recordUndos = true

	assert(refreshAfterUndo, "Your interface file should define refreshAfterUndo() to clean up after an undo/redo")
	refreshAfterUndo(path)
end

