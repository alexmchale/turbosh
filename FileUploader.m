#import "FileUploader.h"

@implementation FileUploader

- (id) initWithSession:(LIBSSH2_SESSION *)s file:(ProjectFile *)f
{
    assert(self = [super init]);

    session = s;
    channel = NULL;
    step = 0;
    success = false;

    file = f;
    [file retain];

    content = [[file content] dataUsingEncoding:NSASCIIStringEncoding];
    [content retain];

    return self;
}

- (void) dealloc
{
    [file release];
    [content release];

    [super dealloc];
}

- (bool) step
{
    int mode = 0700;
    int rc;
    const void *contentPtr;
    int blockSize;

    if (content == nil) {
        success = false;
        return [self close];
    }

    switch (step)
    {
        case 0:
            // Initialize the upload.

            channel = libssh2_scp_send(session, [[file fullpath] UTF8String], mode, [content length]);

            if (channel == NULL) {
                if (libssh2_session_last_errno(session) == LIBSSH2_ERROR_EAGAIN) return true;

                return [self close];
            }

            step++;
            offset = 0;
            success = false;

            return true;

        case 1:
            // Send data.

            contentPtr = [content bytes] + offset;
            blockSize = [content length] - offset;

            if (blockSize <= 0) {
                step++;
                return true;
            }

            blockSize = MIN(1024, blockSize);

            rc = libssh2_channel_write(channel, contentPtr, blockSize);

            if (rc == LIBSSH2_ERROR_EAGAIN) return true;
            if (rc < 0) return [self close];

            offset += blockSize;

            return true;

        case 2:
            // Send EOF.

            rc = libssh2_channel_send_eof(channel);

            if (rc == LIBSSH2_ERROR_EAGAIN) return true;
            if (rc < 0) return [self close];

            step++;

            return true;

        case 3:
            // Wait for EOF.

            rc = libssh2_channel_wait_eof(channel);

            if (rc == LIBSSH2_ERROR_EAGAIN) return true;
            if (rc < 0) return [self close];

            step++;

            return true;

        case 4:
            // Wait for channel to close.

            rc = libssh2_channel_wait_closed(channel);

            if (rc == LIBSSH2_ERROR_EAGAIN) return true;
            if (rc != LIBSSH2_ERROR_NONE) return [self close];

            file.remoteMd5 = hex_md5(content);
            [Store storeProjectFile:file];

            success = true;
            step++;

            return true;

        default: return [self close];
    }
}

- (bool) close
{
    if (channel != NULL) {
        libssh2_channel_free(channel);
        channel = NULL;
    }

    return false;
}

- (bool) succeeded
{
    return success;
}

@end
