#
#  Copyright (C) 2000 Free Software Foundation, Inc.
#
#  Author:  Nicola Pero <nicola@brainstorm.co.uk>
#  Date: September 2000
#   
#  This file is part of GNUstep.
#   
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#   
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#   
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA. */

#
# Please make sure you type `. ./GNUstep-Java.sh' before attempting 
# to compile this makefile!
#

include $(GNUSTEP_MAKEFILES)/common.make

TOOL_NAME = JavaTest
JavaTest_OBJC_FILES = main.m

ADDITIONAL_OBJCFLAGS += -Wall

include $(GNUSTEP_MAKEFILES)/jigs.make
include $(GNUSTEP_MAKEFILES)/tool.make


check:: all
	./obj/JavaTest

