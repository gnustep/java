/* WCPrimitiveType.h                                          -*-objc-*-

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

#ifndef __WCPrimitiveType_h_GNUSTEP_WrapCreator_INCLUDE
#define __WCPrimitiveType_h_GNUSTEP_WrapCreator_INCLUDE

#include "WCType.h"

@interface WCPrimitiveType : WCType
{
  NSString *javaType;
  NSString *jniType;
  NSString *javaArgumentType;
}
@end

#endif /* __WCPrimitiveType_h_GNUSTEP_WrapCreator_INCLUDE */
