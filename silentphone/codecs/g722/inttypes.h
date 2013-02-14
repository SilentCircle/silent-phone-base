/*
 * SpanDSP - a series of DSP components for telephony
 *
 * inttypes.h - a fudge for MSVC, which lacks this header
 *
 * Written by Steve Underwood <steveu@coppice.org>
 *
 * Copyright (C) 2006 Michael Jerris
 *
 *
 * This file is released in the public domain.
 *
 */

#if !defined(_INTTYPES_H_)
#define _INTTYPES_H_
#ifdef __linux__
#include <inttypes.h>
//#include <types.h>

#else
//def __APPLE__
//#include <machine/types.h>
//#include <types.h>

//#else

#ifdef __cplusplus
extern "C" {
#endif
#ifdef __APPLE__
   typedef unsigned char		uint8_t;
   typedef unsigned short	uint16_t;
   typedef unsigned int	uint32_t;
   typedef unsigned long long    uint64_t;
   typedef signed char		        int8_t;
   typedef signed short		        int16_t;
   typedef signed int		        int32_t;
   typedef signed long long		        int64_t;
#else
typedef __int8		        __int8_t;
typedef __int16		        __int16_t;
typedef __int32		        __int32_t;
typedef __int64		        __int64_t;

typedef unsigned __int8		uint8_t;
typedef unsigned __int16	uint16_t;
typedef unsigned __int32	uint32_t;
typedef unsigned __int64    uint64_t;
typedef __int8		        int8_t;
typedef __int16		        int16_t;
typedef __int32		        int32_t;
typedef __int64		        int64_t;
#endif

#if !defined(INFINITY)
#define INFINITY 0x7FFFFFFF
#endif

#if !defined(UINT8_MAX)
#define UINT8_MAX   0xFF
#endif
#if !defined(UINT16_MAX)
#define UINT16_MAX  0xFFFF
#endif

#if !defined(INT16_MAX)
#define INT16_MAX   0x7FFF 
#endif
#if !defined(INT16_MIN)
#define INT16_MIN   (-INT16_MAX - 1) 
#endif

#if !defined(INT32_MAX)
#define INT32_MAX	(2147483647)
#endif
#if !defined(INT32_MIN)
#define INT32_MIN	(-2147483647 - 1)
#endif

#define PRId8 "d"
#define PRId16 "d"
#define PRId32 "ld"
#define PRId64 "lld"

#define PRIu8 "u"
#define PRIu16 "u"
#define PRIu32 "lu"
#define PRIu64 "llu"

#ifdef __cplusplus
}
#endif
#endif

#endif
