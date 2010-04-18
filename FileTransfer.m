@implementation FileTransfer

- (id) initWithSession:(LIBSSH2_SESSION *)s upload:(ProjectFile *)f
{
    assert(self = [super init]);

    session = s;
    channel = NULL;
    step = 0;
    success = false;
    isUpload = true;

    file = f;
    [file retain];

    content = [NSMutableData dataWithData:[[file content] dataUsingEncoding:NSASCIIStringEncoding]];
    [content retain];

    return self;
}

- (id) initWithSession:(LIBSSH2_SESSION *)s download:(ProjectFile *)f
{
    assert(self = [super init]);

    session = s;
    channel = NULL;
    step = 0;
    success = false;
    isUpload = false;

    file = f;
    [file retain];

    content = [NSMutableData data];
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
    static char buffer[0x4000];

    if (isUpload && content == nil) {
        success = false;
        return [self close];
    }

    switch (step)
    {
        case 0:
            // Initialize the upload.

            if (isUpload)
                channel = libssh2_scp_send(session, [[file fullpath] UTF8String], mode, [content length]);
            else
                channel = libssh2_scp_recv(session, [[file fullpath] UTF8String], &sb);

            if (channel == NULL) {
                if (libssh2_session_last_errno(session) == LIBSSH2_ERROR_EAGAIN) return true;

                return [self close];
            }

            step++;
            offset = 0;
            success = false;

            return true;

        case 1:
            if (isUpload) {
                // Send data.

                contentPtr = [content bytes] + offset;
                blockSize = [content length] - offset;

                if (blockSize <= 0) {
                    step++;
                    return true;
                }

                blockSize = MIN(1024, blockSize);

                rc = libssh2_channel_write(channel, contentPtr, blockSize);
            } else {
                // Receive data.

                blockSize = sb.st_size - offset;

                if (blockSize <= 0) {
                    step++;
                    return true;
                }

                blockSize = MIN(sizeof(buffer), blockSize);

                rc = libssh2_channel_read(channel, buffer, blockSize);

                if (rc > 0) [content appendBytes:buffer length:rc];
            }

            if (rc == LIBSSH2_ERROR_EAGAIN) return true;
            if (rc < 0) return [self close];

            offset += blockSize;

            return true;

        case 2:
            // Send EOF.

            if (isUpload) {
                rc = libssh2_channel_send_eof(channel);

                if (rc == LIBSSH2_ERROR_EAGAIN) return true;
                if (rc < 0) return [self close];
            }

            step++;

            return true;

        case 3:
            // Wait for EOF.

            if (isUpload) {
                rc = libssh2_channel_wait_eof(channel);

                if (rc == LIBSSH2_ERROR_EAGAIN) return true;
                if (rc < 0) return [self close];
            }

            step++;

            return true;

        case 4:
            // Wait for channel to close.

            if (isUpload) {
                rc = libssh2_channel_wait_closed(channel);

                if (rc == LIBSSH2_ERROR_EAGAIN) return true;
                if (rc < 0) return [self close];
            }

            success = true;
            step++;

            return true;

        default:
            if (success) {
                if (isUpload) {
                    file.remoteMd5 = hex_md5(content);
                    [Store storeProjectFile:file];
                } else {
                    [Store storeRemote:file content:content];
                }
            }

            return [self close];
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
