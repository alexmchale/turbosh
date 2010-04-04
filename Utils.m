#import "Utils.h"

@implementation Utils

NSString *hex_md5(NSData *nsData) {
	unsigned char result[CC_MD5_DIGEST_LENGTH];
    const char *cData = [nsData bytes];
    const int cDataLen = [nsData length];
    
	CC_MD5(cData, cDataLen, result);
    
	return [NSString 
			stringWithFormat: @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
			result[0], result[1],
			result[2], result[3],
			result[4], result[5],
			result[6], result[7],
			result[8], result[9],
			result[10], result[11],
			result[12], result[13],
			result[14], result[15]
			];
}

+ (NSString *) getUrl:(NSURL *)url {
	NSURLResponse *resp;
	NSError *error;
	
	NSURLRequest *req = [NSURLRequest requestWithURL:url];
	NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:&resp error:&error];
	
	if (data == nil) return nil;
	
	return [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
}

@end
