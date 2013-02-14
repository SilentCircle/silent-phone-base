/*
 *  SSL client demonstration program
 *
 *  Copyright (C) 2006-2011, Brainspark B.V.
 *
 *  This file is part of PolarSSL (http://www.polarssl.org)
 *  Lead Maintainer: Paul Bakker <polarssl_maintainer at polarssl.org>
 *
 *  All rights reserved.
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License along
 *  with this program; if not, write to the Free Software Foundation, Inc.,
 *  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

#ifndef _CRT_SECURE_NO_DEPRECATE
#define _CRT_SECURE_NO_DEPRECATE 1
#endif

#include <string.h>
#include <stdio.h>

#include "polarssl/config.h"

#include "polarssl/net.h"
#include "polarssl/ssl.h"
#include "polarssl/entropy.h"
#include "polarssl/ctr_drbg.h"
#include "polarssl/error.h"

#define SERVER_PORT 5061
#define SERVER_NAME "50.116.49.43" 
//209.85.173.105"
//159.148.8.97"
//https://www.tivi.com/selfcare/login.php?en
//#define GET_REQUEST "GET / HTTP/1.0\r\n\r\n"
char GET_REQUEST[]=
"OPTIONS sip:fs-devel.silentcircle.org SIP/2.0\r\n"
"Via: SIP/2.0/TLS 192.168.1.65:5060;branch=z9hG4bK44cef81a;rport\r\n"
"Max-Forwards: 70\r\n"
"From:  <sip:Unknown@fs-devel.silentcircle.org>;tag=as72e9af44\r\n"
"To: <sip:fs-devel.silentcircle.org>\r\n"
"Contact: <sip:Unknown@192.168.1.65>\r\n"
"Call-ID: 269e7b6e377894fd4e7a8d2b4c07f094@192.168.1.65\r\n"
"CSeq: 102 OPTIONS\r\n"
"Allow: INVITE, ACK, CANCEL, OPTIONS, BYE, REFER, SUBSCRIBE, NOTIFY, INFO\r\n"
"Content-Length: 0\r\n\r\n";



#define DEBUG_LEVEL 1

void my_debug( void *ctx, int level, const char *str )
{
    if( level < DEBUG_LEVEL )
    {
        fprintf( (FILE *) ctx, "%s", str );
        fflush(  (FILE *) ctx  );
    }
}

#if !defined(POLARSSL_BIGNUM_C) || !defined(POLARSSL_ENTROPY_C) ||  \
    !defined(POLARSSL_SSL_TLS_C) || !defined(POLARSSL_SSL_CLI_C) || \
    !defined(POLARSSL_NET_C) || !defined(POLARSSL_RSA_C) ||         \
    !defined(POLARSSL_CTR_DRBG_C)
int main( int argc, char *argv[] )
{
    ((void) argc);
    ((void) argv);

    printf("POLARSSL_BIGNUM_C and/or POLARSSL_ENTROPY_C and/or "
           "POLARSSL_SSL_TLS_C and/or POLARSSL_SSL_CLI_C and/or "
           "POLARSSL_NET_C and/or POLARSSL_RSA_C and/or "
           "POLARSSL_CTR_DRBG_C not defined.\n");
    return( 0 );
}
#else
int main( int argc, char *argv[] )
{
    int ret, len, server_fd;
    unsigned char buf[1024];
    char *pers = "ssl_client1";

    entropy_context entropy;
    ctr_drbg_context ctr_drbg;
    ssl_context ssl;
    ssl_session ssn;

int ssl_default_ciphersuitesz[] =
{
   
#if defined(POLARSSL_DHM_C)
#if defined(POLARSSL_AES_C)
//    SSL_EDH_RSA_AES_128_SHA,
    SSL_EDH_RSA_AES_256_SHA,
#endif
#if defined(POLARSSL_CAMELLIA_C)
    SSL_EDH_RSA_CAMELLIA_128_SHA,
    SSL_EDH_RSA_CAMELLIA_256_SHA,
#endif
#if defined(POLARSSL_DES_C)
    SSL_EDH_RSA_DES_168_SHA,
#endif
#endif

#if defined(POLARSSL_AES_C)
    SSL_RSA_AES_256_SHA,
#endif
#if defined(POLARSSL_CAMELLIA_C)
    SSL_RSA_CAMELLIA_256_SHA,
#endif
#if defined(POLARSSL_AES_C)
    SSL_RSA_AES_128_SHA,
#endif
#if defined(POLARSSL_CAMELLIA_C)
    SSL_RSA_CAMELLIA_128_SHA,
#endif
#if defined(POLARSSL_DES_C)
    SSL_RSA_DES_168_SHA,
#endif
#if defined(POLARSSL_ARC4_C)
    SSL_RSA_RC4_128_SHA,
    SSL_RSA_RC4_128_MD5,
#endif
    
//    SSL_RSA_AES_256_SHA,
    SSL_RSA_RC4_128_MD5,
    0
};


    ((void) argc);
    ((void) argv);

    /*
     * 0. Initialize the RNG and the session data
     */
    memset( &ssn, 0, sizeof( ssl_session ) );
    memset( &ssl, 0, sizeof( ssl_context ) );

    printf( "\n  . Seeding the random number generator..." );
    fflush( stdout );

    entropy_init( &entropy );
    if( ( ret = ctr_drbg_init( &ctr_drbg, entropy_func, &entropy,
                               (unsigned char *) pers, strlen( pers ) ) ) != 0 )
    {
        printf( " failed\n  ! ctr_drbg_init returned %d\n", ret );
        goto exit;
    }

    printf( " ok\n" );

    /*
     * 1. Start the connection
     */
    printf( "  . Connecting to tcp/%s/%4d...", SERVER_NAME,
                                               SERVER_PORT );
    fflush( stdout );

    if( ( ret = net_connect( &server_fd, SERVER_NAME,
                                         SERVER_PORT ) ) != 0 )
    {
        printf( " failed\n  ! net_connect returned %d\n\n", ret );
        goto exit;
    }

    printf( " ok\n" );

    /*
     * 2. Setup stuff
     */
    printf( "  . Setting up the SSL/TLS structure..." );
    fflush( stdout );

    if( ( ret = ssl_init( &ssl ) ) != 0 )
    {
        printf( " failed\n  ! ssl_init returned %d\n\n", ret );
        goto exit;
    }

    printf( " ok\n" );

    ssl_set_endpoint( &ssl, SSL_IS_CLIENT );
    ssl_set_authmode( &ssl, SSL_VERIFY_NONE );

    ssl_set_rng( &ssl, ctr_drbg_random, &ctr_drbg );
    ssl_set_dbg( &ssl, my_debug, stdout );
    ssl_set_bio( &ssl, net_recv, &server_fd,
                       net_send, &server_fd );

//ssl_default_ciphersuitesz
//    ssl_set_ciphersuites( &ssl, ssl_default_ciphersuites );
    ssl_set_ciphersuites( &ssl, ssl_default_ciphersuitesz );
    ssl_set_session( &ssl, 1, 600, &ssn );

    /*
     * 3. Write the GET request
     */
    printf( "  > Write to server:" );
    fflush( stdout );

    len = sprintf( (char *) buf, GET_REQUEST );

    while( ( ret = ssl_write( &ssl, buf, len ) ) <= 0 )
    {
        if( ret != POLARSSL_ERR_NET_WANT_READ && ret != POLARSSL_ERR_NET_WANT_WRITE )
        {
            printf( " failed\n  ! ssl_write returned %d\n\n", ret );
            goto exit;
        }
    }

    len = ret;
    printf( " %d bytes written\n\n%s", len, (char *) buf );

    /*
     * 7. Read the HTTP response
     */
    printf( "  < Read from server:" );
    fflush( stdout );

    do
    {
        len = sizeof( buf ) - 1;
        memset( buf, 0, sizeof( buf ) );
        ret = ssl_read( &ssl, buf, len );

        if( ret == POLARSSL_ERR_NET_WANT_READ || ret == POLARSSL_ERR_NET_WANT_WRITE )
            continue;

        if( ret == POLARSSL_ERR_SSL_PEER_CLOSE_NOTIFY )
            break;

        if( ret < 0 )
        {
            printf( "failed\n  ! ssl_read returned %d\n\n", ret );
            break;
        }

        if( ret == 0 )
        {
            printf( "\n\nEOF\n\n" );
            break;
        }

        len = ret;
        printf( " %d bytes read\n\n%s", len, (char *) buf );
    }
    while( 1 );

    ssl_close_notify( &ssl );

exit:

#ifdef POLARSSL_ERROR_C
    if( ret != 0 )
    {
        char error_buf[100];
        error_strerror( ret, error_buf, 100 );
        printf("Last error was: %d - %s\n\n", ret, error_buf );
    }
#endif

    net_close( server_fd );
    ssl_free( &ssl );

    memset( &ssl, 0, sizeof( ssl ) );

#if defined(_WIN32)
    printf( "  + Press Enter to exit this program.\n" );
    fflush( stdout ); getchar();
#endif

    return( ret );
}
#endif /* POLARSSL_BIGNUM_C && POLARSSL_ENTROPY_C && POLARSSL_SSL_TLS_C &&
          POLARSSL_SSL_CLI_C && POLARSSL_NET_C && POLARSSL_RSA_C &&
          POLARSSL_CTR_DRBG_C */
