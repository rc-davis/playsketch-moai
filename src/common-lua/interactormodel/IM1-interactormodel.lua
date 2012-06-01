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

	interactormodel/IM1-interactormodel.lua
	
	IM1 is for testing/experimenting purposes and evaluating the interface with the base model.
	This should perform ALL of the interactions with the base model.
	See: https://github.com/richardcd73/playsketch2/wiki/Interactor-Model-1-Spec
	
	
--]]


interactormodel = {}

function interactormodel.newDrawableCreated(drawable, location, time)
end

function interactormodel.newSelection(drawableSet, time)
end

function interactormodel.recordingStarts(time)
end

function interactormodel.recordingUpdate(time, data)
end

function interactormodel.recordingFinished(time)
end

function interactormodel.updateKeyframe(time, data)
end

function interactormodel.updateVisibility(time, newValue)
end



return interactormodel