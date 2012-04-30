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

#import "RefPtr.h"

class USTexture;

//================================================================//
// OpenGLView
//================================================================//
@interface OpenGLView : UIView {
@protected

	GLint mWidth;
	GLint mHeight;
    
	RefPtr < EAGLContext > mContext;
    
	GLuint mFramebuffer;
	GLuint mRenderbuffer;
	GLuint mDepthbuffer;
}

	PROPERTY_READONLY ( GLuint, framebuffer );

	//----------------------------------------------------------------//
	-( void )	beginDrawing;
	-( void )	closeContext;
	-( void )	drawView;
	-( void )	endDrawing;
	-( void )	openContext;

@end
