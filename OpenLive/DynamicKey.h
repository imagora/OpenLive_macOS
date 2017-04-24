//
//  DynamicKey.h
//  OpenLive
//
//  Created by shanhui on 2017/1/12.
//  Copyright © 2017年 Agora. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DynamicKey : NSObject

+(NSString*) generateMediaChannelKey:(NSString *)appID appCertificate:(NSString *)appCertificate channelName:(NSString *)channelName unixTs:(UInt32)unixTs randomInt:(UInt32)randomInt uid:(UInt32)uid expiredTs:(UInt32)expiredTs;

@end
