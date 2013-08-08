//
//  Hawk.m
//  Hawk
//
//  Created by Jesse Stuart on 8/6/13.
//  Copyright (c) 2013 Tent. All rights reserved.
//

#import "Hawk.h"

@implementation Hawk

+ (NSString *)payloadHashWithAttributes:(HawkAuthAttributes *)attributes

{
    NSMutableData *payloadNormalizedString = [[NSMutableData alloc] init];

    [payloadNormalizedString appendData:[@"hawk.1.payload\n" dataUsingEncoding:NSUTF8StringEncoding]];

    [payloadNormalizedString appendData:[attributes.contentType dataUsingEncoding:NSUTF8StringEncoding]];
    [payloadNormalizedString appendData:[@"\n" dataUsingEncoding:NSUTF8StringEncoding]];

    [payloadNormalizedString appendData:attributes.payload];
    [payloadNormalizedString appendData:[@"\n" dataUsingEncoding:NSUTF8StringEncoding]];

    unsigned char hash[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(payloadNormalizedString.mutableBytes, (CC_LONG)payloadNormalizedString.length, hash);

    NSData *output = [NSData dataWithBytes:hash length:CC_SHA256_DIGEST_LENGTH];

    return [output base64EncodedString];
}

+ (NSString *)mac:(HawkAuthAttributes *)attributes
{
    NSMutableData *normalizedString = [[NSMutableData alloc] init];

    // header
    [normalizedString appendData:[@"hawk.1.header\n" dataUsingEncoding:NSUTF8StringEncoding]];

    // timestamp
    [normalizedString appendData:[[NSString stringWithFormat:@"%i\n", (int)[attributes.timestamp timeIntervalSince1970]] dataUsingEncoding:NSUTF8StringEncoding]];

    // nonce
    [normalizedString appendData:[attributes.nonce dataUsingEncoding:NSUTF8StringEncoding]];
    [normalizedString appendData:[@"\n" dataUsingEncoding:NSUTF8StringEncoding]];

    // method
    [normalizedString appendData:[attributes.method dataUsingEncoding:NSUTF8StringEncoding]];
    [normalizedString appendData:[@"\n" dataUsingEncoding:NSUTF8StringEncoding]];

    // request uri
    [normalizedString appendData:[attributes.requestUri dataUsingEncoding:NSUTF8StringEncoding]];
    [normalizedString appendData:[@"\n" dataUsingEncoding:NSUTF8StringEncoding]];

    // host
    [normalizedString appendData:[attributes.host dataUsingEncoding:NSUTF8StringEncoding]];
    [normalizedString appendData:[@"\n" dataUsingEncoding:NSUTF8StringEncoding]];

    // port
    [normalizedString appendData:[[NSString stringWithFormat:@"%i\n", (int)[attributes.port integerValue]] dataUsingEncoding:NSUTF8StringEncoding]];

    // hash
    [normalizedString appendData:[[self payloadHashWithAttributes:attributes] dataUsingEncoding:NSUTF8StringEncoding]];
    [normalizedString appendData:[@"\n" dataUsingEncoding:NSUTF8StringEncoding]];

    // ext
    if (attributes.ext) {
        [normalizedString appendData:[attributes.ext dataUsingEncoding:NSUTF8StringEncoding]];
    }
    [normalizedString appendData:[@"\n" dataUsingEncoding:NSUTF8StringEncoding]];

    // app
    if (attributes.app) {
        [normalizedString appendData:[attributes.app dataUsingEncoding:NSUTF8StringEncoding]];
        [normalizedString appendData:[@"\n" dataUsingEncoding:NSUTF8StringEncoding]];
    }

    // trailing newline
    [normalizedString appendData:[@"\n" dataUsingEncoding:NSUTF8StringEncoding]];

    const char *key = [attributes.credentials.key cStringUsingEncoding:NSUTF8StringEncoding];
    unsigned char hmac[CC_SHA256_DIGEST_LENGTH];

    CCHmac(kCCHmacAlgSHA256, key, strlen(key), normalizedString.mutableBytes, (CC_LONG)normalizedString.length, hmac);

    NSData *output = [NSData dataWithBytes:hmac length:CC_SHA256_DIGEST_LENGTH];

    return [output base64EncodedString];
}

@end