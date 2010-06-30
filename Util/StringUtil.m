#import "StringUtil.h"

@implementation NSString (monkey)

static const char encodingTable[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

- (NSData *) decodeBase64
{
	if ([self length] == 0) return [NSData data];

	static char *decodingTable = NULL;
	if (decodingTable == NULL)
	{
		decodingTable = malloc(256);
		if (decodingTable == NULL)
			return nil;
		memset(decodingTable, CHAR_MAX, 256);
		NSUInteger i;
		for (i = 0; i < 64; i++)
			decodingTable[(short)encodingTable[i]] = i;
	}

	const char *characters = [self UTF8String];
	if (characters == NULL) return nil;

	char *bytes = malloc((([self length] + 3) / 4) * 3);
	if (bytes == NULL) return nil;

    NSUInteger length = 0;
    NSUInteger i = 0;

    while (YES)
	{
		char buffer[4];
		short bufferLength;
		for (bufferLength = 0; bufferLength < 4; i++)
		{
			if (characters[i] == '\0')
				break;
			if (isspace(characters[i]) || characters[i] == '=')
				continue;
			buffer[bufferLength] = decodingTable[(short)characters[i]];
			if (buffer[bufferLength++] == CHAR_MAX)      //  Illegal character!
			{
				free(bytes);
				return nil;
			}
		}

		if (bufferLength == 0)
			break;
		if (bufferLength == 1)      //  At least two characters are needed to produce one byte!
		{
			free(bytes);
			return nil;
		}

		//  Decode the characters in the buffer to bytes.
		bytes[length++] = (buffer[0] << 2) | (buffer[1] >> 4);
		if (bufferLength > 2)
			bytes[length++] = (buffer[1] << 4) | (buffer[2] >> 2);
		if (bufferLength > 3)
			bytes[length++] = (buffer[2] << 6) | buffer[3];
	}

	realloc(bytes, length);
	return [NSData dataWithBytesNoCopy:bytes length:length freeWhenDone:YES];
}

- (NSString *) stringByConvertingAnsiColor
{
    const char *rs = [self cStringUsingEncoding:NSUTF8StringEncoding];
    char c;
    bool inColor = false;

    AnsiCode *ansi = [[AnsiCode alloc] init];
    NSMutableString *ms = [NSMutableString string];

    while ((c = *rs++)) {
        if (c == 27) {
            [ansi start];

            do {
                rs++;
                c = *rs;
            } while (c && [ansi append:c]);

            if (inColor) [ms appendFormat:@"</span>"];
            inColor = true;
            [ms appendFormat:@"<span class='%@'>", [ansi cssName]];
        } else {
            [ms appendFormat:@"%c", c];
        }
    }

    if (inColor) [ms appendString:@"</span>"];

    [ansi release];

    return ms;
}

- (NSString *) stringByQuotingJavascript
{
    NSString *ns = [self stringByReplacingOccurrencesOfString:@"'" withString:@"\\'"];
    ns = [ns stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
    ns = [ns stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    return [NSString stringWithFormat:@"'%@'", ns];
}

- (NSString *) stringBySingleQuoting
{
    NSString *ns = [self stringByReplacingOccurrencesOfString:@"'" withString:@"'\\''"];
    return [NSString stringWithFormat:@"'%@'", ns];
}

- (NSString *) findMd5
{
    NSString *r1 = @"MD5 .* = ([0-9A-F]{32})$"; // BSD-style MD5 result.
    NSString *r2 = @"^([0-9A-F]{32}) ";         // Linux-style MD5 result.
    NSString *r3 = @"([0-9A-F]{32})";           // Generic MD5 result.

    NSArray *md5Regexes = [NSArray arrayWithObjects:r1, r2, r3, nil];
    NSString *upper = [self uppercaseString];

    for (NSString *regex in md5Regexes) {
        NSArray *comps = [upper componentsMatchedByRegex:regex capture:1];

        if ([comps count] > 0) return [comps objectAtIndex:0];
    }

    return nil;
}

- (NSData *) dataWithAutoEncoding
{
    return [self dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
}

- (NSString *) stringByStrippingWhitespace
{
    NSCharacterSet *ws = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    return [self stringByTrimmingCharactersInSet:ws];
}

- (bool) hasContent
{
    NSString *trimmed = [self stringByStrippingWhitespace];
    return [trimmed length] != 0;
}

@end
