/* WCTypeLoader.m: Loads the type needed

   Copyright (C) 2000 Free Software Foundation, Inc.

   Author:  Nicola Pero <nicola@brainstorm.co.uk>
   Date: August 2000

   This file is part of JIGS, the GNUstep Java Interface.

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA. */

/* This class knows all the WCType concrete subclasses, and creates
   the right one for the right objective-C type. */

#include "WCBOOLType.h"
#include "WCCharType.h"
#include "WCDoubleType.h"
#include "WCIdType.h"
#include "WCFloatType.h"
#include "WCIntType.h"
#include "WCLongType.h"
#include "WCLongLongType.h"
#include "WCNSIntegerType.h"
#include "WCNSUIntegerType.h"
#include "WCCGFloatType.h"
#include "WCShortType.h"
#include "WCMorphType.h"
#include "WCObjectType.h"
#include "WCType.h"
#include "WCTypeLoader.h"
#include "WCUnsignedIntType.h"
#include "WCUnsignedLongType.h"
#include "WCUnsignedShortType.h"
#include "WCUnsignedLongLongType.h"
#include "WCVoidType.h"

/* Default morphing types.  Oh - it would be nice to have constant objects */
#define DEFAULT_MORPHTYPES_NUMBER 7

static const struct morphType
{
  NSString *objcName;
  NSString *javaName;
  NSString *jniName;
  NSString *javaArgumentType;
  NSString *java2objc;
  NSString *objc2java;
} defaultMorphTypes[DEFAULT_MORPHTYPES_NUMBER] = {
  { @"NSString *", @"String", @"jstring", @"Ljava.lang.String;",
    @"JIGSNSStringFromJstring", @"JIGSJstringFromNSString" },

  { @"NSNumber *", @"Number", @"jobject", @"Ljava.lang.Number;",
    @"GSJNI_NSNumberFromJNumber", @"GSJNI_JNumberFromNSNumber" },

  { @"NSPoint", @"NSPoint", @"jobject", @"Lgnu.gnustep.base.NSPoint;",
    @"JIGSNSPointConvertToStruct", @"JIGSNSPointConvertToJobject" },

  { @"NSSize", @"NSSize", @"jobject", @"Lgnu.gnustep.base.NSSize;",
    @"JIGSNSSizeConvertToStruct", @"JIGSNSSizeConvertToJobject" },

  { @"NSRect", @"NSRect", @"jobject", @"Lgnu.gnustep.base.NSRect;",
    @"JIGSNSRectConvertToStruct", @"JIGSNSRectConvertToJobject" },

  { @"NSRange", @"NSRange", @"jobject", @"Lgnu.gnustep.base.NSRange;",
    @"JIGSNSRangeConvertToStruct", @"JIGSNSRangeConvertToJobject" },

  { @"SEL", @"NSSelector", @"jobject", @"Lgnu.gnustep.base.NSSelector;",
    @"JIGSSELFromNSSelector", @"JIGSNSSelectorFromSEL" }

};

@implementation WCTypeLoader

/* name should already be normalized */
+ (id) typeWithObjcType: (NSString *)name
{
  id	t = nil;
  int	i;

  if ([name isEqualToString: @"void"] == YES)
    {
      t = [[WCVoidType alloc] initWithObjcType: @"void"];
    }
  else if ([name isEqualToString: @"id"] == YES)
    {
      t = [[WCIdType alloc] initWithObjcType: @"id"];
    }
  else if ([name isEqualToString: @"instancetype"] == YES)
    {
      /* For generics 'instancetype' is #defined to be an id
       */
      t = [[WCIdType alloc] initWithObjcType: @"id"];
    }
  else if ([name isEqualToString: @"NSInteger"] == YES)
    {
      t = [[WCNSIntegerType alloc] initWithObjcType: @"NSInteger"];
    }
  else if ([name isEqualToString: @"NSUInteger"] == YES)
    {
      t = [[WCNSUIntegerType alloc] initWithObjcType: @"NSUInteger"];
    }
  else if ([name isEqualToString: @"CGFloat"] == YES)
    {
      t = [[WCCGFloatType alloc] initWithObjcType: @"CGFloat"];
    }
  else if ([name isEqualToString: @"BOOL"] == YES)
    {
      t = [[WCBOOLType alloc] initWithObjcType: @"BOOL"];
    }
  else if (([name isEqualToString: @"int"] == YES)
      || ([name isEqualToString: @"signed"] == YES)
      || ([name isEqualToString: @"signed int"] == YES))
    {
      t = [[WCIntType alloc] initWithObjcType: name];
    }
  else if (([name isEqualToString: @"unsigned int"] == YES)
      || ([name isEqualToString: @"unsigned"] == YES))
    {
      t = [[WCUnsignedIntType alloc] initWithObjcType: name];
    }
  else if ([name isEqualToString: @"unsigned char"] == YES)
    {
     t = [[WCCharType alloc] initWithObjcType: name  signed: NO];
    }
  else if ([name isEqualToString: @"signed char"] == YES)
    {
      t = [[WCCharType alloc] initWithObjcType: name  signed: YES];
    }
  else if ([name isEqualToString: @"char"] == YES)
    {
#if CHAR_MIN == 0
      t = [[WCCharType alloc] initWithObjcType: name  signed: NO];
#else
      t = [[WCCharType alloc] initWithObjcType: name  signed: YES];
#endif
    }
  else if ([name isEqualToString: @"float"] == YES)
    {
       t = [[WCFloatType alloc] initWithObjcType: name];
    }
  else if ([name isEqualToString: @"double"] == YES)
    {
      t = [[WCDoubleType alloc] initWithObjcType: name];
    }
  else if ([name isEqualToString: @"unsigned short"]
	   || [name isEqualToString: @"unsigned short int"])
    {
      t = [[WCUnsignedShortType alloc] initWithObjcType: name];
    }
  else if ([name isEqualToString: @"short"]
	   || [name isEqualToString: @"short int"]
	   || [name isEqualToString: @"signed short"]
	   || [name isEqualToString: @"signed short int"])
    {
      t = [[WCShortType alloc] initWithObjcType: name];
    }
  else if ([name isEqualToString: @"long"]
	   || [name isEqualToString: @"long int"]
	   || [name isEqualToString: @"signed long"]
	   || [name isEqualToString: @"signed long int"])
    {
      t = [[WCLongType alloc] initWithObjcType: name];
    }
  else if ([name isEqualToString: @"unsigned long"]
	   || [name isEqualToString: @"unsigned long int"])
    {
      t = [[WCUnsignedLongType alloc] initWithObjcType: name];
    }
  else if ([name isEqualToString: @"long long"]
	   || [name isEqualToString: @"long long int"]
	   || [name isEqualToString: @"signed long long"]
	   || [name isEqualToString: @"signed long long int"])
    {
      t = [[WCLongLongType alloc] initWithObjcType: name];
    }
  else if ([name isEqualToString: @"unsigned long long"]
	   || [name isEqualToString: @"unsigned long long int"])
    {
      t = [[WCUnsignedLongLongType alloc] initWithObjcType: name];
    }
  else
    {
      for (i = 0; i < DEFAULT_MORPHTYPES_NUMBER; i++)
	{
	  struct morphType morph = defaultMorphTypes[i];

	  if ([name isEqualToString: morph.objcName])
	    {
	      t = [[WCMorphType alloc] initWithObjcType: name
		javaType: morph.javaName
		jniType: morph.jniName
		javaArgumentType: morph.javaArgumentType
		javaToObjcFunction: morph.java2objc
		objcToJavaFunction: morph.objc2java];
	      break;
	    }
	}
    }
  if (t == nil && [name hasSuffix: @"*"] == YES)
    {
      /* name is a wrapped objective-C class */
      t = [[WCObjectType alloc] initWithObjcType: name];
    }
  if (t == nil)
    {
      [NSException raise: NSGenericException
		  format: @"Unknown objective-C type %@", name];
    }
  return t;
}

@end


