playsketch-moai
===============

1. Project Description
-----------
This was an experimental version of the [Playsketch](https://github.com/richardcd73/playsketch) system that was developed using MOAI. It is no longer under active development.


2. Project Structure
--------------
**src/common-lua** contains the bulk of the interesting code. This is all of the application code, written in lua against the MOAI sdk.

**src/playsketch2-ios** contains the Xcode project that combines the common-lua source with the moai binaries to deploy to iPad (or iPad simulator).

See **src/common-lua/main.lua** for the application entry point.


3. Getting code & dependencies
----------
playsketch-moai depends on our fork of the MOAI project (http://getmoai.com), which can be found at [https://github.com/richardcd73/moai-dev](https://github.com/richardcd73/moai-dev)

To get the code:

1. Create a directory called **sketch**

2. Clone the playsketch-moai repo into it, from [https://github.com/richardcd73/playsketch-moai](https://github.com/richardcd73/playsketch-moai) to **sketch/playsketch-moai**

3. Clone the moai-dev repo into it, from [https://github.com/richardcd73/moai-dev](https://github.com/richardcd73/moai-dev) to **sketch/moai-dev**
	* The current version of playsketch-moai depends on [moai beta v0.95](https://github.com/moai/moai-dev/commit/b11578ad7e4d8a3bdaa28f47d127ab7cef978ded).



4. Building and Running on the Mac (for development & testing work)
---------------

1.	Install Xcode (you can get it from the Mac App Store)

2.	Launch Xcode and install the command-line tools. Under Xcode->Preferences->Downloads->Components, install the "Command Line Tools".

3.	If this is a new install of Xcode, you'll have to set up the environment to point at your build tools. Assuming you've installed Xcode from the App store:

	**> sudo xcode-select -switch /Applications/Xcode.app/Contents/Developer**

4.	Build moai-dev:

	**> cd sketch/moai-dev/xcode/osx**
	
	**> ./build.sh -c all** (Debug and Release)
	
	This will put the moai binaries in sketch/moai-dev/osx/
	
5.	To run playsketch-moai:

	**> cd sketch/playsketch-moai/src/common-lua**
	
	**> ../../../moai-dev/bin/osx/Release/moai config.lua main.lua**
	

5. Building and deploying on iPad simulator
---------------
**[Note: without a developer certificate, you can only run it in the simulator]**

1.	Install Xcode

2.	From within Xcode, ensure you have installed a version of the iOS simulator (I've been developing against 5.0). Do this under Xcode->Preferences->Downloads. It will require a (free) apple developer account.

3.	Open **sketch/playsketch-moai/src/PlaySketch2-ios/PlaySketch2.xcodeproj**

4.	On the toolbar, where you select the scheme to build, make sure you have selected **PlaySketch2 - Release** and **iPad x.x Simulator**.

5. Hit the play button to build and run. The build will take a while the first time. It should launch in the iOS simulator.
	

