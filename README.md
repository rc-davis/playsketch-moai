playsketch2
===========

1. Project Description
-----------
[project description]


2. Project Structure
--------------
**src/common-lua** contains the bulk of the interesting code. This is all of the application code, written in lua against the MOAI sdk.

See **src/common-lua/main.lua** for the application entry point.


3. Getting code & dependencies
----------
Playsketch2 depends on our fork of the MOAI project (http://getmoai.com), which can be found at [https://github.com/richardcd73/moai-dev](https://github.com/richardcd73/moai-dev)

To get the code:

1. Create a directory called **sketch**

2. Clone the playsketch2 repo into it, from [https://github.com/richardcd73/playsketch2](https://github.com/richardcd73/playsketch2) to **sketch/playsketch2**

3. Clone the moai-dev repo into it, from [https://github.com/richardcd73/moai-dev](https://github.com/richardcd73/moai-dev) to **sketch/moai-dev**


4. Building and Running on the Mac (for development & testing work)
---------------

1.	Install xcode (you can get it from the Mac App Store)

2.	If this is a new install of Xcode, you'll have to set up the environment to point at your build tools. Assuming you've installed Xcode from the App store:

	**> sudo xcode-select -switch /Applications/Xcode.app/Contents/Developer**

3.	Build moai-dev:

	**> cd sketch/moai-dev/xcode/osx**
	
	**> ./build.sh -c all** (Debug and Release)
	
	This will put the moai binaries in sketch/moai-dev/osx/
	
4.	To run playsketch2:

	**> cd sketch/playsketch2/src/common-lua**
	
	**> ../../../moai-dev/bin/osx/Release/moai config.lua main.lua**
	
