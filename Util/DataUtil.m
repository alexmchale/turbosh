#import "DataUtil.h"
#import <openssl/evp.h>

@implementation NSData (nsdata_monkey)

- (NSString *) stringWithAutoEncoding
{
    NSString *s = nil;

    s = [[NSString alloc] initWithData:self encoding:NSASCIIStringEncoding];
    if (s != nil) return [s autorelease];

    s = [[NSString alloc] initWithData:self encoding:NSUTF8StringEncoding];
    if (s != nil) return [s autorelease];

    s = [[NSString alloc] initWithData:self encoding:NSUTF16StringEncoding];
    if (s != nil) return [s autorelease];

    s = [[NSString alloc] initWithData:self encoding:NSUTF32StringEncoding];
    if (s != nil) return [s autorelease];

    return nil;
}

static const char encodingTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

- (NSString *) base64
{
    return [self encodeBase64WithNewlines: YES];
}

- (NSString *) encodeBase64WithNewlines: (BOOL) encodeWithNewlines
{
    // Create a memory buffer which will contain the Base64 encoded string
    BIO * mem = BIO_new(BIO_s_mem());

    // Push on a Base64 filter so that writing to the buffer encodes the data
    BIO * b64 = BIO_new(BIO_f_base64());
    if (!encodeWithNewlines)
        BIO_set_flags(b64, BIO_FLAGS_BASE64_NO_NL);
    mem = BIO_push(b64, mem);

    // Encode all the data
    BIO_write(mem, [self bytes], [self length]);
    BIO_flush(mem);

    // Create a new string from the data in the memory buffer
    char * base64Pointer;
    long base64Length = BIO_get_mem_data(mem, &base64Pointer);
    NSString * base64String = [NSString stringWithCString: base64Pointer
                                                   length: base64Length];

    // Clean up and go home
    BIO_free_all(mem);
    return base64String;
}

- (NSString *) _base64
{
	if ([self length] == 0)
		return @"";

    char *characters = malloc((([self length] + 2) / 3) * 4);
	if (characters == NULL) return nil;

    NSUInteger length = 0;
	NSUInteger i = 0;

    while (i < [self length])
	{
		char buffer[3] = {0, 0, 0};
		short bufferLength = 0;

		while (bufferLength < 3 && i < [self length])
			buffer[bufferLength++] = ((char *)[self bytes])[i++];

		//  Encode the bytes in the buffer to four characters, including padding "=" characters if necessary.
		characters[length++] = encodingTable[(buffer[0] & 0xFC) >> 2];
		characters[length++] = encodingTable[((buffer[0] & 0x03) << 4) | ((buffer[1] & 0xF0) >> 4)];

        if (bufferLength > 1)
			characters[length++] = encodingTable[((buffer[1] & 0x0F) << 2) | ((buffer[2] & 0xC0) >> 6)];
		else
            characters[length++] = '=';

        if (bufferLength > 2)
			characters[length++] = encodingTable[buffer[2] & 0x3F];
		else
            characters[length++] = '=';
	}

	return [[[NSString alloc]
                 initWithBytesNoCopy:characters
                 length:length
                 encoding:NSASCIIStringEncoding
                 freeWhenDone:YES]
                    autorelease];
}

@end
