//
//  ChatGPUImageHandle.h
//  SealRTC
//
//  Created by LiuLinhong on 2019/02/21.
//  Copyright © 2019 BridgeMind. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

@interface ChatGPUImageHandler : NSObject

- (CMSampleBufferRef)onGPUFilterSource:(CMSampleBufferRef)sampleBuffer;

@end

NS_ASSUME_NONNULL_END
