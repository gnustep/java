/* WCLibrary.m: A library to be wrapped          -*-objc-*-

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

#include "WCClass.h"
#include "WCLibrary.h"
#include "WCHeaderParser.h"

static NSString *libraryName;
static NSString *libraryHeader;
static NSString *wrapDir;
static NSDictionary *wrappingPreferences;
static WCHeaderParser *headerParser;
static BOOL verboseOutput;

@implementation WCLibrary
+ (NSString *)libraryName
{
  return libraryName;
}

+ (NSString *)shortLibraryName
{
    if ([libraryName hasPrefix: @"lib"] == NO)
      return libraryName;
    else
      {
	return [libraryName substringFromIndex: 3];
      }
}

+ (WCHeaderParser *)headerParser
{
  return headerParser;
}

+ (NSString *)libraryHeader
{
  return libraryHeader;
}

+ (BOOL) verboseOutput
{
  return verboseOutput;
}

+ (void)initializeWithJigsFile: (NSString *)jigsFileName
	preprocessedHeaderFile: (NSString *)headerFileName
		    headerFile: (NSString *)libHeader
		 wrapDirectory: (NSString *)wrapDirectory
		   libraryName: (NSString *)libName
		 verboseOutput: (BOOL)verbOut
{
  headerParser = [WCHeaderParser newWithHeaderFile: headerFileName];
  if (headerParser == nil)
    {
      [NSException raise: @"WrapCreatorException"
		   format: @"Could not read header file %@", headerFileName];
    }

  wrappingPreferences = [NSDictionary dictionaryWithContentsOfFile: jigsFileName];
  if (wrappingPreferences == nil)
    {
      [NSException raise: @"WrapCreatorException"
		   format: @"Could not parse jigs file %@", jigsFileName];
    }
  RETAIN (wrappingPreferences);

  ASSIGN (wrapDir, wrapDirectory);
  ASSIGN (libraryName, libName);
  ASSIGN (libraryHeader, libHeader);
  verboseOutput = verbOut;
}

+ (void)outputWrappers
{
  NSAutoreleasePool *pool;
  NSArray *classes;
  NSDictionary *classInfo;
  NSString *path;
  WCClass *class;
  int i, count;
  NSMutableString *libraryInitCode;
  NSMutableString *javaFiles;
  NSMutableString *objcFiles;

  javaFiles = [NSMutableString stringWithString: @"# Automatically generated "
			       @"by JIGS Wrap Creator - do not edit !\n\n"];
  [javaFiles appendString: @"JW_FILE_LIST = "];
  objcFiles = AUTORELEASE ([javaFiles mutableCopy]);

  libraryInitCode = [NSMutableString stringWithString: @"/* Wrapper for library "];
  [libraryInitCode appendString: libraryName];
  [libraryInitCode appendString: @", generated by JIGS Wrap Creator\n"];
  [libraryInitCode appendString: @"   This file is automatically generated, "];
  [libraryInitCode appendString: @"do not edit!\n"];
  [libraryInitCode appendString: @"*/\n"];
  [libraryInitCode appendString: @"\n"];
  [libraryInitCode appendString: @"#include <Foundation/Foundation.h>\n"];
  [libraryInitCode appendString: @"#include <jni.h>\n"];
  [libraryInitCode appendString: @"#include <java/JIGS.h>\n"];
  [libraryInitCode appendString: @"\n"];
  [libraryInitCode appendString: @"JNIEXPORT jint JNICALL\n"];
  [libraryInitCode appendString: @"JNI_OnLoad (JavaVM *jvm, void *reserved)\n"];
  [libraryInitCode appendString: @"{\n"];

  classes = [wrappingPreferences objectForKey: @"classes"];
  count = [classes count];
  for (i = 0; i < count; i++)
    {
      pool = [NSAutoreleasePool new];
      classInfo = [classes objectAtIndex: i];
      class = [WCClass newWithDictionary: classInfo];
      if (verboseOutput == YES)
	{
	  printf ("Wrapping class %s\n", [[class objcName] cString]);
	}
      [class outputWrappers];

      [libraryInitCode appendString: @"  JIGSRegisterJavaProxyClass "]; 
      [libraryInitCode appendFormat: @"(JIGSJNIEnv (), @\"%@\", @\"%@\");\n",
		       [class javaName], [class objcName]];
      // FIXME: Platform independent way of doing this
      path = [[class javaName] stringByReplacingString: @"." withString: @"/"];
      [javaFiles appendFormat: @" \\\n  %@.java", path];
      [objcFiles appendFormat: @" \\\n  %@.m", [class objcName]];
      [pool release];
    }

  [libraryInitCode appendString: @"  return JNI_VERSION_1_2;\n"];
  [libraryInitCode appendString: @"}\n\n/* END OF FILE */\n"];
  /* Write libraryName-init.m */
  path = [NSString stringWithFormat: @"%@/Objc/%@-init.m", wrapDir, libraryName];
  if (verboseOutput == YES)
    {
      printf ("Writing objc library initialization file\n");
    }
  if ([libraryInitCode writeToFile: path  atomically: YES] == NO)
    {
      NSLog (@"Error - could not write to file %@", path);
    }
  [objcFiles appendFormat: @"\\\n  %@-init.m", libraryName];

  [objcFiles appendString: @"\n\n# END OF FILE\n"];
  [javaFiles appendString: @"\n\n# END OF FILE\n"];

  /* Write Java/GNUmakefile.files, Objc/GNUmakefile.files */
  path = [NSString stringWithFormat: @"%@/Java/GNUmakefile.files", wrapDir];
  if (verboseOutput == YES)
    {
      printf ("Writing list of java files\n");
    }
  if ([javaFiles writeToFile: path  atomically: YES] == NO)
    {
      NSLog (@"Error - could not write to file %@", path);
    }
  path = [NSString stringWithFormat: @"%@/Objc/GNUmakefile.files", wrapDir];
  if (verboseOutput == YES)
    {
      printf ("Writing list of objc files\n");
    }
  if ([objcFiles writeToFile: path  atomically: YES] == NO)
    {
      NSLog (@"Error - could not write to file %@", path);
    }
}

+ (NSString *)javaMethodForObjcMethod: (NSString *)methodName
{
  NSDictionary* methodNameMapping;

  methodNameMapping = [wrappingPreferences objectForKey: @"method name mapping"]; 

  return [methodNameMapping objectForKey: methodName];
}

+ (void) createJavaDirectoryForClass: (NSString *)fullJavaClassName
{
  NSString *javaPath;
  NSArray *components;
  int i, count;
  NSFileManager *fm;

  fm = [NSFileManager defaultManager];

  // FIXME: Platform independent way of doing this
  javaPath = [fullJavaClassName stringByReplacingString: @"." withString: @"/"];

  components = [javaPath pathComponents];
  javaPath = [NSString stringWithFormat: @"%@/Java/", wrapDir];
  count = [components count];

  for (i = 0; i < count; i++)
    {
      if ([fm fileExistsAtPath: javaPath] == NO)
	{
	  if ([fm createDirectoryAtPath: javaPath attributes: nil] == NO)
	    {
	      [NSException raise: @"WrapCreatorException"
			   format: @"Could not create directory %@", javaPath];
	    }
	}
      javaPath = [javaPath stringByAppendingPathComponent: 
			     [components objectAtIndex: i]];
    }
}

+ (NSString *) javaWrapperFileForClass: (NSString *)fullJavaClassName
{
  NSString *javaPath;

  // FIXME: Platform independent way of doing this
  javaPath = [fullJavaClassName stringByReplacingString: @"." withString: @"/"];
  
  return [NSString stringWithFormat: @"%@/Java/%@.java", wrapDir, javaPath];
}

+ (NSString *) objcWrapperFileForClass: (NSString *)objcClassName
{
  return [NSString stringWithFormat: @"%@/Objc/%@.m", wrapDir, objcClassName];
}

@end

