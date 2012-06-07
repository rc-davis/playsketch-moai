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

	widgets/widgets.lua

	Our set of reusable widgets. 
	They all get created on their own MOAILayer2D, created by calling widgets.init()

	- widgets/buttons.lua: A set of push, toggle, and slider buttons.
	- widgets/manipulator.lua: The ksketch SRT widget.
--]]

widgets = {}

function widgets.init(viewport)

	-- Create a new layer
	widgets.layer = MOAILayer2D.new ()
	widgets.layer:setViewport ( viewport )
	MOAISim.pushRenderPass ( widgets.layer )

	--Import all of the parts of this package once the layer has been created
	require "widgets/buttons"
	require "widgets/manipulator"
	require "widgets/keyframes"
	require "widgets/modifierButton"
	require "widgets/slider"
	require "widgets/textButton"
	require "widgets/textButtonList"
end

return widgets
