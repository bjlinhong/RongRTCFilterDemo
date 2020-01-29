//
//  ChatGPUImageHandle.m
//  SealRTC
//
//  Created by LiuLinhong on 2019/02/21.
//  Copyright © 2019 BridgeMind. All rights reserved.
//

#import "ChatGPUImageHandler.h"
#import <GPUImage/GPUImage.h>
#import "GPUImageBeautyFilter.h"
#import "GPUImageOutputCamera.h"


@interface ChatGPUImageHandler ()

@property (nonatomic, strong) GPUImageBeautyFilter *beautyFilter;
@property (nonatomic, strong) GPUImageOutputCamera *outputCamera;
@property (nonatomic, strong) GPUImageView *imageView;
@property (nonatomic, strong) GPUImageAlphaBlendFilter *blendFilter;
@property (nonatomic, strong) GPUImageFilter *filter, *defaultFilter;

@end


@implementation ChatGPUImageHandler

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [self initBeautyFilter];
    }
    return self;
}

- (void)initBeautyFilter
{
    [self.outputCamera addTarget:self.beautyFilter];
    [self.beautyFilter addTarget:self.imageView];
    self.filter = self.beautyFilter;
}

- (CMSampleBufferRef)onGPUFilterSource:(CMSampleBufferRef)sampleBuffer
{
    if (!self.filter || !sampleBuffer)
        return nil;
    
    if (!CMSampleBufferIsValid(sampleBuffer))
        return nil;
    
    [self.filter useNextFrameForImageCapture];
    CFRetain(sampleBuffer);
    [self.outputCamera processVideoSampleBuffer:sampleBuffer];
    
    CMTime currentTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    CFRelease(sampleBuffer);
    
    GPUImageFramebuffer *framebuff = [self.filter framebufferForOutput];
    CVPixelBufferRef pixelBuff = [framebuff pixelBuffer];
    CVPixelBufferLockBaseAddress(pixelBuff, 0);
    
    CMVideoFormatDescriptionRef videoInfo = NULL;
    CMVideoFormatDescriptionCreateForImageBuffer(NULL, pixelBuff, &videoInfo);
    
    CMSampleTimingInfo timing = {currentTime, currentTime, kCMTimeInvalid};
    
    CMSampleBufferRef processedSampleBuffer = NULL;
    CMSampleBufferCreateForImageBuffer(kCFAllocatorDefault, pixelBuff, YES, NULL, NULL, videoInfo, &timing, &processedSampleBuffer);
    
    if (videoInfo == NULL)
        return nil;
    
    CFRelease(videoInfo);
    CVPixelBufferUnlockBaseAddress(pixelBuff, 0);
    return processedSampleBuffer;
}

#pragma mark - Getter
- (GPUImageFilter *)defaultFilter
{
    if (!_defaultFilter)  {
        _defaultFilter = [[GPUImageFilter alloc] init];
    }
    return _defaultFilter;
}

- (GPUImageBeautyFilter *)beautyFilter
{
    if (!_beautyFilter) {
        _beautyFilter = [[GPUImageBeautyFilter alloc] init];
    }
    return _beautyFilter;
}

- (GPUImageOutputCamera *)outputCamera
{
    if (!_outputCamera) {
        _outputCamera = [[GPUImageOutputCamera alloc] init];
    }
    return _outputCamera;
}

- (GPUImageAlphaBlendFilter *)blendFilter
{
    if (!_blendFilter) {
        _blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
        _blendFilter.mix = 1.0;
    }
    return _blendFilter;
}

- (GPUImageView *)imageView
{
    if (!_imageView) {
        _imageView = [[GPUImageView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    }
    return _imageView;
}

@end
