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

	interactormodel/IM1-interactor.lua
	
	todo:description
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