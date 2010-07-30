#import "KeyPair.h"
#import <openssl/rsa.h>

#include <fcntl.h>
#include <unistd.h>
#include "rsa.h"
#include "libssh2_priv.h"

@implementation KeyPair

- (id) init
{
    NSFileManager *fm = [NSFileManager defaultManager];
    bool pubExists = [fm fileExistsAtPath:[self publicFilename]];
    bool priExists = [fm fileExistsAtPath:[self privateFilename]];

    if (!pubExists || !priExists) {
        [self generate];
    }

    return self;
}

- (id) generate
{
    const char *publicFilename = [[self publicFilename] UTF8String];
    const char *privateFilename = [[self privateFilename] UTF8String];
    unsigned char keyBuffer[32 * 1024];
    unsigned char rawKey[32 * 1024];
    unsigned char *keyBytesEnd;
    unsigned char *flag = (unsigned char *)"\000\000\000\007ssh-rsa\000\000\000\001#....";
    const int flagLength = 20;
    FILE *fp;

    // Generate the key pair.

    RSA *rsaKey = RSA_generate_key(1024, 35, NULL, NULL);

    // Write the private key.

    fp = fopen(privateFilename, "w");
    PEM_write_RSAPrivateKey(fp, rsaKey, NULL, NULL, 0, NULL, NULL);
    fclose(fp);
    chmod(privateFilename, 0600);

    // Write the public key.

    int keySize = i2d_RSAPublicKey(rsaKey, NULL);
    assert(keySize > 10);

    memcpy(keyBuffer, flag, flagLength);
    _libssh2_htonu32(&keyBuffer[16], keySize - 9);

    keyBytesEnd = rawKey;
    i2d_RSAPublicKey(rsaKey, &keyBytesEnd);
    memcpy(&keyBuffer[flagLength], &rawKey[6], keySize - 9);

    int contentSize = flagLength + keySize - 9;

    NSData *_publicKey = [NSData dataWithBytes:keyBuffer length:contentSize];
    NSString *publicBase64 = [_publicKey encodeBase64WithNewlines:NO];
    const char *publicBase64c = [publicBase64 UTF8String];

    int publicFile = open(publicFilename, O_CREAT|O_TRUNC|O_WRONLY, 0600);
    write(publicFile, "ssh-rsa ", 8);
    write(publicFile, publicBase64c, strlen(publicBase64c));
    write(publicFile, "\n", 1);
    close(publicFile);
    chmod(publicFilename, 0600);

    return self;
}

- (NSString *) publicFilename
{
    return user_file_path(@"public.key");
}

- (NSString *) privateFilename
{
    return user_file_path(@"private.key");
}

- (NSString *) readPublicKey
{
    return read_user_file(@"public.key");
}

@end
