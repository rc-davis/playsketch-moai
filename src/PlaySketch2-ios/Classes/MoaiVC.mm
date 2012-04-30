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

#import "MoaiVC.h"

//================================================================//
// MoaiVC
//================================================================//
@implementation MoaiVC

	//----------------------------------------------------------------//
	- ( id ) init {
	
		self = [ super init ];
		if ( self ) {
		
		}
		return self;
	}

	//----------------------------------------------------------------//
	- ( BOOL ) shouldAutorotateToInterfaceOrientation :( UIInterfaceOrientation )interfaceOrientation {		
        
            return UIInterfaceOrientationIsPortrait(interfaceOrientation);
        }
	
@end