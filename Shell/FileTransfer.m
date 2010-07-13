@implementation FileTransfer

- (id) initWithSession:(LIBSSH2_SESSION *)s upload:(ProjectFile *)f
{
    self = [super init];

    session = s;
    channel = NULL;
    step = 0;
    success = false;
    isUpload = true;
    file = [f retain];

    NSData *rawContent = [file rawContent];
    if (rawContent)
        content = [[NSMutableData dataWithData:rawContent] retain];
    else
        content = nil;

    return self;
}

- (id) initWithSession:(LIBSSH2_SESSION *)s download:(ProjectFile *)f
{
    self = [super init];

    session = s;
    channel = NULL;
    step = 0;
    success = false;
    isUpload = false;
    file = [f retain];

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
    static char buffer[0x10000];

    NSLog(@"File Transfer %d (upload %d) (content %d/%d)", step, isUpload, content!=nil, [content length]);

    if (isUpload && content == nil) {
        success = false;
        return [self close:9000];
    }

    switch (step)
    {
        case 0:
            // Initialize the upload.

            offset = 0;
            success = false;

            if (!content) return [self close:9001];

            if (isUpload)
                channel = libssh2_scp_send(session, [[file fullpath] UTF8String], mode, [content length]);
            else
                channel = libssh2_scp_recv(session, [[file fullpath] UTF8String], &sb);

            if (channel == NULL) {
                rc = libssh2_session_last_errno(session);

                if (rc == LIBSSH2_ERROR_EAGAIN) return true;

                NSLog(@"Failed to establish an SCP channel %d.", rc);

                return [self close:rc];
            }

            step++;

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
            if (rc < 0) return [self close:rc];

            offset += blockSize;

            return true;

        case 2:
            // Send EOF.

            if (isUpload) {
                rc = libssh2_channel_send_eof(channel);

                if (rc == LIBSSH2_ERROR_EAGAIN) return true;
                if (rc < 0) return [self close:rc];
            }

            step++;

            return true;

        case 3:
            // Wait for EOF.

            if (isUpload) {
                rc = libssh2_channel_wait_eof(channel);

                if (rc == LIBSSH2_ERROR_EAGAIN) return true;
                if (rc < 0) return [self close:rc];
            }

            step++;

            return true;

        case 4:
            // Wait for channel to close.

            if (isUpload) {
                rc = libssh2_channel_wait_closed(channel);

                if (rc == LIBSSH2_ERROR_EAGAIN) return true;
                if (rc < 0) return [self close:rc];
            }

            success = true;
            step++;

            return true;

        default:
            if (success) [Store storeRemote:file content:content];

            return [self close:success];
    }
}

- (bool) close:(int)rc
{
    NSLog(@"Closing file transfer with code %d.", rc);

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
