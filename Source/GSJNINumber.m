/* GSJNINumber.m - Conversion between ObjC and Java number objects -*-objc-*-
   Copyright (C) 2001 Free Software Foundation, Inc.
   
   Written by:  Nicola Pero <n.pero@mi.flashnet.it>
   Date: May 2001
   
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

#include "GSJNINumber.h"
#include "GSJNICache.h"

/* Our little cache of classes.  Initialized by _GSJNI_ClassCacheInit () */

static jclass byteClass = NULL;
static jclass shortClass = NULL;
static jclass intClass = NULL;
static jclass longClass = NULL;
static jclass floatClass = NULL;
static jclass doubleClass = NULL;

static void _GSJNI_ClassCacheInit (JNIEnv *env)
{
  if (byteClass != NULL)
    {
      return;
    }
  
#define NEW_CLASS_CACHE(VAR,CLASS_NAME) \
VAR = GSJNI_NewClassCache (env, #CLASS_NAME);           \
if (VAR == NULL)                                        \
  {                                                     \
    NSLog (@"Could not get reference to " @#CLASS_NAME);\
    return;                                            \
  }

  NEW_CLASS_CACHE (byteClass, java/lang/Byte);  
  NEW_CLASS_CACHE (floatClass, java/lang/Float);  
  NEW_CLASS_CACHE (doubleClass, java/lang/Double);  
  NEW_CLASS_CACHE (intClass, java/lang/Integer);  
  NEW_CLASS_CACHE (shortClass, java/lang/Short);  
  NEW_CLASS_CACHE (longClass, java/lang/Long);  
}


#define _JIGS_check_null(variable) if (variable == NULL) return nil;

static NSNumber *GSJNI_NSNumberFromJByte (JNIEnv *env, jobject object)
{
  jmethodID jid;
  jclass objectClass;
  jbyte value;

  /* Object might belong to a subclass, so we can't cache the class or
     jmethodID */
  objectClass = (*env)->GetObjectClass (env, object);
  jid = (*env)->GetMethodID (env, objectClass, "byteValue", "()B");
  _JIGS_check_null (jid);
  
  value = (*env)->CallByteMethod (env, object, jid);
  
  if ((*env)->ExceptionCheck (env))
    {
      return nil;
    }
  
  /* `signed' implied */
  return [NSNumber numberWithChar: value];
}

static NSNumber *GSJNI_NSNumberFromJDouble (JNIEnv *env, jobject object)
{
  jmethodID jid;
  jclass objectClass;
  jdouble value;

  objectClass = (*env)->GetObjectClass (env, object);
  jid = (*env)->GetMethodID (env, objectClass, "doubleValue", "()D");
  _JIGS_check_null (jid);
  
  value = (*env)->CallDoubleMethod (env, object, jid);
  
  if ((*env)->ExceptionCheck (env))
    {
      return nil;
    }
  
  /* we need 64 bits ... FIXME: check on the doc if a C double always
     has at least 64 bits ! */
  return [NSNumber numberWithDouble: value];
}

static NSNumber *GSJNI_NSNumberFromJFloat (JNIEnv *env, jobject object)
{
  jmethodID jid;
  jclass objectClass;
  jfloat value;

  objectClass = (*env)->GetObjectClass (env, object);
  jid = (*env)->GetMethodID (env, objectClass, "floatValue", "()F");
  _JIGS_check_null (jid);
  
  value = (*env)->CallFloatMethod (env, object, jid);
  
  if ((*env)->ExceptionCheck (env))
    {
      return nil;
    }
  
  /* we need 32 bits ... FIXME: check on the doc if a C float always
     has at least 32 bits! */
  return [NSNumber numberWithFloat: value];
}

static NSNumber *GSJNI_NSNumberFromJInteger (JNIEnv *env, jobject object)
{
  jmethodID jid;
  jclass objectClass;
  jint value;

  objectClass = (*env)->GetObjectClass (env, object);
  jid = (*env)->GetMethodID (env, objectClass, "intValue", "()I");
  _JIGS_check_null (jid);
  
  value = (*env)->CallIntMethod (env, object, jid);
  
  if ((*env)->ExceptionCheck (env))
    {
      return nil;
    }
  
  /* a signed 32 bits */
  return [NSNumber numberWithLong: value];
}

static NSNumber *GSJNI_NSNumberFromJLong (JNIEnv *env, jobject object)
{
  jmethodID jid;
  jclass objectClass;
  jlong value;

  objectClass = (*env)->GetObjectClass (env, object);
  jid = (*env)->GetMethodID (env, objectClass, "longValue", "()J");
  _JIGS_check_null (jid);
  
  value = (*env)->CallLongMethod (env, object, jid);
  
  if ((*env)->ExceptionCheck (env))
    {
      return nil;
    }
  
  /* a signed 64 bits */
  return [NSNumber numberWithLongLong: value];
}

static NSNumber *GSJNI_NSNumberFromJShort (JNIEnv *env, jobject object)
{
  jmethodID jid;
  jclass objectClass;
  jshort value;

  objectClass = (*env)->GetObjectClass (env, object);
  jid = (*env)->GetMethodID (env, objectClass, "shortValue", "()S");
  _JIGS_check_null (jid);
  
  value = (*env)->CallShortMethod (env, object, jid);
  
  if ((*env)->ExceptionCheck (env))
    {
      return nil;
    }
  
  /* a signed 16 bits */
  return [NSNumber numberWithShort: value];
}




NSNumber *GSJNI_NSNumberFromJNumber (JNIEnv *env, jobject object)
{
  if (byteClass == NULL)
    {
      _GSJNI_ClassCacheInit (env);
    }
  

  // java.lang.Byte
  if ((*env)->IsInstanceOf (env, object, byteClass) == YES)
    {
      return GSJNI_NSNumberFromJByte (env, object);
    }
  
  // java.lang.Double
  if ((*env)->IsInstanceOf (env, object, doubleClass) == YES)
    {
      return GSJNI_NSNumberFromJDouble (env, object);
    }
  
  // java.lang.Float
  if ((*env)->IsInstanceOf (env, object, floatClass) == YES)
    {
      return GSJNI_NSNumberFromJFloat (env, object);
    }
  
  // java.lang.Integer
  if ((*env)->IsInstanceOf (env, object, intClass) == YES)
    {
      return GSJNI_NSNumberFromJInteger (env, object);
    }
  
  // java.lang.Long
  if ((*env)->IsInstanceOf (env, object, longClass) == YES)
    {
      return GSJNI_NSNumberFromJLong (env, object);
    }
  
  // java.lang.Short
  if ((*env)->IsInstanceOf (env, object, shortClass) == YES)
    {
      return GSJNI_NSNumberFromJShort (env, object);
    }

  // Else, treat is as a Double
  return GSJNI_NSNumberFromJDouble (env, object);
}



/* This is a little cache for the constructors for the java
   classes. */
static jmethodID byteId = NULL;
static jmethodID shortId = NULL;
static jmethodID intId = NULL;
static jmethodID longId = NULL;
static jmethodID floatId = NULL;
static jmethodID doubleId = NULL;

jobject GSJNI_JNumberFromNSNumber (JNIEnv *env, NSNumber *object)
{ 
  const char *type = [object objCType];
  char jtype;
  jvalue value;
  jobject result = NULL;

  if (byteClass == NULL)
    {
      _GSJNI_ClassCacheInit (env);
    }
  
  /* Read the number into value; store the type (in Java convention)
     into jtype */

  switch (*type)
    {
    case _C_CHR:
      {
#if CHAR_MIN == 0 
	/* non signed chars - but don't use 'z' or 'c' */	
	value.s = [object charValue];
	jtype = 's';
	break;
#else 
	/* signed chars */
	value.b = [object charValue];
	jtype = 'b';
	break;
#endif
      }

    case _C_UCHR:
      {
	/* non signed chars */	
	value.s = [object charValue];
	jtype = 's';
	break;
      }
      
    case _C_SHT:
      {
	/* Short must be at least 16 bits - always signed */
	if (sizeof (short) == 2)
	  {
	    value.s = [object shortValue];
	    jtype = 's';
	    break;
	  }
	else if (sizeof (short) == 4)
	  {
	    value.i = [object shortValue];
	    jtype = 'i';
	    break;
	  }
	else
	  {
	    value.j = [object shortValue];
	    jtype = 'j';
	    break;
	  }
      }
      
    case _C_USHT:
      {
	/* Unsigned Short must be at least 16 bits, but we can't use a
	   character as that is not a number - so we always use a long */
	value.j = [object unsignedShortValue];
	jtype = 'j';
	break;
      }
      
    case _C_INT: 
      {
	/* Int must be at least 16 bits */
	if (sizeof (int) == 2)
	  {
	    value.s = [object intValue];
	    jtype = 's';
	    break;
	  }
	else if (sizeof (int) == 4)
	  {
	    value.i = [object intValue];
	    jtype = 'i';
	    break;   
	  }
	else if (sizeof (int) == 8)
	  {
	    value.j = [object intValue];
	    jtype = 'j';
	    break;
	  }
	else 
	  {
	    value.j = [object intValue];
	    jtype = 'j';
	    break;
	  }
      }
      
    case _C_UINT:
      {
	/* Unsigned int must be at least 16 bits, but we can't convert
           it to char, so we always use a long */
	value.j = [object unsignedIntValue];
	jtype = 'j';
	break;
      }

    case _C_LNG:
      {
	/* Long must be at least 32 bits */
	if (sizeof (long) == 4)
	  {
	    value.i = [object longValue];
	    jtype = 'i';
	    break;   
	  }
	else if (sizeof (long) == 8)
	  {
	    value.j = [object longValue];
	    jtype = 'j';
	    break;
	  }
	else 
	  {
	    value.j = [object longValue];
	    jtype = 'j';
	    break;
	  }
      }
      
    case _C_ULNG:
      {
	/* Unsigned Long must be at least 32 bits - the only thing we
           can do is use the Java 64 bits signed type for this */
	value.j = [object unsignedLongValue];
	jtype = 'j';
	break;
      }      

#ifdef	_C_LNGLNG
    case _C_LNGLNG:
#else
    case 'q':
#endif
      {
	/* Well - Java has at most 64 bits types - we do what we can */
	value.j = [object longLongValue];
	jtype = 'j';
	break;
      }

#ifdef	_C_ULNGLNG
    case _C_ULNGLNG:
#else
    case 'Q':
#endif
      {
	/* Well - Java has at most 64 bits types - this will probably
	   not work very well */
	value.j = [object unsignedLongLongValue];
	jtype = 'j';
	break;
      }

    case _C_FLT:
      {
	if (sizeof (float) == 4)
	  {
	    value.f = [object floatValue];
	    jtype = 'f';
	    break;
	  }
	else if (sizeof (float) == 8)
	  {
	    value.d = [object floatValue];
	    jtype = 'd';
	    break;
	  }
	else 
	  {
	    value.d = [object floatValue];
	    jtype = 'd';
	    break;
	  }
      }
      
    case _C_DBL:
      {
	if (sizeof (double) == 8)
	  {
	    value.d = [object doubleValue];
	    jtype = 'd';
	    break;
	  }
	else 
	  {
	    value.d = [object doubleValue];
	    jtype = 'd';
	    break;
	  }
      }
      
    default:  /* ? - convert to integer and treat it as integer */
      {
	value.i = [object intValue];
	jtype = 'i';
	break;
      }
    }

#undef _JIGS_check_null
#define _JIGS_check_null(variable) if (variable == NULL) return NULL;

  switch (jtype)
    {
    case 'z':
      {
	NSLog (@"Internal Error - numbers should never be morphed to bools");
	result = NULL;
	break;
      }
    case 'b':
      {
	if (byteId == NULL)
	  {
	    byteId = (*env)->GetMethodID (env, byteClass, "<init>", "(B)V");
	    _JIGS_check_null (byteId);
	  }
	
	result = (*env)->NewObject (env, byteClass, byteId, value.b);
	break;
      }
    case 'c':
      {
	NSLog (@"Internal Error - numbers should never be morphed to chars");
	result = NULL;
	break;
      }
    case 's':
      {
	if (shortId == NULL)
	  {
	    shortId = (*env)->GetMethodID (env, shortClass, "<init>", "(S)V");
	    _JIGS_check_null (shortId);
	  }
	
	result = (*env)->NewObject (env, shortClass, shortId, value.s);
	break;
      }
    case 'i':
      {
	if (intId == NULL)
	  {
	    intId = (*env)->GetMethodID (env, intClass, "<init>", "(I)V");
	    _JIGS_check_null (intId);
	  }
	
	result = (*env)->NewObject (env, intClass, intId, value.i);
	break;
      }
    case 'j':
      {
	if (longId == NULL)
	  {
	    longId = (*env)->GetMethodID (env, longClass, "<init>", "(J)V");
	    _JIGS_check_null (longId);
	  }
	
	result = (*env)->NewObject (env, longClass, longId, value.j);
	break;
      }
    case 'f':
      {
	if (floatId == NULL)
	  {
	    floatId = (*env)->GetMethodID (env, floatClass, "<init>", "(F)V");
	    _JIGS_check_null (floatId);
	  }
	
	result = (*env)->NewObject (env, floatClass, floatId, value.f);
	break;
      }
    case 'd':
      {
	if (doubleId == NULL)
	  {
	    doubleId = (*env)->GetMethodID (env, doubleClass, 
					    "<init>", "(D)V");
	    _JIGS_check_null (doubleId);
	  }
	
	result = (*env)->NewObject (env, doubleClass, doubleId, value.d);
	break;
      }
    }
  
  /* NB: If result == NULL, an exception has been raised */
  return result;
}
