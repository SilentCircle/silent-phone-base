/*
Created by Janis Narbuts
Copyright © 2004-2012, Tivi LTD,www.tiviphone.com. All rights reserved.
Copyright © 2012-2013, Silent Circle, LLC. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Any redistribution, use, or modification is done solely for personal 
      benefit and not for any commercial purpose or for monetary gain
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name Silent Circle nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL SILENT CIRCLE, LLC BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

/*
********************************************************************************
*
*      GSM AMR-NB speech codec   R98   Version 7.6.0   December 12, 2001
*                                R99   Version 3.3.0                
*                                REL-4 Version 4.1.0                
*
********************************************************************************
*
*      File             : typedefs.h
*      Description      : Definition of platform independent data
*                         types and constants
*
*
*      The following platform independent data types and corresponding
*      preprocessor (#define) constants are defined:
*
*        defined type  meaning           corresponding constants
*        ----------------------------------------------------------
*        Char          character         (none)
*        Bool          boolean           true, false
*        Word8         8-bit signed      minWord8,   maxWord8
*        UWord8        8-bit unsigned    minUWord8,  maxUWord8
*        Word16        16-bit signed     minWord16,  maxWord16
*        UWord16       16-bit unsigned   minUWord16, maxUWord16
*        Word32        32-bit signed     minWord32,  maxWord32
*        UWord32       32-bit unsigned   minUWord32, maxUWord32
*        Float         floating point    minFloat,   maxFloat
*
*
*      The following compile switches are #defined:
*
*        PLATFORM      string indicating platform progam is compiled on
*                      possible values: "OSF", "PC", "SUN"
*
*        OSF           only defined if the current platform is an Alpha
*        PC            only defined if the current platform is a PC
*        SUN           only defined if the current platform is a Sun
*        
*        LSBFIRST      is defined if the byte order on this platform is
*                      "least significant byte first" -> defined on DEC Alpha
*                      and PC, undefined on Sun
*
********************************************************************************
*/
#ifndef typedefs_h
#define typedefs_h "$Id $"

/*
********************************************************************************
*                         INCLUDE FILES
********************************************************************************
*/
#ifndef __SYMBIAN32__
#include <float.h>
#endif
#include <limits.h>



/*
********************************************************************************
*                         DEFINITION OF CONSTANTS 
********************************************************************************
*/
/*
 ********* define char type
 */
typedef char Char;

/*
 ********* define 8 bit signed/unsigned types & constants
 */
#if SCHAR_MAX == 127

#ifndef _T_WORD8
#define _T_WORD8
typedef unsigned char UWord8;
typedef signed char Word8;
#endif

#define minWord8  SCHAR_MIN
#define maxWord8  SCHAR_MAX


#define minUWord8 0
#define maxUWord8 UCHAR_MAX
#else
#error cannot find 8-bit type
#endif


/*
 ********* define 16 bit signed/unsigned types & constants
 */
#if INT_MAX == 32767
typedef int Word16;
#define minWord16     INT_MIN
#define maxWord16     INT_MAX
typedef unsigned int UWord16;
#define minUWord16    0
#define maxUWord16    UINT_MAX
#elif SHRT_MAX == 32767
#ifndef _T_WORD16
#define _T_WORD16
typedef short Word16;
typedef unsigned short UWord16;
#endif

#define minWord16     SHRT_MIN
#define maxWord16     SHRT_MAX

#define minUWord16    0
#define maxUWord16    USHRT_MAX
#else
#error cannot find 16-bit type
#endif


/*
 ********* define 32 bit signed/unsigned types & constants
 */
#if INT_MAX == 2147483647
#ifndef _T_WORD32
#define _T_WORD32
typedef int Word32;
#endif

#define minWord32     INT_MIN
#define maxWord32     INT_MAX
typedef unsigned int UWord32;
#define minUWord32    0
#define maxUWord32    UINT_MAX
#elif LONG_MAX == 2147483647
typedef long Word32;
#define minWord32     LONG_MIN
#define maxWord32     LONG_MAX
typedef unsigned long UWord32;
#define minUWord32    0
#define maxUWord32    ULONG_MAX
#else
#error cannot find 32-bit type
#endif

/*
 ********* define floating point type & constants
 */
/* use "#if 0" below if Float should be double;
   use "#if 1" below if Float should be float
 */
#if 0
typedef float Float;
#define maxFloat      FLT_MAX
#define minFloat      FLT_MIN
#else
typedef double Float;
#define maxFloat      DBL_MAX
#define minFloat      DBL_MIN
#endif

/*
 ********* define complex type
 */
typedef struct {
  Float r;  /* real      part */
  Float i;  /* imaginary part */
} CPX;

/*
 ********* define boolean type
 */
typedef int Bool;
#define false 0
#define true 1

/*
 ********* Check current platform
 */
#if defined(__MSDOS__)
#define PC
#define PLATFORM "PC"
#define LSBFIRST
#elif defined(__osf__)
#define OSF
#define PLATFORM "OSF"
#define LSBFIRST
#elif defined(__sun__) || defined(__sun)
#define SUN
#define PLATFORM "SUN"
#undef LSBFIRST
#elif defined(linux) && defined(i386)
#define PC
#define PLATFORM "PC"
#define LSBFIRST
#else
#define PC
#define PLATFORM "PC"
#define LSBFIRST
//#error "can't determine architecture; adapt typedefs.h to your platform"
#endif

#endif
