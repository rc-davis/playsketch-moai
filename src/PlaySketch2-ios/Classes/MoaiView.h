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


#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <aku/AKU.h>

#import "OpenGLView.h"
#import "RefPtr.h"

@class LocationObserver;

//================================================================//
// MoaiView
//================================================================//
@interface MoaiView : OpenGLView < UIAccelerometerDelegate > {
@private
	
	AKUContextID					mAku;
	NSTimeInterval					mAnimInterval;
    RefPtr < CADisplayLink >		mDisplayLink;
	RefPtr < LocationObserver >		mLocationObserver;
}

	//----------------------------------------------------------------//
	-( void )	moaiInit	:( UIApplication* )application;
	-( void )	pause		:( BOOL )paused;
	-( void )	run			:( NSString* )filename;
	
@end
