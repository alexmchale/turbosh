/* Copyright (c) 2009 by Daniel Stenberg
 * Copyright (c) 2004-2008, Sara Golemon <sarag@libssh2.org>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms,
 * with or without modification, are permitted provided
 * that the following conditions are met:
 *
 *   Redistributions of source code must retain the above
 *   copyright notice, this list of conditions and the
 *   following disclaimer.
 *
 *   Redistributions in binary form must reproduce the above
 *   copyright notice, this list of conditions and the following
 *   disclaimer in the documentation and/or other materials
 *   provided with the distribution.
 *
 *   Neither the name of the copyright holder nor the names
 *   of any other contributors may be used to endorse or
 *   promote products derived from this software without
 *   specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
 * CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY
 * OF SUCH DAMAGE.
 */

#include "libssh2_priv.h"
#include <errno.h>
#include <stdlib.h>

#include "channel.h"


/* Max. length of a quoted string after libssh2_shell_quotearg() processing */
#define libssh2_shell_quotedsize(s)	(3 * strlen(s) + 2)

/*
    This function quotes a string in a way suitable to be used with a
    shell, e.g. the file name
        one two
    becomes
        'one two'

    The resulting output string is crafted in a way that makes it usable
    with the two most common shell types: Bourne Shell derived shells
    (sh, ksh, ksh93, bash, zsh) and C-Shell derivates (csh, tcsh).

    The following special cases are handled:
     o  If the string contains an apostrophy itself, the apostrophy
	character is written in quotation marks, e.g. "'".
	The shell cannot handle the syntax 'doesn\'t', so we close the
	current argument word, add the apostrophe in quotation marks "",
	and open a new argument word instead (_ indicate the input
	string characters):
	     _____   _   _
	    'doesn' "'" 't'

	Sequences of apostrophes are combined in one pair of quotation marks:
	    a'''b
	becomes
	     _  ___  _
	    'a'"'''"'b'

     o	If the string contains an exclamation mark (!), the C-Shell
	interprets it as an event number. Using \! (not within quotation
	marks or single quotation marks) is a mechanism understood by
	both Bourne Shell and C-Shell.

	If a quotation was already started, the argument word is closed
	first:
	    a!b

	become
	     _  _ _
	    'a'\!'b'

    The result buffer must be large enough for the expanded result. A
    bad case regarding expansion is alternating characters and
    apostrophes:

        a'b'c'd'                   (length 8) gets converted to
        'a'"'"'b'"'"'c'"'"'d'"'"   (length 24)

    This is the worst case.

    Maximum length of the result:
    	1 + 6 * (length(input) + 1) / 2) + 1

        => 3 * length(input) + 2

    Explanation:
     o  leading apostrophe
     o  one character / apostrophe pair (two characters) can get
        represented as 6 characters: a' -> a'"'"'
     o  String terminator (+1)

    A result buffer three times the size of the input buffer + 2
    characters should be safe.

    References:
     o  csh-compatible quotation (special handling for '!' etc.), see
        http://www.grymoire.com/Unix/Csh.html#toc-uh-10

    Return value:
      Length of the resulting string (not counting the terminating '\0'),
      or 0 in case of errors, e.g. result buffer too small

    Note: this function could possible be used elsewhere within libssh2, but
    until then it is kept static and in this source file.
*/

static unsigned
libssh2_shell_quotearg(const char *path, unsigned char *buf,
                       unsigned bufsize)
{
    const char *src;
    unsigned char *dst, *endp;

    /*
     * Processing States:
     *  UQSTRING:	unquoted string: ... -- used for quoting exclamation
     *  		marks. This is the initial state
     *  SQSTRING:       single-qouted-string: '... -- any character may follow
     *  QSTRING:        quoted string: "... -- only apostrophes may follow
     */
    enum { UQSTRING, SQSTRING, QSTRING } state = UQSTRING;

    endp = &buf[bufsize];
    src = path;
    dst = buf;
    while (*src && dst < endp - 1) {

    	switch (*src) {
	    /*
	     * Special handling for apostrophe.
	     * An apostrophe is always written in quotation marks, e.g.
	     * ' -> "'".
	     */

        case '\'':
            switch (state) {
            case UQSTRING:	/* Unquoted string */
                if (dst+1 >= endp)
                    return 0;
                *dst++ = '"';
                break;
            case QSTRING:	/* Continue quoted string */
                break;
            case SQSTRING:	/* Close single quoted string */
                if (dst+2 >= endp)
                    return 0;
                *dst++ = '\'';
                *dst++ = '"';
                break;
            default:
                break;
            }
            state = QSTRING;
            break;

            /*
             * Special handling for exclamation marks. CSH interprets
             * exclamation marks even when quoted with apostrophes. We convert
             * it to the plain string \!, because both Bourne Shell and CSH
             * interpret that as a verbatim exclamation mark.
             */

        case '!':
            switch (state) {
            case UQSTRING:
                if (dst+1 >= endp)
                    return 0;
                *dst++ = '\\';
                break;
            case QSTRING:
                if (dst+2 >= endp)
                    return 0;
                *dst++ = '"';		/* Closing quotation mark */
                *dst++ = '\\';
                break;
            case SQSTRING:		/* Close single quoted string */
                if (dst+2 >= endp)
                    return 0;
                *dst++ = '\'';
                *dst++ = '\\';
                break;
            default:
                break;
            }
            state = UQSTRING;
            break;

	    /*
	     * Ordinary character: prefer single-quoted string
	     */

        default:
            switch (state) {
            case UQSTRING:
                if (dst+1 >= endp)
                    return 0;
                *dst++ = '\'';
                break;
            case QSTRING:
                if (dst+2 >= endp)
                    return 0;
                *dst++ = '"';		/* Closing quotation mark */
                *dst++ = '\'';
                break;
            case SQSTRING:	/* Continue single quoted string */
                break;
            default:
                break;
            }
            state = SQSTRING;	/* Start single-quoted string */
            break;
	}

        if (dst+1 >= endp)
            return 0;
        *dst++ = *src++;
    }

    switch (state) {
    	case UQSTRING:
            break;
        case QSTRING:           /* Close quoted string */
            if (dst+1 >= endp)
                return 0;
            *dst++ = '"';
            break;
        case SQSTRING:          /* Close single quoted string */
            if (dst+1 >= endp)
                return 0;
            *dst++ = '\'';
            break;
        default:
            break;
    }

    if (dst+1 >= endp)
        return 0;
    *dst = '\0';

    /* The result cannot be larger than 3 * strlen(path) + 2 */
    /* assert((dst - buf) <= (3 * (src - path) + 2)); */

    return dst - buf;
}

/*
 * scp_recv
 *
 * Open a channel and request a remote file via SCP
 *
 */
static LIBSSH2_CHANNEL *
scp_recv(LIBSSH2_SESSION * session, const char *path, struct stat * sb)
{
    int cmd_len;
    int rc;

    if (session->scpRecv_state == libssh2_NB_state_idle) {
        session->scpRecv_mode = 0;
        session->scpRecv_size = 0;
        session->scpRecv_mtime = 0;
        session->scpRecv_atime = 0;

        session->scpRecv_command_len =
            libssh2_shell_quotedsize(path) + sizeof("scp -f ") + (sb?1:0);

        session->scpRecv_command =
            LIBSSH2_ALLOC(session, session->scpRecv_command_len);

        if (!session->scpRecv_command) {
            libssh2_error(session, LIBSSH2_ERROR_ALLOC,
                          "Unable to allocate a command buffer for SCP session",
                          0);
            return NULL;
        }

        /* sprintf() is fine here since we allocated a large enough buffer */
        sprintf((char *)session->scpRecv_command, "scp -%sf ", sb?"p":"");

        cmd_len = strlen((char *)session->scpRecv_command);

        (void) libssh2_shell_quotearg(path,
                                      &session->scpRecv_command[cmd_len],
                                      session->scpRecv_command_len - cmd_len);


        _libssh2_debug(session, LIBSSH2_TRACE_SCP,
                       "Opening channel for SCP receive");

        session->scpRecv_state = libssh2_NB_state_created;
    }

    if (session->scpRecv_state == libssh2_NB_state_created) {
        /* Allocate a channel */
        session->scpRecv_channel =
            libssh2_channel_open_ex(session, "session",
                                    sizeof("session") - 1,
                                    LIBSSH2_CHANNEL_WINDOW_DEFAULT,
                                    LIBSSH2_CHANNEL_PACKET_DEFAULT, NULL,
                                    0);
        if (!session->scpRecv_channel) {
            if (libssh2_session_last_errno(session) !=
                LIBSSH2_ERROR_EAGAIN) {
                LIBSSH2_FREE(session, session->scpRecv_command);
                session->scpRecv_command = NULL;
                session->scpRecv_state = libssh2_NB_state_idle;
            }
            else {
                libssh2_error(session, LIBSSH2_ERROR_EAGAIN,
                              "Would block starting up channel", 0);
            }
            return NULL;
        }

        session->scpRecv_state = libssh2_NB_state_sent;
    }

    if (session->scpRecv_state == libssh2_NB_state_sent) {
        /* Request SCP for the desired file */
        rc = libssh2_channel_process_startup(session->scpRecv_channel, "exec",
                                             sizeof("exec") - 1,
                                             (char *) session->scpRecv_command,
                                             session->scpRecv_command_len);
        if (rc == PACKET_EAGAIN) {
            libssh2_error(session, LIBSSH2_ERROR_EAGAIN,
                          "Would block requesting SCP startup", 0);
            return NULL;
        } else if (rc) {
            LIBSSH2_FREE(session, session->scpRecv_command);
            session->scpRecv_command = NULL;
            goto scp_recv_error;
        }
        LIBSSH2_FREE(session, session->scpRecv_command);
        session->scpRecv_command = NULL;

        _libssh2_debug(session, LIBSSH2_TRACE_SCP, "Sending initial wakeup");
        /* SCP ACK */
        session->scpRecv_response[0] = '\0';

        session->scpRecv_state = libssh2_NB_state_sent1;
    }

    if (session->scpRecv_state == libssh2_NB_state_sent1) {
        rc = _libssh2_channel_write(session->scpRecv_channel, 0,
                                    (char *) session->scpRecv_response, 1);
        if (rc == PACKET_EAGAIN) {
            libssh2_error(session, LIBSSH2_ERROR_EAGAIN,
                          "Would block sending initial wakeup", 0);
            return NULL;
        } else if (rc != 1) {
            goto scp_recv_error;
        }

        /* Parse SCP response */
        session->scpRecv_response_len = 0;

        session->scpRecv_state = libssh2_NB_state_sent2;
    }

    if ((session->scpRecv_state == libssh2_NB_state_sent2)
        || (session->scpRecv_state == libssh2_NB_state_sent3)) {
        while (sb && (session->scpRecv_response_len <
                      LIBSSH2_SCP_RESPONSE_BUFLEN)) {
            unsigned char *s, *p;

            if (session->scpRecv_state == libssh2_NB_state_sent2) {
                rc = _libssh2_channel_read(session->scpRecv_channel, 0,
                                           (char *) session->
                                           scpRecv_response +
                                           session->scpRecv_response_len, 1);
                if (rc == PACKET_EAGAIN) {
                    libssh2_error(session, LIBSSH2_ERROR_EAGAIN,
                                  "Would block waiting for SCP response", 0);
                    return NULL;
                } else if (rc <= 0) {
                    /* Timeout, give up */
                    libssh2_error(session, LIBSSH2_ERROR_SCP_PROTOCOL,
                                  "Timed out waiting for SCP response", 0);
                    goto scp_recv_error;
                }
                session->scpRecv_response_len++;

                if (session->scpRecv_response[0] != 'T') {
                    /*
                     * Set this as the default error for here, if
                     * we are successful it will be replaced
                     */
                    libssh2_error(session, LIBSSH2_ERROR_SCP_PROTOCOL,
                                  "Invalid data in SCP response, missing Time data",
                                  0);

                    session->scpRecv_err_len =
                        _libssh2_channel_packet_data_len(session->
                                                         scpRecv_channel, 0);
                    session->scpRecv_err_msg =
                        LIBSSH2_ALLOC(session, session->scpRecv_err_len + 1);
                    if (!session->scpRecv_err_msg) {
                        goto scp_recv_error;
                    }
                    memset(session->scpRecv_err_msg, 0,
                           session->scpRecv_err_len + 1);

                    /* Read the remote error message */
                    rc = _libssh2_channel_read(session->scpRecv_channel, 0,
                                               session->scpRecv_err_msg,
                                               session->scpRecv_err_len);
                    if (rc <= 0) {
                        /*
                         * Since we have alread started reading this packet,
                         * it is already in the systems so it can't return
                         * PACKET_EAGAIN
                         */
                        LIBSSH2_FREE(session, session->scpRecv_err_msg);
                        session->scpRecv_err_msg = NULL;
                        libssh2_error(session, LIBSSH2_ERROR_SCP_PROTOCOL,
                                      "Unknown error while getting error string",
                                      0);
                        goto scp_recv_error;
                    }

                    libssh2_error(session, LIBSSH2_ERROR_SCP_PROTOCOL,
                                  session->scpRecv_err_msg, 1);
                    session->scpRecv_err_msg = NULL;
                    goto scp_recv_error;
                }

                if ((session->scpRecv_response_len > 1) &&
                    ((session->
                      scpRecv_response[session->scpRecv_response_len - 1] <
                      '0')
                     || (session->
                         scpRecv_response[session->scpRecv_response_len - 1] >
                         '9'))
                    && (session->
                        scpRecv_response[session->scpRecv_response_len - 1] !=
                        ' ')
                    && (session->
                        scpRecv_response[session->scpRecv_response_len - 1] !=
                        '\r')
                    && (session->
                        scpRecv_response[session->scpRecv_response_len - 1] !=
                        '\n')) {
                    libssh2_error(session, LIBSSH2_ERROR_SCP_PROTOCOL,
                                  "Invalid data in SCP response", 0);
                    goto scp_recv_error;
                }

                if ((session->scpRecv_response_len < 9)
                    || (session->
                        scpRecv_response[session->scpRecv_response_len - 1] !=
                        '\n')) {
                    if (session->scpRecv_response_len ==
                        LIBSSH2_SCP_RESPONSE_BUFLEN) {
                        /* You had your chance */
                        libssh2_error(session, LIBSSH2_ERROR_SCP_PROTOCOL,
                                      "Unterminated response from SCP server",
                                      0);
                        goto scp_recv_error;
                    }
                    /* Way too short to be an SCP response, or not done yet,
                       short circuit */
                    continue;
                }

                /* We're guaranteed not to go under response_len == 0 by the
                   logic above */
                while ((session->
                        scpRecv_response[session->scpRecv_response_len - 1] ==
                        '\r')
                       || (session->
                           scpRecv_response[session->scpRecv_response_len -
                                            1] == '\n'))
                    session->scpRecv_response_len--;
                session->scpRecv_response[session->scpRecv_response_len] =
                    '\0';

                if (session->scpRecv_response_len < 8) {
                    /* EOL came too soon */
                    libssh2_error(session, LIBSSH2_ERROR_SCP_PROTOCOL,
                                  "Invalid response from SCP server, too short",
                                  0);
                    goto scp_recv_error;
                }

                s = session->scpRecv_response + 1;

                p = (unsigned char *) strchr((char *) s, ' ');
                if (!p || ((p - s) <= 0)) {
                    /* No spaces or space in the wrong spot */
                    libssh2_error(session, LIBSSH2_ERROR_SCP_PROTOCOL,
                                  "Invalid response from SCP server, malformed mtime",
                                  0);
                    goto scp_recv_error;
                }

                *(p++) = '\0';
                /* Make sure we don't get fooled by leftover values */
                errno = 0;
                session->scpRecv_mtime = strtol((char *) s, NULL, 10);
                if (errno) {
                    libssh2_error(session, LIBSSH2_ERROR_SCP_PROTOCOL,
                                  "Invalid response from SCP server, invalid mtime",
                                  0);
                    goto scp_recv_error;
                }
                s = (unsigned char *) strchr((char *) p, ' ');
                if (!s || ((s - p) <= 0)) {
                    /* No spaces or space in the wrong spot */
                    libssh2_error(session, LIBSSH2_ERROR_SCP_PROTOCOL,
                                  "Invalid response from SCP server, malformed mtime.usec",
                                  0);
                    goto scp_recv_error;
                }

                /* Ignore mtime.usec */
                s++;
                p = (unsigned char *) strchr((char *) s, ' ');
                if (!p || ((p - s) <= 0)) {
                    /* No spaces or space in the wrong spot */
                    libssh2_error(session, LIBSSH2_ERROR_SCP_PROTOCOL,
                                  "Invalid response from SCP server, too short or malformed",
                                  0);
                    goto scp_recv_error;
                }

                *(p++) = '\0';
                /* Make sure we don't get fooled by leftover values */
                errno = 0;
                session->scpRecv_atime = strtol((char *) s, NULL, 10);
                if (errno) {
                    libssh2_error(session, LIBSSH2_ERROR_SCP_PROTOCOL,
                                  "Invalid response from SCP server, invalid atime",
                                  0);
                    goto scp_recv_error;
                }

                /* SCP ACK */
                session->scpRecv_response[0] = '\0';

                session->scpRecv_state = libssh2_NB_state_sent3;
            }

            if (session->scpRecv_state == libssh2_NB_state_sent3) {
                rc = _libssh2_channel_write(session->scpRecv_channel, 0,
                                            (char *) session->
                                            scpRecv_response, 1);
                if (rc == PACKET_EAGAIN) {
                    libssh2_error(session, LIBSSH2_ERROR_EAGAIN,
                                  "Would block waiting to send SCP ACK", 0);
                    return NULL;
                } else if (rc != 1) {
                    goto scp_recv_error;
                }

                _libssh2_debug(session, LIBSSH2_TRACE_SCP,
                               "mtime = %ld, atime = %ld",
                               session->scpRecv_mtime, session->scpRecv_atime);

                /* We *should* check that atime.usec is valid, but why let
                   that stop use? */
                break;
            }
        }

        session->scpRecv_state = libssh2_NB_state_sent4;
    }

    if (session->scpRecv_state == libssh2_NB_state_sent4) {
        session->scpRecv_response_len = 0;

        session->scpRecv_state = libssh2_NB_state_sent5;
    }

    if ((session->scpRecv_state == libssh2_NB_state_sent5)
        || (session->scpRecv_state == libssh2_NB_state_sent6)) {
        while (session->scpRecv_response_len < LIBSSH2_SCP_RESPONSE_BUFLEN) {
            char *s, *p, *e = NULL;

            if (session->scpRecv_state == libssh2_NB_state_sent5) {
                rc = _libssh2_channel_read(session->scpRecv_channel, 0,
                                           (char *) session->
                                           scpRecv_response +
                                           session->scpRecv_response_len, 1);
                if (rc == PACKET_EAGAIN) {
                    libssh2_error(session, LIBSSH2_ERROR_EAGAIN,
                                  "Would block waiting for SCP response", 0);
                    return NULL;
                } else if (rc <= 0) {
                    /* Timeout, give up */
                    libssh2_error(session, LIBSSH2_ERROR_SCP_PROTOCOL,
                                  "Timed out waiting for SCP response", 0);
                    goto scp_recv_error;
                }
                session->scpRecv_response_len++;

                if (session->scpRecv_response[0] != 'C') {
                    libssh2_error(session, LIBSSH2_ERROR_SCP_PROTOCOL,
                                  "Invalid response from SCP server", 0);
                    goto scp_recv_error;
                }

                /*
                if ((session->scpRecv_response_len > 1) &&
                    (session->
                     scpRecv_response[session->scpRecv_response_len - 1] !=
                     '\r')
                    && (session->
                        scpRecv_response[session->scpRecv_response_len - 1] !=
                        '\n')
                    &&
                    ((session->
                      scpRecv_response[session->scpRecv_response_len - 1] < 32)
                     || (session->
                         scpRecv_response[session->scpRecv_response_len - 1] >
                         126))) {
                    libssh2_error(session, LIBSSH2_ERROR_SCP_PROTOCOL,
                                  "Invalid data in SCP response", 0);
                    goto scp_recv_error;
                }
                */

                if ((session->scpRecv_response_len < 7)
                    || (session->
                        scpRecv_response[session->scpRecv_response_len - 1] !=
                        '\n')) {
                    if (session->scpRecv_response_len ==
                        LIBSSH2_SCP_RESPONSE_BUFLEN) {
                        /* You had your chance */
                        libssh2_error(session, LIBSSH2_ERROR_SCP_PROTOCOL,
                                      "Unterminated response from SCP server",
                                      0);
                        goto scp_recv_error;
                    }
                    /* Way too short to be an SCP response, or not done yet,
                       short circuit */
                    continue;
                }

                /* We're guaranteed not to go under response_len == 0 by the
                   logic above */
                while ((session->
                        scpRecv_response[session->scpRecv_response_len - 1] ==
                        '\r')
                       || (session->
                           scpRecv_response[session->scpRecv_response_len -
                                            1] == '\n')) {
                    session->scpRecv_response_len--;
                }
                session->scpRecv_response[session->scpRecv_response_len] =
                    '\0';

                if (session->scpRecv_response_len < 6) {
                    /* EOL came too soon */
                    libssh2_error(session, LIBSSH2_ERROR_SCP_PROTOCOL,
                                  "Invalid response from SCP server, too short",
                                  0);
                    goto scp_recv_error;
                }

                s = (char *) session->scpRecv_response + 1;

                p = strchr(s, ' ');
                if (!p || ((p - s) <= 0)) {
                    /* No spaces or space in the wrong spot */
                    libssh2_error(session, LIBSSH2_ERROR_SCP_PROTOCOL,
                                  "Invalid response from SCP server, malformed mode",
                                  0);
                    goto scp_recv_error;
                }

                *(p++) = '\0';
                /* Make sure we don't get fooled by leftover values */
                errno = 0;
                session->scpRecv_mode = strtol(s, &e, 8);
                if ((e && *e) || errno) {
                    libssh2_error(session, LIBSSH2_ERROR_SCP_PROTOCOL,
                                  "Invalid response from SCP server, invalid mode",
                                  0);
                    goto scp_recv_error;
                }

                s = strchr(p, ' ');
                if (!s || ((s - p) <= 0)) {
                    /* No spaces or space in the wrong spot */
                    libssh2_error(session, LIBSSH2_ERROR_SCP_PROTOCOL,
                                  "Invalid response from SCP server, too short or malformed",
                                  0);
                    goto scp_recv_error;
                }

                *(s++) = '\0';
                /* Make sure we don't get fooled by leftover values */
                errno = 0;
                session->scpRecv_size = scpsize_strtol(p, &e, 10);
                if ((e && *e) || errno) {
                    libssh2_error(session, LIBSSH2_ERROR_SCP_PROTOCOL,
                                  "Invalid response from SCP server, invalid size",
                                  0);
                    goto scp_recv_error;
                }

                /* SCP ACK */
                session->scpRecv_response[0] = '\0';

                session->scpRecv_state = libssh2_NB_state_sent6;
            }

            if (session->scpRecv_state == libssh2_NB_state_sent6) {
                rc = _libssh2_channel_write(session->scpRecv_channel, 0,
                                            (char *) session->
                                            scpRecv_response, 1);
                if (rc == PACKET_EAGAIN) {
                    libssh2_error(session, LIBSSH2_ERROR_EAGAIN,
                                  "Would block sending SCP ACK", 0);
                    return NULL;
                } else if (rc != 1) {
                    goto scp_recv_error;
                }
                _libssh2_debug(session, LIBSSH2_TRACE_SCP,
                               "mode = 0%lo size = %ld", session->scpRecv_mode,
                               session->scpRecv_size);

                /* We *should* check that basename is valid, but why let that
                   stop us? */
                break;
            }
        }

        session->scpRecv_state = libssh2_NB_state_sent7;
    }

    if (sb) {
        memset(sb, 0, sizeof(struct stat));

        sb->st_mtime = session->scpRecv_mtime;
        sb->st_atime = session->scpRecv_atime;
        sb->st_size = session->scpRecv_size;
        sb->st_mode = session->scpRecv_mode;
    }

    session->scpRecv_state = libssh2_NB_state_idle;
    return session->scpRecv_channel;

  scp_recv_error:
    while (libssh2_channel_free(session->scpRecv_channel) == PACKET_EAGAIN);
    session->scpRecv_channel = NULL;
    session->scpRecv_state = libssh2_NB_state_idle;
    return NULL;
}

/*
 * libssh2_scp_recv
 *
 * Open a channel and request a remote file via SCP
 *
 */
LIBSSH2_API LIBSSH2_CHANNEL *
libssh2_scp_recv(LIBSSH2_SESSION *session, const char *path, struct stat * sb)
{
    LIBSSH2_CHANNEL *ptr;
    BLOCK_ADJUST_ERRNO(ptr, session, scp_recv(session, path, sb));
    return ptr;
}

/*
 * scp_send()
 *
 * Send a file using SCP
 *
 */
static LIBSSH2_CHANNEL *
scp_send(LIBSSH2_SESSION * session, const char *path, int mode,
         size_t size, long mtime, long atime)
{
    int cmd_len;
    unsigned const char *base;
    int rc;

    if (session->scpSend_state == libssh2_NB_state_idle) {
        session->scpSend_command_len =
            libssh2_shell_quotedsize(path) + sizeof("scp -t ") +
            ((mtime || atime)?1:0);

        session->scpSend_command =
            LIBSSH2_ALLOC(session, session->scpSend_command_len);
        if (!session->scpSend_command) {
            libssh2_error(session, LIBSSH2_ERROR_ALLOC,
                          "Unable to allocate a command buffer for scp session",
                          0);
            return NULL;
        }

        sprintf((char *)session->scpSend_command, "scp -%st ",
                (mtime || atime)?"p":"");

        cmd_len = strlen((char *)session->scpSend_command);

        (void)libssh2_shell_quotearg(path,
                                     &session->scpSend_command[cmd_len],
                                     session->scpSend_command_len - cmd_len);

        session->scpSend_command[session->scpSend_command_len - 1] = '\0';

        _libssh2_debug(session, LIBSSH2_TRACE_SCP,
                       "Opening channel for SCP send");
        /* Allocate a channel */

        session->scpSend_state = libssh2_NB_state_created;
    }

    if (session->scpSend_state == libssh2_NB_state_created) {
        session->scpSend_channel =
            libssh2_channel_open_ex(session, "session", sizeof("session") - 1,
                                    LIBSSH2_CHANNEL_WINDOW_DEFAULT,
                                    LIBSSH2_CHANNEL_PACKET_DEFAULT, NULL, 0);
        if (!session->scpSend_channel) {
            if (libssh2_session_last_errno(session) != LIBSSH2_ERROR_EAGAIN) {
                /* previous call set libssh2_session_last_error(), pass it
                   through */
                LIBSSH2_FREE(session, session->scpSend_command);
                session->scpSend_command = NULL;
                session->scpSend_state = libssh2_NB_state_idle;
            }
            else {
                libssh2_error(session, LIBSSH2_ERROR_EAGAIN,
                              "Would block starting up channel", 0);
            }
            return NULL;
        }

        session->scpSend_state = libssh2_NB_state_sent;
    }

    if (session->scpSend_state == libssh2_NB_state_sent) {
        /* Request SCP for the desired file */
        rc = libssh2_channel_process_startup(session->scpSend_channel, "exec",
                                             sizeof("exec") - 1,
                                             (char *) session->scpSend_command,
                                             session->scpSend_command_len);
        if (rc == PACKET_EAGAIN) {
            libssh2_error(session, LIBSSH2_ERROR_EAGAIN,
                          "Would block requesting SCP startup", 0);
            return NULL;
        }
        else if (rc) {
            /* previous call set libssh2_session_last_error(), pass it
               through */
            LIBSSH2_FREE(session, session->scpSend_command);
            session->scpSend_command = NULL;
            libssh2_error(session, LIBSSH2_ERROR_SCP_PROTOCOL,
                          "Unknown error while getting error string", 0);
            goto scp_send_error;
        }
        LIBSSH2_FREE(session, session->scpSend_command);
        session->scpSend_command = NULL;

        session->scpSend_state = libssh2_NB_state_sent1;
    }

    if (session->scpSend_state == libssh2_NB_state_sent1) {
        /* Wait for ACK */
        rc = _libssh2_channel_read(session->scpSend_channel, 0,
                                   (char *) session->scpSend_response, 1);
        if (rc == PACKET_EAGAIN) {
            libssh2_error(session, LIBSSH2_ERROR_EAGAIN,
                          "Would block waiting for response from remote", 0);
            return NULL;
        } else if ((rc <= 0) || (session->scpSend_response[0] != 0)) {
            libssh2_error(session, LIBSSH2_ERROR_SCP_PROTOCOL,
                          "Invalid ACK response from remote", 0);
            goto scp_send_error;
        }

        if (mtime || atime) {
            /* Send mtime and atime to be used for file */
            session->scpSend_response_len =
                snprintf((char *) session->scpSend_response,
                         LIBSSH2_SCP_RESPONSE_BUFLEN, "T%ld 0 %ld 0\n", mtime,
                         atime);
            _libssh2_debug(session, LIBSSH2_TRACE_SCP, "Sent %s",
                           session->scpSend_response);
        }

        session->scpSend_state = libssh2_NB_state_sent2;
    }

    /* Send mtime and atime to be used for file */
    if (mtime || atime) {
        if (session->scpSend_state == libssh2_NB_state_sent2) {
            rc = _libssh2_channel_write(session->scpSend_channel, 0,
                                        (char *) session->scpSend_response,
                                        session->scpSend_response_len);
            if (rc == PACKET_EAGAIN) {
                libssh2_error(session, LIBSSH2_ERROR_EAGAIN,
                              "Would block sending time data for SCP file", 0);
                return NULL;
            } else if (rc != (int)session->scpSend_response_len) {
                libssh2_error(session, LIBSSH2_ERROR_SOCKET_SEND,
                              "Unable to send time data for SCP file", 0);
                goto scp_send_error;
            }

            session->scpSend_state = libssh2_NB_state_sent3;
        }

        if (session->scpSend_state == libssh2_NB_state_sent3) {
            /* Wait for ACK */
            rc = _libssh2_channel_read(session->scpSend_channel, 0,
                                       (char *) session->scpSend_response, 1);
            if (rc == PACKET_EAGAIN) {
                libssh2_error(session, LIBSSH2_ERROR_EAGAIN,
                              "Would block waiting for response", 0);
                return NULL;
            } else if ((rc <= 0) || (session->scpSend_response[0] != 0)) {
                libssh2_error(session, LIBSSH2_ERROR_SCP_PROTOCOL,
                              "Invalid ACK response from remote", 0);
                goto scp_send_error;
            }

            session->scpSend_state = libssh2_NB_state_sent4;
        }
    } else {
        if (session->scpSend_state == libssh2_NB_state_sent2) {
            session->scpSend_state = libssh2_NB_state_sent4;
        }
    }

    if (session->scpSend_state == libssh2_NB_state_sent4) {
        /* Send mode, size, and basename */
        base = (unsigned char *) strrchr(path, '/');
        if (base) {
            base++;
        } else {
            base = (unsigned char *) path;
        }

        session->scpSend_response_len =
            snprintf((char *) session->scpSend_response,
                     LIBSSH2_SCP_RESPONSE_BUFLEN, "C0%o %lu %s\n", mode,
                     (unsigned long) size, base);
        _libssh2_debug(session, LIBSSH2_TRACE_SCP, "Sent %s",
                       session->scpSend_response);

        session->scpSend_state = libssh2_NB_state_sent5;
    }

    if (session->scpSend_state == libssh2_NB_state_sent5) {
        rc = _libssh2_channel_write(session->scpSend_channel, 0,
                                    (char *) session->scpSend_response,
                                    session->scpSend_response_len);
        if (rc == PACKET_EAGAIN) {
            libssh2_error(session, LIBSSH2_ERROR_EAGAIN,
                          "Would block send core file data for SCP file", 0);
            return NULL;
        } else if (rc != (int)session->scpSend_response_len) {
            libssh2_error(session, LIBSSH2_ERROR_SOCKET_SEND,
                          "Unable to send core file data for SCP file", 0);
            goto scp_send_error;
        }

        session->scpSend_state = libssh2_NB_state_sent6;
    }

    if (session->scpSend_state == libssh2_NB_state_sent6) {
        /* Wait for ACK */
        rc = _libssh2_channel_read(session->scpSend_channel, 0,
                                   (char *) session->scpSend_response, 1);
        if (rc == PACKET_EAGAIN) {
            libssh2_error(session, LIBSSH2_ERROR_EAGAIN,
                          "Would block waiting for response", 0);
            return NULL;
        } else if (rc <= 0) {
            libssh2_error(session, LIBSSH2_ERROR_SCP_PROTOCOL,
                          "Invalid ACK response from remote", 0);
            goto scp_send_error;
        } else if (session->scpSend_response[0] != 0) {
            /*
             * Set this as the default error for here, if
             * we are successful it will be replaced
             */
            libssh2_error(session, LIBSSH2_ERROR_SCP_PROTOCOL,
                          "Invalid ACK response from remote", 0);

            session->scpSend_err_len =
                _libssh2_channel_packet_data_len(session->scpSend_channel, 0);
            session->scpSend_err_msg =
                LIBSSH2_ALLOC(session, session->scpSend_err_len + 1);
            if (!session->scpSend_err_msg) {
                goto scp_send_error;
            }
            memset(session->scpSend_err_msg, 0, session->scpSend_err_len + 1);

            /* Read the remote error message */
            rc = _libssh2_channel_read(session->scpSend_channel, 0,
                                       session->scpSend_err_msg,
                                       session->scpSend_err_len);
            if (rc <= 0) {
                /*
                 * Since we have alread started reading this packet, it is
                 * already in the systems so it can't return PACKET_EAGAIN
                 */
                LIBSSH2_FREE(session, session->scpSend_err_msg);
                session->scpSend_err_msg = NULL;
                goto scp_send_error;
            }

            libssh2_error(session, LIBSSH2_ERROR_SCP_PROTOCOL,
                          session->scpSend_err_msg, 1);
            session->scpSend_err_msg = NULL;
            goto scp_send_error;
        }
    }

    session->scpSend_state = libssh2_NB_state_idle;

    return session->scpSend_channel;

  scp_send_error:
    while (libssh2_channel_free(session->scpSend_channel) == PACKET_EAGAIN);
    session->scpSend_channel = NULL;
    session->scpSend_state = libssh2_NB_state_idle;
    return NULL;
}

/*
 * libssh2_scp_send_ex
 *
 * Send a file using SCP
 */
LIBSSH2_API LIBSSH2_CHANNEL *
libssh2_scp_send_ex(LIBSSH2_SESSION *session, const char *path, int mode,
                    size_t size, long mtime, long atime)
{
    LIBSSH2_CHANNEL *ptr;
    BLOCK_ADJUST_ERRNO(ptr, session,
                       scp_send(session, path, mode, size, mtime, atime));
    return ptr;
}
