/* NSPropertyListSerialization.h -*-objc-*-
   Copyright (C) 2000 Free Software Foundation, Inc.

   Written by: Nicola Pero <n.pero@mi.flashnet.it>
   Date: October 2000

   This file is part of JIGS, the GNUstep Java Interface.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
  */

#ifndef _JIGS_PROPERTY_LIST_SERIALIZATION_H
#define _JIGS_PROPERTY_LIST_SERIALIZATION_H

#include <Foundation/Foundation.h>

@interface NSPropertyListSerialization : NSObject

+ (id) propertyListFromString: (NSString *)aString;

+ (NSString *) stringFromPropertyList: (id)anObject;

+ (NSData *) dataFromPropertyList: (id)anObject;

+ (id) propertyListFromData: (NSData *)aData;

@end

#endif /* _JIGS_PROPERTY_LIST_SERIALIZATION_H */
