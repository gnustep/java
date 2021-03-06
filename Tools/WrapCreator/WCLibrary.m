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
#include "WCCustomType.h"

static NSString *libraryName;
static NSString *libraryHeader;
static NSString *topLevelDirectory;
static NSString *wrapDir;
static NSDictionary *wrappingPreferences;
static WCHeaderParser *headerParser;
static BOOL verboseOutput;
static BOOL outputJavadoc;
static NSMutableArray *classList;

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

+ (BOOL) outputJavadoc
{
  return outputJavadoc;
}

+ (void) initializeWithOptions: (NSDictionary *)options
{
  int i, count;
  NSArray *classes;
  NSAutoreleasePool *pool;
  NSDictionary *customTypes;
  NSEnumerator *enumerator;
  NSString *customType;
  NSString *primitiveType;
  NSArray *enumTypes;
  NSString *enumType;
  NSDictionary *classInfo;

  /* Options */
  NSString *jigsFileName;
  NSString *headerFileName;

  /* Set these options first so that WCHeaderParser can access them */
  [(NSValue *)[options objectForKey: @"VerboseOutput"] 
	      getValue: &verboseOutput];
  [(NSValue *)[options objectForKey: @"OutputJavadoc"] 
	      getValue: &outputJavadoc];

  headerFileName = [options objectForKey: @"PreprocessedHeaderFileName"];

  headerParser = [WCHeaderParser newWithHeaderFile: headerFileName];
  if (headerParser == nil)
    {
      [NSException raise: @"WrapCreatorException"
		   format: @"Could not read header file %@", headerFileName];
    }

  jigsFileName = [options objectForKey: @"JigsFile"];
  wrappingPreferences = [NSDictionary dictionaryWithContentsOfFile: jigsFileName];
  if (wrappingPreferences == nil)
    {
      [NSException raise: @"WrapCreatorException"
		   format: @"Could not parse jigs file %@", jigsFileName];
    }
  RETAIN (wrappingPreferences);
  ASSIGN (topLevelDirectory, [jigsFileName stringByDeletingLastPathComponent]);

  ASSIGN (libraryHeader, [options objectForKey: @"HeaderFile"]);  
  ASSIGN (wrapDir, [options objectForKey: @"WrapDirectory"]);
  ASSIGN (libraryName, [options objectForKey: @"LibraryName"]);

  /* Load custom types */
  pool = [NSAutoreleasePool new];
  customTypes = [wrappingPreferences objectForKey: @"types"];
  
  enumerator = [customTypes keyEnumerator];
  
  while (1)
    {
      customType = [enumerator nextObject];
      if (customType == nil)
	{
	  break;
	}
      primitiveType = [customTypes objectForKey: customType];
      
      if (verboseOutput == YES)
	{
	  printf ("Loading type mapping %s --> %s\n", 
		  [customType cString], [primitiveType cString]);
	}
      /* Allocating the type registers it in WCType's internal table
	 so it will be returned next time WCType's is asked for this
	 type. */
      [[WCCustomType alloc] initWithObjcType: customType
			    primitiveType: primitiveType];
    }
  [pool release];

  /* Load enumeration types */
  pool = [NSAutoreleasePool new];
  
  /* First, enumerations found by the header parser in the header file */
  enumTypes = [headerParser enumerationTypes];
  /* Then, user specified enumerations - not sure this is useful - I
     suppose you use it if the parser misses some enums */
  enumTypes = [enumTypes arrayByAddingObjectsFromArray:
			   [wrappingPreferences 
			     objectForKey: @"enumerations"]];
  
  enumerator = [enumTypes objectEnumerator];
  
  while (1)
    {
      enumType = [enumerator nextObject];
      if (enumType == nil)
	{
	  break;
	}
      if (verboseOutput == YES)
	{
	  printf ("Loading enumeration %s\n", [enumType cString]);
	}
      /* Allocating the type registers it in WCType's internal table
	 so it will be returned next time WCType's is asked for this
	 type. */
      [[WCCustomType alloc] initWithObjcType: enumType
			    primitiveType: @"int"];
    }
  [pool release];

  /* Load class list */
  pool = [NSAutoreleasePool new];
  classList = RETAIN ([NSMutableArray new]);
  classes = [wrappingPreferences objectForKey: @"classes"];
  count = [classes count];
  for (i = 0; i < count; i++)
    {
      WCClass *class; 
      
      classInfo = [classes objectAtIndex: i];
      class = [WCClass newWithDictionary: classInfo];
      if (verboseOutput == YES)
	{
	  printf ("Loading class %s\n", [[class objcName] cString]);
	}
      [classList addObject: class];
    }
  [pool release];
}

+ (void)outputWrappers
{
  NSAutoreleasePool *pool;
  NSString *path;
  WCClass *class;
  int i, count;
  NSMutableString *libraryInitCode;
  NSMutableString *selectorMapping;
  NSMutableString *javaFiles;
  NSMutableString *objcFiles;

  javaFiles = [NSMutableString stringWithString: @"# Automatically generated "
			       @"by JIGS Wrap Creator - do not edit !\n\n"];
  [javaFiles appendString: @"JW_FILE_LIST = "];
  objcFiles = AUTORELEASE ([javaFiles mutableCopy]);

  selectorMapping = [NSMutableString stringWithString: @"/* List of selector mappings for library "];
  [selectorMapping appendString: libraryName];
  [selectorMapping appendString: @"\n   generated by JIGS Wrap Creator\n"];
  [selectorMapping appendString: @"   This file is automatically generated, "];
  [selectorMapping appendString: @"do not edit!\n"];
  [selectorMapping appendString: @"*/\n"];
  [selectorMapping appendString: @"\n"];

  libraryInitCode = [NSMutableString stringWithString: @"/* Wrapper for library "];
  [libraryInitCode appendString: libraryName];
  [libraryInitCode appendString: @", generated by JIGS Wrap Creator\n"];
  [libraryInitCode appendString: @"   This file is automatically generated, "];
  [libraryInitCode appendString: @"do not edit!\n"];
  [libraryInitCode appendString: @"*/\n"];
  [libraryInitCode appendString: @"\n"];
  [libraryInitCode appendString: @"#include <Foundation/Foundation.h>\n"];
  [libraryInitCode appendString: @"#include <jni.h>\n"];
  [libraryInitCode appendString: @"#include <GNUstepJava/JIGS.h>\n"];
  [libraryInitCode appendString: @"\n"];
  [libraryInitCode appendFormat: @"#include \"%@-map.c\"\n", libraryName];  
  [libraryInitCode appendString: @"\n"];
  [libraryInitCode appendString: @"JNIEXPORT jint JNICALL\n"];
  [libraryInitCode appendString: @"JNI_OnLoad (JavaVM *jvm, void *reserved)\n"];
  [libraryInitCode appendString: @"{\n"];
  [libraryInitCode appendString: @"  JIGS_ONLOAD_ENTER;\n"];

  /* Wrap classes */
  count = [classList count];
  for (i = 0; i < count; i++)
    {
      pool = [NSAutoreleasePool new];
      class = [classList objectAtIndex: i];
      if (verboseOutput == YES)
	{
	  printf ("Wrapping class %s\n", [[class objcName] cString]);
	  /*	  printf ("Wrapping class %s, %s\n",
		  [[class objcName] cString],
		  [[class description] cString]); */
	}
      [class outputWrappers];

      [libraryInitCode appendString: @"  JIGSRegisterJavaProxyClass "]; 
      [libraryInitCode appendFormat: @"(JIGSJNIEnv (), @\"%@\", @\"%@\");\n",
		       [class javaName], [class objcName]];
      [libraryInitCode appendString: @"  JIGSRegisterJavaProxySelectors "]; 
      [libraryInitCode appendFormat: @"(JIGSJNIEnv (), %@_count, %@_map_list);\n",
		       [class objcName], [class objcName]];
      // FIXME: Platform independent way of doing this
      path = [[class javaName] stringByReplacingString: @"." withString: @"/"];
      [javaFiles appendFormat: @" \\\n  %@.java", path];
      [objcFiles appendFormat: @" \\\n  %@.m", [class objcName]];
      [selectorMapping appendFormat: @"#include \"%@-map.c\"\n", 
		       [class objcName]];
      [pool release];
    }

  [libraryInitCode appendString: @"  JIGS_ONLOAD_EXIT;\n"];
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
  path = [NSString stringWithFormat: @"%@/Objc/%@-map.c", wrapDir, 
		   libraryName];
  if (verboseOutput == YES)
    {
      printf ("Writing selector mapping table\n");
    }
  if ([selectorMapping writeToFile: path  atomically: YES] == NO)
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

+ (NSArray *)prerequisiteLibraries
{
  NSArray *libraries;

  libraries = [wrappingPreferences objectForKey: @"prerequisite libraries"]; 

  return libraries;
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

+ (NSString *) selectorMapFileForClass: (NSString *)objcClassName
{
  return [NSString stringWithFormat: @"%@/Objc/%@-map.c", wrapDir, 
		   objcClassName];
}

+ (NSString *) fileWithRelativePath: (NSString *)relativePath
{
  NSString *path;

  path = [topLevelDirectory stringByAppendingPathComponent: relativePath];
  return [NSString stringWithContentsOfFile: path];
}

+ (NSString *) javaClassNameForObjcClassName: (NSString*)objcClassName
{
  int i, count;
  NSDictionary *hints;
  NSEnumerator *enumerator;
  NSString *objcHintName;

  /* First look in the list of classes we are wrapping */
  count = [classList count];
  
  for (i = 0; i < count; i++)
    {
      WCClass *class = [classList objectAtIndex: i];

      if ([[class objcName] isEqualToString: objcClassName])
	{
	  return [class javaName];
	}
    }

  /* No luck - see if the programmer has given us an explicit hint on
     this. */
  hints = [wrappingPreferences objectForKey: @"class name mapping hints"];
  
  enumerator = [hints keyEnumerator];
  
  while (1)
    {
      objcHintName = [enumerator nextObject];
      if (objcHintName == nil)
	{
	  break;
	}
      if ([objcHintName isEqualToString: objcClassName])
	{
	  return [hints objectForKey: objcHintName];
	}
    }

  /* No luck - try using some very common hardcoded cases */
  if ([objcClassName isEqualToString: @"NSArray"])
    {
      return @"gnu.gnustep.base.NSArray";
    }
  else if ([objcClassName isEqualToString: @"NSData"])
    {
      return @"gnu.gnustep.base.NSData";
    }
  else if ([objcClassName isEqualToString: @"NSDictionary"])
    {
      return @"gnu.gnustep.base.NSDictionary";
    }
  else if ([objcClassName isEqualToString: @"NSMutableArray"])
    {
      return @"gnu.gnustep.base.NSMutableArray";
    }
  else if ([objcClassName isEqualToString: @"NSMutableData"])
    {
      return @"gnu.gnustep.base.NSMutableData";
    }
  else if ([objcClassName isEqualToString: @"NSMutableDictionary"])
    {
      return @"gnu.gnustep.base.NSMutableDictionary";
    }
  else if ([objcClassName isEqualToString: @"NSNotification"])
    {
      return @"gnu.gnustep.base.NSNotification";
    }
  
  /* Return nil.  This is usually harmless - but unrecoverably bad for
     an overloaded native method. */
  return nil;
}
@end

