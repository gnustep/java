/* NSArrayTest: test of gnu.gnustep.base.NSArray

   Copyright (C) 2000 Free Software Foundation, Inc.

   Author:  Nicola Pero <n.pero@mi.flashnet.it>
   Date: August 2000
   
   This file is part of GNUstep.
   
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

import gnu.gnustep.base.*;

class NSArrayTest
{ 
  public static void main (String[] args) 
    throws Throwable
  {
    NSArray arrayOne;
    NSArray arrayTwo;
    boolean testEquality;
    
    /* Create two NSArray */
    arrayOne = new NSArray ();
    arrayTwo = new NSArray (); 
    
    /* Add numbers to the first one */
    arrayOne = arrayOne.arrayByAddingObject ("one");
    arrayOne = arrayOne.arrayByAddingObject ("two");
    arrayOne = arrayOne.arrayByAddingObject ("three");
    arrayOne = arrayOne.arrayByAddingObject ("four");

    /* Add letters to the second one */
    arrayTwo = arrayTwo.arrayByAddingObject ("A");
    arrayTwo = arrayTwo.arrayByAddingObject ("B");
    arrayTwo = arrayTwo.arrayByAddingObject ("C");
    arrayTwo = arrayTwo.arrayByAddingObject ("D");    
    arrayTwo = arrayTwo.arrayByAddingObject ("E");

    /* Force the system to garbage-collect now. */
    System.gc ();

    /* Print out description */
    System.out.println ("Created two NSArrays:");
    System.out.println ("* The first one is " + arrayOne);
    System.out.println ("* The second one is " + arrayTwo);
    System.out.println ("");

    /* Now trying to count arrays */
    System.out.println ("Now trying if count () works");
    count (arrayOne, 4);
    count (arrayTwo, 5);
    System.out.println ("");

    /* Now trying if indexOf: works */
    System.out.println ("Now trying if indexOfObject () works");
    indexOf (arrayOne, "one", 0);
    indexOf (arrayOne, "two", 1);
    indexOf (arrayOne, "three", 2);
    indexOf (arrayOne, "four", 3);
    indexOf (arrayTwo, "C", 2);
    System.out.println ("");

    /* Right, now test if equality works */
    System.out.println ("Now trying to compare the arrays using isEqualToArray ()");
    compare (arrayOne, arrayTwo, false);
    compare (arrayTwo, arrayOne, false);
    compare (arrayOne, arrayOne, true);
    compare (arrayTwo, arrayTwo, true);
    System.out.println ("");

    /* Now try cloning */
    System.out.println ("Now trying to clone () " + arrayOne);
    arrayTwo = (NSArray)arrayOne.clone ();
    System.out.println ("Comparing the original array and its clone");
    compare (arrayOne, arrayTwo, true);
    System.out.println ("");

    /* OK, then write it to a file and read it back. */
    System.out.println ("Now writing to file \"test.array\"");
    arrayOne.writeToFile ("test.array", true);
    System.out.println ("Now loading array from file \"test.array\"");
    arrayTwo = new NSArray ("test.array");
    System.out.println ("Comparing the original array and the one read from file");
    compare (arrayOne, arrayTwo, true);
    System.out.println ("");

    /* Happy end */
    System.out.println ("test passed");
  }

  /* Tests - they do not return upon failing */

  public static void compare (NSArray one, NSArray two, 
			      boolean expectedResult)
  {
    String output = "* ";
    String descriptionOfOne;
    String descriptionOfTwo;
    boolean result;

    descriptionOfOne = one.toString ();
    if (two != null)
      {
	descriptionOfTwo = two.toString ();
      }
    else
      {
	descriptionOfTwo = "(null)";
      }

    result = one.isEqualToArray (two);

    if (result)
      {
	output += descriptionOfOne + " and " + descriptionOfTwo
	  + " are equal";
      }
    else
      {
	output += descriptionOfOne + " and " + descriptionOfTwo
	  + " are not equal";
      }
    
    if (result != expectedResult)
      {
	output += " ==> test FAILED";
	System.out.println (output);
	System.exit (1);
      }
    else
      {
	output += " ==> test passed";
	System.out.println (output);
      }
  }

  public static void count (NSArray array, int count)
  {
    String description;
    String output = "* ";
    long result;

    description = array.toString ();
    result = array.count ();

    output += description + " contains " + result + " elements";

    if (result != count)
      {
	output += " ==> test FAILED";
	System.out.println (output);
	System.exit (1);
      }
    else
      {
	output += " ==> test passed";
	System.out.println (output);
      }
  }

  public static void indexOf (NSArray array, Object object, 
			      int position)
  {
    String description;
    String output = "* ";
    long result;

    description = array.toString ();
    result = array.indexOfObject (object);

    output += object + " is at index " + result + " in array " + description;

    if (result != position)
      {
	output += " ==> test FAILED";
	System.out.println (output);
	System.exit (1);
      }
    else
      {
	output += " ==> test passed";
	System.out.println (output);
      }
  }

}
