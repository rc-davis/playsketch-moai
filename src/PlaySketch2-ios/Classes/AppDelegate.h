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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "RefPtr.h"

@class MoaiVC;
@class MoaiView;

//================================================================//
// AppDelegate
//================================================================//
@interface AppDelegate : NSObject < UIApplicationDelegate > {
@private

	IBOutlet MoaiView*	mMoaiView;
	IBOutlet UIWindow*	mWindow;	
	IBOutlet MoaiVC*	mMoaiVC;
}

@end
