/* JIGSMapper.m - Mapping tables from/to java
   Copyright (C) 2000 Free Software Foundation, Inc.
   
   Written by:  Nicola Pero <nicola@brainstorm.co.uk>
   Date: July 2000
   
   This file is part of the GNUstep Java Interface Library.

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

#include "JIGSMapper.h"
#include "java.lang.Object.h"
#include "GSJNI.h"
#include "JIGSProxy.h"
#include "NSJavaVirtualMachine.h"
#include <objc/Object.h>

/***
 *** Table mapping real objc objects to their java proxies 
 ***/
static NSMapTable* _JIGSProxiedObjcMap = NULL; 
static objc_mutex_t _JIGSProxiedObjcMapLock = NULL;

static inline jobject _JIGSMapperGetProxyFromProxiedObjc (id objc)
{
  jobject java;
  
  objc_mutex_lock (_JIGSProxiedObjcMapLock);
  java = NSMapGet (_JIGSProxiedObjcMap, objc);
  objc_mutex_unlock (_JIGSProxiedObjcMapLock);
  return java;
}

void _JIGSMapperAddJavaProxy (JNIEnv *env, id objc, jobject java)
{
  jobject weak_java;
  
  weak_java = (*env)->NewWeakGlobalRef (env, java);
  if (weak_java == NULL)
    {
      return;
    }  

  objc_mutex_lock (_JIGSProxiedObjcMapLock);
  NSMapInsert (_JIGSProxiedObjcMap, objc, weak_java);
  objc_mutex_unlock (_JIGSProxiedObjcMapLock);
}

void _JIGSMapperRemoveJavaProxy (JNIEnv *env, id objc)
{
  jobject weak_java;

  objc_mutex_lock (_JIGSProxiedObjcMapLock);

  weak_java = NSMapGet (_JIGSProxiedObjcMap, objc);
  (*env)->DeleteWeakGlobalRef (env, weak_java);

  NSMapRemove (_JIGSProxiedObjcMap, objc);

  objc_mutex_unlock (_JIGSProxiedObjcMapLock);
}

/***
 *** Table mapping real java objects to their objc proxies 
 ***/
static NSMapTable* _JIGSProxiedJavaMap = NULL; 
static objc_mutex_t _JIGSProxiedJavaMapLock = NULL;

/* To compare two java references, we need to use JNI's
   IsSameObject. */
BOOL _JIGSProxyJavaIsEqual (NSMapTable *table, const void *a, const void *b)
{
  JNIEnv *env = JIGSJNIEnv ();

  return (*env)->IsSameObject (env, (jobject)a, (jobject)b);
}

/* Hashcodes to speed up comparison */
unsigned int _JIGSProxyJavaHash (NSMapTable *table, const void *a)
{
  static jmethodID jid = NULL; // Cached
  JNIEnv *env = JIGSJNIEnv ();
  jint javaHashCode;

  if (jid == NULL)
    {
      jclass java_lang_Object = NULL;

      if((*env)->PushLocalFrame (env, 1) < 0)
	{
	  return 0;
	}

      java_lang_Object = (*env)->FindClass (env, "java/lang/Object");
      if (java_lang_Object == NULL)
	{
	  (*env)->PopLocalFrame (env, NULL);
	  return 0;
	}

      jid = (*env)->GetMethodID (env, java_lang_Object, "hashCode", "()I");
      if (jid == NULL)
	{
	  (*env)->PopLocalFrame (env, NULL);
	  return 0;
	}
    }
  
  // Get object's hashCode
  javaHashCode = (*env)->CallIntMethod (env, (jobject)a, jid);

  // We encode the jint hashcode into an 'unsigned int' hashcode.
  // While doing this, we mix it up because java hashcodes
  // are not good in the implementation I tried.
  // If you change this, be careful to check for performance.
  // Bad hash codes can make lookup in the table slow by an order 
  // of magnitude or more.
  {
    int i;
    unsigned int hash = 0;
    union divide 
      {
	jint number;
	jboolean parts[4]; // NB: jboolean is defined as unsigned 8bit
      };
    
    for (i = 0; i < 4; i++)
      {
	hash = (hash << 5) + hash + ((union divide)javaHashCode).parts[i];
      }
    return hash;
  }
}

static NSMapTableKeyCallBacks JIGSJavaReferenceMapKeyCallBacks;

static inline id _JIGSMapperGetProxyFromProxiedJava (jobject java)
{
  id objc;
  
  objc_mutex_lock (_JIGSProxiedJavaMapLock);
  objc = NSMapGet (_JIGSProxiedJavaMap, java);
  objc_mutex_unlock (_JIGSProxiedJavaMapLock);
  return objc;
}

void _JIGSMapperAddObjcProxy (JNIEnv *env, jobject java, id objc)
{
  objc_mutex_lock (_JIGSProxiedJavaMapLock);
  NSMapInsert (_JIGSProxiedJavaMap, java, objc);
  objc_mutex_unlock (_JIGSProxiedJavaMapLock);
}

void _JIGSMapperRemoveObjcProxy (JNIEnv* env, jobject java)
{
  objc_mutex_lock (_JIGSProxiedJavaMapLock);
  NSMapRemove (_JIGSProxiedJavaMap, java);
  objc_mutex_unlock (_JIGSProxiedJavaMapLock);
}

/***
 *** Table mapping GNUstep classes to the corresponding java proxy classes 
 ***/

/* 
 * It maps a Class to a jclass reference, as in a pointer to the
 * NSObject class mapped to a jclass reference to gnu/gnustep/base/NSObject 
 */
static NSMapTable* _JIGSProxiedObjcClassMap = NULL;
static objc_mutex_t _JIGSProxiedObjcClassMapLock = NULL;

/*
 * The same map in reverse, mapping a jclass reference to
 * gnu/gnustep/base/NSObject to a pointer to the NSObject class.
 * Protected by the same lock.
 */

static NSMapTable* _JIGSProxiedObjcClassReverseMap = NULL;

/* We only insert in the table, never remove */
void JIGSRegisterJavaProxyClass (JNIEnv *env, NSString *fullJavaClassName, 
				 NSString *objcClassName)
{
  jclass javaClass;
  Class objcClass;
  NSAutoreleasePool *pool = [NSAutoreleasePool new]; 

  fullJavaClassName = GSJNI_ConvertJavaClassNameToJNI (fullJavaClassName);
  javaClass = GSJNI_NewClassCache (env, [fullJavaClassName cString]);
  if (javaClass == NULL)
    {
      NSLog (@"Could not find java proxy class %@ for class %@", 
	     fullJavaClassName, objcClassName);
      RELEASE (pool);
      return;
    }
  objcClass = NSClassFromString (objcClassName);
  if (objcClass == Nil)
    {
      NSLog (@"Could not find objc class %@ proxied by java class %@", 
	     objcClassName, fullJavaClassName);
      RELEASE (pool);
      return;
    }

  objc_mutex_lock (_JIGSProxiedObjcClassMapLock);
  NSMapInsert (_JIGSProxiedObjcClassMap, objcClass, javaClass);
  NSMapInsert (_JIGSProxiedObjcClassReverseMap, javaClass, objcClass);
  objc_mutex_unlock (_JIGSProxiedObjcClassMapLock);

  RELEASE (pool);
}

/* Please call the following only in the top-most local reference frame. 
   Otherwise, DeleteLocalRef will do nothing and for very deep class trees 
   you could get an out-of-memory error because of excessive local refs 
   creation.  

   Also, beware that this function call wants a local reference as 
   argument, and it destroys it during processing ! 
*/
static inline Class _JIGSFirstJavaProxySuperClass (JNIEnv *env, 
						   jclass inClass)
{
  Class outClass;

  objc_mutex_lock (_JIGSProxiedObjcClassMapLock); 

  /* Keep an eye on leakages of local references */
  if ((*env)->EnsureLocalCapacity (env, 2) < 0)
    {
      /* Exception thrown */
      return Nil;
    }
  
  while (1)
    {
      outClass = NSMapGet (_JIGSProxiedObjcClassReverseMap, inClass);

      if (outClass != NULL)
	{
	  break;
	}
      else
	{
	  jclass superClass = (*env)->GetSuperclass (env, inClass);
	  if (superClass == NULL)
	    {
	      // Root Class - no exception thrown
	      NSLog (@"Could not find a real objective-C class");
	      outClass = Nil;
	      break;
	    }

	  (*env)->DeleteLocalRef (env, inClass);
	  inClass = superClass;
	}
    }

  (*env)->DeleteLocalRef (env, inClass);
  objc_mutex_unlock (_JIGSProxiedObjcClassMapLock);

  return outClass;
}

Class JIGSClassFromThisClass (JNIEnv *env, jclass class)
{

  /* The new local ref we create is destroyed by the function call itself */
  return _JIGSFirstJavaProxySuperClass (env, (*env)->NewLocalRef (env, class));
}

Class _JIGSAllocClassForThis (JNIEnv *env, jobject this)
{
  Class class;
  jclass objectClass;

  if ((*env)->EnsureLocalCapacity (env, 1) < 0)
    {
      /* Exception thrown */
      return Nil;
    }
  /* The following local ref is destroyed by _JIGSFirstJavaProxySuperclass */
  objectClass  = (*env)->GetObjectClass (env, this);

  class = _JIGSFirstJavaProxySuperClass (env, objectClass);

  return class;
}

NSString *_JIGSLongJavaClassNameForObjcClassName (JNIEnv *env, 
						  NSString *className)
{
  jclass result = NULL;

  objc_mutex_lock (_JIGSProxiedObjcClassMapLock); 
  result = NSMapGet (_JIGSProxiedObjcClassMap, NSClassFromString (className));
  objc_mutex_unlock (_JIGSProxiedObjcClassMapLock); 

  if (result == NULL)
    return nil;

  return GSJNI_NSStringFromJClass (env, result);
}

// Cache used in the lookup functions
static jclass gnu_gnustep_base_NSObject = NULL;
static jfieldID fidRealObject = NULL;
static jclass java_lang_String = NULL;
static jclass java_lang_Boolean = NULL;
static jclass java_lang_Byte = NULL;
static jclass java_lang_Float = NULL;
static jclass java_lang_Double = NULL;
static jclass java_lang_Integer = NULL;
static jclass java_lang_Short = NULL;
static jclass java_lang_Long = NULL;
static Class java_lang_Object = Nil;
static Class nsstring = Nil;
static Class nsnumber = Nil;

/***
 *** Functions
 ***/

void _JIGSMapperInitialize (JNIEnv *env)
{
  if (gnu_gnustep_base_NSObject != NULL)
    return;

  // Create the maps 
  _JIGSProxiedObjcMap = NSCreateMapTable (NSNonOwnedPointerMapKeyCallBacks, 
					  NSNonOwnedPointerMapValueCallBacks, 
					  20);
  _JIGSProxiedObjcMapLock = objc_mutex_allocate ();
  
  JIGSJavaReferenceMapKeyCallBacks = NSNonOwnedPointerMapKeyCallBacks;
  JIGSJavaReferenceMapKeyCallBacks.isEqual = _JIGSProxyJavaIsEqual;
  JIGSJavaReferenceMapKeyCallBacks.hash = _JIGSProxyJavaHash;
  
  _JIGSProxiedJavaMap = NSCreateMapTable (JIGSJavaReferenceMapKeyCallBacks, 
					  NSNonOwnedPointerMapValueCallBacks, 
					  20);
  _JIGSProxiedJavaMapLock = objc_mutex_allocate ();
  
  _JIGSProxiedObjcClassMap 
    = NSCreateMapTable (NSNonOwnedPointerMapKeyCallBacks, 
			NSNonOwnedPointerMapValueCallBacks, 
			20);
  _JIGSProxiedObjcClassReverseMap 
    = NSCreateMapTable (JIGSJavaReferenceMapKeyCallBacks,
			NSNonOwnedPointerMapValueCallBacks, 
			20);
  _JIGSProxiedObjcClassMapLock = objc_mutex_allocate ();
  
  gnu_gnustep_base_NSObject = GSJNI_NewClassCache 
    (env, "gnu/gnustep/base/NSObject");
  
  if (gnu_gnustep_base_NSObject == NULL)
    {
      NSLog (@"Could not get a reference to gnu/gnustep/base/NSObject");
      // Exception thrown
      return;
    }

  JIGSRegisterJavaProxyClass (env, @"gnu.gnustep.base.NSObject", @"NSObject");
  
  fidRealObject = (*env)->GetFieldID (env, gnu_gnustep_base_NSObject, 
				      "realObject", "J");
  if (fidRealObject == 0) 
    {
      NSLog (@"Could not get fid of realObject");
      // Exception thrown	  
      return;
    }
  
  java_lang_Object = NSClassFromString (@"java.lang.Object");

#define NEW_CLASS_CACHE(VAR,CLASS_NAME) \
VAR = GSJNI_NewClassCache (env, #CLASS_NAME);           \
if (VAR == NULL)                                        \
  {                                                     \
    NSLog (@"Could not get reference to " @#CLASS_NAME);\
    return;                                            \
  }

  NEW_CLASS_CACHE (java_lang_String, java/lang/String);
  NEW_CLASS_CACHE (java_lang_Boolean, java/lang/Boolean);
  NEW_CLASS_CACHE (java_lang_Byte, java/lang/Byte);
  NEW_CLASS_CACHE (java_lang_Float, java/lang/Float);
  NEW_CLASS_CACHE (java_lang_Double, java/lang/Double);
  NEW_CLASS_CACHE (java_lang_Integer, java/lang/Integer);
  NEW_CLASS_CACHE (java_lang_Short, java/lang/Short);
  NEW_CLASS_CACHE (java_lang_Long, java/lang/Long);
  
  nsstring = NSClassFromString (@"NSString");
  nsnumber = NSClassFromString (@"NSNumber");
}

/*
 * Gets the best proxy class for objcClass. 
 * This is the java proxy class for that class, if it exists; 
 * or the java proxy class of the superclass, if it exists; 
 * or the java proxy class of the supersuperclas, if it exists; 
 * etc.
 * 
 * Return NULL if the class could not be found.
 * 
 */
static inline jclass _JIGSMapperGetBestJavaProxyClass (Class objcClass)
{
  jclass result = NULL;
  
  objc_mutex_lock (_JIGSProxiedObjcClassMapLock); 
  while (1)
    {
      result = NSMapGet (_JIGSProxiedObjcClassMap, objcClass);
      if (result != NULL) 
	{
	  break;
	}

      objcClass = class_get_super_class (objcClass);
      if (objcClass == Nil)
	{
	  result = NULL;
	  break;
	}  
    }
  objc_mutex_unlock (_JIGSProxiedObjcClassMapLock);
  return result;
}

id JIGSCreateNewObjcProxy (JNIEnv *env, jobject java)
{
  NSString *className;
  id objc;
  Class proxyClass;
  jobject java_global_ref;

  className = GSJNI_NSStringFromClassOfObject (env, java);

  // A. Create the class for the objc proxy if needed
  JIGSRegisterJavaClass (env, className);
  
  // B. Create the objc proxy of that class
  proxyClass = NSClassFromString (className);
  if (className == nil)
    {
      // FIXME - what to do here ?
      NSLog (@"Could not create proxy class");
      return nil;
    }
  objc = AUTORELEASE ([proxyClass alloc]);

  // C. Set the pointer of the proxy to the real java object
  java_global_ref = (*env)->NewGlobalRef (env, java);
  if (java_global_ref == NULL)
    {
      // Exception Thrown
      return nil;
    }

  ((_java_lang_Object *)objc)->realObject = java_global_ref;

  // D. Insert the (real object, proxy object) in the table
  _JIGSMapperAddObjcProxy (env, java_global_ref, objc);

  // E. Return it
  return objc;
}

jobject JIGSCreateNewJavaProxy (JNIEnv *env, id object)
{
  Class objectClass;
  jclass javaClass;
  jobject newProxy;

  objectClass = [object class];
  javaClass = _JIGSMapperGetBestJavaProxyClass (objectClass);
  
  if (javaClass == NULL)
    {
      // This should never happen. 
      [NSException raise: @"JIGSMapperException"
		   format: @"Could not find a suitable proxy for class %@", 
		   objectClass];
    }

  newProxy = (*env)->AllocObject (env, javaClass);
  
  if (newProxy == NULL)
    {
      // Oh oh - something big went wrong - do something
      return NULL;
    }
  
  (*env)->SetLongField (env, newProxy, fidRealObject, 
			JIGS_ID_TO_JLONG (object));

  RETAIN (object);

  _JIGSMapperAddJavaProxy (env, object, newProxy);

  return newProxy;
}

// NB: This method could return a global (for objects which are in map
// tables) or a local (eg for strings) reference; in any case, you are
// not responsible for freeing the reference so you should not worry.
jobject JIGSJobjectFromId (JNIEnv *env, id object)
{
  // Return object
  jobject ret;

  // nil
  if (object == nil)
    return NULL;
  
  // java.lang.Object
  if ([object isKindOfClass: java_lang_Object])
    {
      return ((_java_lang_Object *)object)->realObject;
    }
  
  // NSString 
  if ([object isKindOfClass: nsstring])
    {
      return GSJNI_JStringFromNSString (env, object);
    }

  // NSNumber
  if ([object isKindOfClass: nsnumber])
    {
      return GSJNI_JNumberFromNSNumber (env, object);
    }
  
  // NSException perhaps ?
  
  // Something else - check if it already proxied
  ret = _JIGSMapperGetProxyFromProxiedObjc (object);
  if (ret != NULL)
    {
      return ret;
    }

  return JIGSCreateNewJavaProxy (env, object);
}

id JIGSIdFromJobject (JNIEnv *env, jobject object)
{
  // Return object
  id ret;

  // NULL
  if (object == NULL)
    {
      return nil;
    }

  // gnu.gnustep.NSObject
  if ((*env)->IsInstanceOf (env, object, gnu_gnustep_base_NSObject) == YES)
    {
      return JIGS_JLONG_TO_ID((*env)->GetLongField (env, object, 
						    fidRealObject));
    }  

  // FIXME - how slow is going to be the following class examination session
  
  // java.lang.String
  if ((*env)->IsInstanceOf (env, object, java_lang_String) == YES)
    {
      return GSJNI_NSStringFromJString (env, object);
    }

  // java.lang.Boolean - this is safely morphed as a NSNumber
  // containing a boolean comes back as a java.lang.Boolean.
  if ((*env)->IsInstanceOf (env, object, java_lang_Boolean) == YES)
    {
      return GSJNI_NSNumberFromJBoolean (env, object);
    }

  // java.lang.Byte
  if ((*env)->IsInstanceOf (env, object, java_lang_Byte) == YES)
    {
      return GSJNI_NSNumberFromJByte (env, object);
    }

  // java.lang.Character - this is better not morphed, otherwise if
  // you put a java.lang.Character in an NSArray, you could get a
  // java.lang.Integer when you get it back, and they are objects of
  // completely different classes!

  // java.lang.Double
  if ((*env)->IsInstanceOf (env, object, java_lang_Double) == YES)
    {
      return GSJNI_NSNumberFromJDouble (env, object);
    }

  // java.lang.Float
  if ((*env)->IsInstanceOf (env, object, java_lang_Float) == YES)
    {
      return GSJNI_NSNumberFromJFloat (env, object);
    }

  // java.lang.Integer
  if ((*env)->IsInstanceOf (env, object, java_lang_Integer) == YES)
    {
      return GSJNI_NSNumberFromJInteger (env, object);
    }

  // java.lang.Long
  if ((*env)->IsInstanceOf (env, object, java_lang_Long) == YES)
    {
      return GSJNI_NSNumberFromJLong (env, object);
    }

  // java.lang.Short
  if ((*env)->IsInstanceOf (env, object, java_lang_Short) == YES)
    {
      return GSJNI_NSNumberFromJShort (env, object);
    }

  // NB: We do *not* morph arbitrary java.lang.Number which could be
  // of classes we don't know how to properly morph, such as like
  // BigDecimal or BigInteger or other custom defined classes

  // Something else - check if it is already proxied
  ret = _JIGSMapperGetProxyFromProxiedJava (object);
  if (ret != nil)
    {
      return ret;
    }

  // Otherwise, create a proxy
  return JIGSCreateNewObjcProxy (env, object);
}

jstring JIGSJstringFromNSString (JNIEnv *env, NSString *string)
{
  if (string == nil)
    {
      return NULL;
    }
  else
    {
      return GSJNI_JStringFromNSString (env, string);
    }
}

NSString *JIGSNSStringFromJstring (JNIEnv *env, jstring string)
{
  if (string == NULL)
    {
      return nil;
    }
  else
    {
      return GSJNI_NSStringFromJString (env, string);
    }
}

jbyteArray JIGSJbyteArrayFromNSData (JNIEnv *env, NSData *data)
{
  if (data == nil)
    {
      return NULL;
    }
  else
    {
      return GSJNI_jbyteArrayFromNSData (env, data);
    }
}

NSData *JIGSNSDataFromJbyteArray (JNIEnv *env, jbyteArray bytes)
{
  if (bytes == NULL)
    {
      return nil;
    }
  else
    {
      return GSJNI_NSDataFromJbyteArray (env, bytes);
    }
}

NSData *JIGSInitNSDataFromJbyteArray (JNIEnv *env, NSData *data, 
				      jbyteArray bytes)
{
  if (bytes == NULL)
    {
      return nil;
    }
  else
    {
      return GSJNI_initNSDataFromJbyteArray (env, data, bytes);
    }
}

/* These functions managing jobjectArray can't be in GSJNI because they 
   need to map objects */
jobjectArray JIGSJobjectArrayFromNSArray (JNIEnv *env, NSArray *array)
{
  if (array == nil)
    {
      return NULL;
    }
  else
    {
      unsigned i, length;
      id *gnustepObjects;
      jobjectArray javaArray;
      static jclass Object_class = NULL;
      
      if (Object_class == NULL)
	{
	  Object_class = GSJNI_NewClassCache (env, "java/lang/Object");
	  if (Object_class == NULL)
	    {
	      return NULL;
	    }
	}

      length = [array count];
      gnustepObjects = malloc (sizeof (id) * length);
      if (gnustepObjects == NULL)
	{
	  return NULL;
	}
      [array getObjects: gnustepObjects];
      
      javaArray = (*env)->NewObjectArray (env, length, Object_class, NULL);
      if (javaArray == NULL)
	{
	  /* OutOfMemory exception thrown */
	  return NULL;
	}
      
      for (i = 0; i < length; i++)
	{
	  jobject object;

	  object = JIGSJobjectFromId (env, gnustepObjects[i]);
	  (*env)->SetObjectArrayElement (env, javaArray, i, object);
	}

      free (gnustepObjects);
      
      return javaArray;
    }
}

NSArray *JIGSInitNSArrayFromJobjectArray (JNIEnv *env, NSArray *array, 
					  jobjectArray objects)
{
  if (array == NULL)
    {
      return nil;
    }
  else
    {
      NSArray *returnArray;
      unsigned i, length;
      id *gnustepObjects;

      length = (*env)->GetArrayLength (env, objects);
      
      gnustepObjects = malloc (sizeof (id) * length);
      if (gnustepObjects == NULL)
	{
	  return nil;
	}

      /* Get the objects and convert them to GNUstep objects */
      for (i = 0; i < length; i++)
	{
	  jobject object;
	  
	  object = (*env)->GetObjectArrayElement (env, objects, i);
	  gnustepObjects[i] = JIGSIdFromJobject (env, object);
	}

      returnArray = [array initWithObjects: gnustepObjects  count: length];
      free (gnustepObjects);

      return returnArray;
    }  
}

NSArray *JIGSNSArrayFromJobjectArray (JNIEnv *env, jobjectArray objects)
{
  return AUTORELEASE (JIGSInitNSArrayFromJobjectArray (env, [NSArray alloc],
						       objects));
}

id JIGSIdFromThis (JNIEnv *env, jobject this)
{
  return JIGS_JLONG_TO_ID((*env)->GetLongField (env, this, fidRealObject));
}

