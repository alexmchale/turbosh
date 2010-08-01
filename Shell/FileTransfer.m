@implementation FileTransfer

// Rely on the `cp` command to fix the uploaded file's permissions.
NSString *file_mover_command(NSString *filename)
{
    NSString *temp = [[NSString stringWithFormat:@"%@.part", filename] stringBySingleQuoting];
    NSString *real = [filename stringBySingleQuoting];

    return [NSString stringWithFormat:@"cp %@ %@ ; rm -f %@", temp, real, temp];
}

- (id) initWithSession:(LIBSSH2_SESSION *)s upload:(ProjectFile *)f
{
    self = [super init];

    session = s;
    channel = NULL;
    step = 0;
    success = false;
    isUpload = true;
    file = [f retain];
    filePartialName = [[NSString alloc] initWithFormat:@"%@.part", [f fullpath]];

    NSString *moverScript = file_mover_command([f filename]);
    NSLog(@"Mover script: %@", moverScript);
    fileMover = [[CommandDispatcher alloc] initWithProject:f.project session:session command:moverScript];

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
    filePartialName = nil;
    fileMover = nil;

    content = [NSMutableData data];
    [content retain];

    return self;
}

- (void) dealloc
{
    [file release];
    [filePartialName release];
    [content release];
    [fileMover release];

    [super dealloc];
}

- (bool) step
{
    static char buffer[0x10000];

    int mode = 0700;
    int rc;
    const void *contentPtr;
    int blockSize;
    char *errmsg;
    const char *filename = [[file fullpath] UTF8String];
    const char *partname = [filePartialName UTF8String];

    NSLog(@"File Transfer %d (upload %d) (content %d/%d)", step, isUpload, content!=nil, [content length]);
    assert(content);

    if (content == nil) {
        success = false;
        return [self close:T_ERR_FILE_TRANSFER_NO_CONTENT];
    }

    switch (step)
    {
        case 0:
            // Initialize the upload.

            offset = 0;
            success = false;

            if (isUpload)
                channel = libssh2_scp_send(session, partname, mode, [content length]);
            else
                channel = libssh2_scp_recv(session, filename, &sb);

            if (channel == NULL) {
                rc = libssh2_session_last_error(session, &errmsg, NULL, 0);

                if (rc == LIBSSH2_ERROR_EAGAIN) return true;

                NSLog(@"Failed to establish an SCP channel %d: %s", rc, errmsg);

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

            step++;

            return true;

        case 5:
            // Put the uploaded file into place.

            if (isUpload && fileMover) {
                if ([fileMover step]) return true;
                [fileMover close];
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
    NSLog(@"Closing file transfer at step %d with code %d.", step, rc);

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
