//================================================================//
/*
 Copyright 2012 Singapore Management University
 This Source Code Form is subject to the terms of the
 Mozilla Public License, v. 2.0. If a copy of the MPL was
 not distributed with this file, You can obtain one at
 http://mozilla.org/MPL/2.0/.
 
 Based off sample code at: http://github.com/moai/moai-dev/
 */
//================================================================//

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>

//extern "C" {
//	#include <lua.h>
//	#include <lauxlib.h>
//	#include <lualib.h>
//}

#import <aku/AKU-iphone.h>
#import <aku/AKU-luaext.h>
#import <aku/AKU-untz.h>
#import <aku/AKU-audiosampler.h>
#import <lua-headers/moai_lua.h>

#import "MoaiView.h"
#import "ParticlePresets.h"

namespace MoaiInputDeviceID {
	enum {
		DEVICE,
		TOTAL,
	};
}

namespace MoaiInputDeviceSensorID {
	enum {
		TOUCH,
		TOTAL,
	};
}

//================================================================//
// MoaiView ()
//================================================================//
@interface MoaiView ()

	//----------------------------------------------------------------//
	-( void )	handleTouches		:( NSSet* )touches :( BOOL )down;
	-( void )	onUpdateAnim;
	-( void )	startAnimation;
	-( void )	stopAnimation;

@end

//================================================================//
// MoaiView
//================================================================//
@implementation MoaiView

	//----------------------------------------------------------------//
	-( void ) dealloc {
	
		AKUDeleteContext ( mContext );
		
		[ super dealloc ];
	}

	//----------------------------------------------------------------//
	-( void ) drawView {
						
		[ self beginDrawing ];
		
		AKUSetContext ( mAku );
        AKUSetViewSize ( mWidth, mHeight );
		AKURender ();

		[ self endDrawing ];
	}
	
	//----------------------------------------------------------------//
	-( void ) handleTouches :( NSSet* )touches :( BOOL )down {
	
		for ( UITouch* touch in touches ) {
			
			CGPoint p = [ touch locationInView:self ];
			
			AKUEnqueueTouchEvent (
				MoaiInputDeviceID::DEVICE,
				MoaiInputDeviceSensorID::TOUCH,
				( int )touch, // use the address of the touch as a unique id
				down,
				p.x * [[ UIScreen mainScreen ] scale ],
				p.y * [[ UIScreen mainScreen ] scale ]
			);
		}
	}
	
	//----------------------------------------------------------------//
	-( id )init {
		
		self = [ super init ];
		if ( self ) {
		}
		return self;
	}

	//----------------------------------------------------------------//
	-( id ) initWithCoder:( NSCoder* )encoder {
	
		self = [ super initWithCoder:encoder ];
		if ( self ) {
		}
		return self;
	}
	
	//----------------------------------------------------------------//
	-( id ) initWithFrame :( CGRect )frame {
	
		self = [ super initWithFrame:frame ];
		if ( self ) {
		}
		return self;
	}
	
	//----------------------------------------------------------------//
	-( void ) moaiInit :( UIApplication* )application {
	
		mAku = AKUCreateContext ();
		AKUSetUserdata ( self );
		
		AKUExtLoadLuasql ();
		AKUExtLoadLuacurl ();
		AKUExtLoadLuacrypto ();
		AKUExtLoadLuasocket ();
		
		AKUUntzInit ();
		AKUAudioSamplerInit ();
        
		AKUSetInputConfigurationName ( "iPhone" );

		AKUReserveInputDevices			( MoaiInputDeviceID::TOTAL );
		AKUSetInputDevice				( MoaiInputDeviceID::DEVICE, "device" );
		
		AKUReserveInputDeviceSensors	( MoaiInputDeviceID::DEVICE, MoaiInputDeviceSensorID::TOTAL );
		AKUSetInputDeviceTouch			( MoaiInputDeviceID::DEVICE, MoaiInputDeviceSensorID::TOUCH,		"touch" );
		
		CGRect screenRect = [[ UIScreen mainScreen ] bounds ];
		CGFloat scale = [[ UIScreen mainScreen ] scale ];
		CGFloat screenWidth = screenRect.size.width * scale;
		CGFloat screenHeight = screenRect.size.height * scale;
		
		AKUSetScreenSize ( screenWidth, screenHeight );
		
		AKUSetDefaultFrameBuffer ( mFramebuffer );
		AKUDetectGfxContext ();
		
		mAnimInterval = 1; // 1 for 60fps, 2 for 30fps
		
		
		UIAccelerometer* accel = [ UIAccelerometer sharedAccelerometer ];
		accel.delegate = self;
		accel.updateInterval = mAnimInterval;
		
		// init aku
		AKUIphoneInit ( application );
		AKURunBytecode ( moai_lua, moai_lua_SIZE );
		
		// add in the particle presets
		ParticlePresets ();
	}
	
	//----------------------------------------------------------------//
	-( void ) onUpdateAnim {
		
		[ self openContext ];
		AKUSetContext ( mAku );
		AKUUpdate ();
		
		[ self drawView ];
	}
		
	
	//----------------------------------------------------------------//
	-( void ) pause :( BOOL )paused {
	
		if ( paused ) {
			AKUPause ( YES );
			[ self stopAnimation ];
		}
		else {
			[ self startAnimation ];
			AKUPause ( NO );
		}
	}
	
	//----------------------------------------------------------------//
	-( void ) run :( NSString* )filename {
	
		AKUSetContext ( mAku );
		AKURunScript ([ filename UTF8String ]);
	}
	
	//----------------------------------------------------------------//
	-( void ) startAnimation {
		
		if ( !mDisplayLink ) {
			CADisplayLink* aDisplayLink = [[ UIScreen mainScreen ] displayLinkWithTarget:self selector:@selector( onUpdateAnim )];
			[ aDisplayLink setFrameInterval:mAnimInterval ];
			[ aDisplayLink addToRunLoop:[ NSRunLoop currentRunLoop ] forMode:NSDefaultRunLoopMode ];
			mDisplayLink = aDisplayLink;
		}
	}

	//----------------------------------------------------------------//
	-( void ) stopAnimation {
		
        [ mDisplayLink invalidate ];
        mDisplayLink = nil;
	}
	
	//----------------------------------------------------------------//
	-( void )touchesBegan:( NSSet* )touches withEvent:( UIEvent* )event {
		( void )event;
		
		[ self handleTouches :touches :YES ];
	}
	
	//----------------------------------------------------------------//
	-( void )touchesCancelled:( NSSet* )touches withEvent:( UIEvent* )event {
		( void )touches;
		( void )event;
		
		AKUEnqueueTouchEventCancel ( MoaiInputDeviceID::DEVICE, MoaiInputDeviceSensorID::TOUCH );
	}
	
	//----------------------------------------------------------------//
	-( void )touchesEnded:( NSSet* )touches withEvent:( UIEvent* )event {
		( void )event;
		
		[ self handleTouches :touches :NO ];
	}

	//----------------------------------------------------------------//
	-( void )touchesMoved:( NSSet* )touches withEvent:( UIEvent* )event {
		( void )event;
		
		[ self handleTouches :touches :YES ];
	}
	
@end