//
//  ViewController.m
//  RongRTCFilterDemo
//
//  Created by LiuLinhong on 2019/03/24.
//  Copyright © 2019 RongCloud. All rights reserved.
//

#import "ViewController.h"
#import <RongIMLib/RongIMLib.h>
#import <RongRTCLib/RongRTCLib.h>
#import "ChatGPUImageHandler.h"

@interface ViewController () <RongRTCRoomDelegate>

@property (nonatomic, strong) NSString *appKey, *token;
@property (nonatomic, strong) RongRTCRoom *room;
@property (nonatomic, strong) ChatGPUImageHandler *chatGPUImageHandler;

@end


@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    self.chatGPUImageHandler = [[ChatGPUImageHandler alloc] init];
    
    // AppKey 设置
    self.appKey = @""; //请登录融云官网获取
    self.token = @""; //请使用自定义的userID获取此token
    NSAssert(self.appKey.length > 0 && self.token > 0, @"请登录融云官网开发者账号获取Appkey, 请使用自定义的userID获取token!");
    [[RCIMClient sharedRCIMClient] initWithAppKey:self.appKey];
    [[RCIMClient sharedRCIMClient] connectWithToken:self.token
                                            success:^(NSString *userId) {
        NSLog(@"MClient connectWithToken Success userId: %@", userId);
        [self joinRoom];
    }
                                              error:^(RCConnectErrorCode status) {
        NSLog(@"MClient connectWithToken Error: %zd", status);
    }
                                     tokenIncorrect:^{
        NSLog(@"MClient connectWithToken tokenIncorrect: ");
    }];
}

- (void)joinRoom
{
    // 设置本地渲染视图
    dispatch_async(dispatch_get_main_queue(), ^{
        RongRTCLocalVideoView *localView = [[RongRTCLocalVideoView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height/2)];
        localView.fillMode = RCVideoFillModeAspect;
        [[RongRTCAVCapturer sharedInstance] setVideoRender:localView];
        [self.view addSubview:localView];
    });
    
    // 加入房间
    [[RongRTCEngine sharedEngine] joinRoom:@"85730573" completion:^(RongRTCRoom * _Nullable room, RongRTCCode code) {
        room.delegate = self;
        self.room = room;
        if (code == RongRTCCodeSuccess) {
            //打开摄像头
            [[RongRTCAVCapturer sharedInstance] startCapture];
            // 发布资源
            [self.room publishDefaultAVStream:^(BOOL isSuccess,RongRTCCode desc) {
                if (isSuccess) {
                    NSLog(@"publishDefaultAVStream Success");
                } else {
                    NSLog(@"publishDefaultAVStream Failed code: %zd", code);
                }
            }];
            [self subscribeRemoteUser];
        }
    }];
    
    [RongRTCAVCapturer sharedInstance].videoSendBufferCallback = ^CMSampleBufferRef _Nullable(BOOL valid, CMSampleBufferRef  _Nullable sampleBuffer) {
        CMSampleBufferRef processedSampleBuffer = [self.chatGPUImageHandler onGPUFilterSource:sampleBuffer]; //美颜处理
        return processedSampleBuffer;
    };
}

- (void)subscribeRemoteUser
{
    if (self.room.remoteUsers.count == 0) {
        return;
    }
    
    NSMutableArray *streams = [NSMutableArray array];
    for (RongRTCRemoteUser *user in self.room.remoteUsers) {
        for (RongRTCAVInputStream *stream in user.remoteAVStreams) {
            [streams addObject:stream];
        }
    }
    
    NSMutableArray *subscribes = [NSMutableArray new];
    for (RongRTCAVInputStream *stream in streams) {
        [subscribes addObject:stream];
        if (stream.streamType == RTCMediaTypeVideo) {
            RongRTCRemoteVideoView *videoView = [[RongRTCRemoteVideoView alloc] initWithFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height/2, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height/2)];
            videoView.fillMode = RCVideoFillModeAspect;
            [stream setVideoRender:videoView];
            [self.view addSubview:videoView];
        }
    }
    
    if (subscribes.count > 0) {
        FwLogI(RC_Type_RTC,@"A-appSubscribeStream-T",@"%@all subscribe streams",@"sealRTCApp:");
        [self.room subscribeAVStream:subscribes tinyStreams:nil completion:^(BOOL isSuccess, RongRTCCode desc) {
            for (RongRTCAVInputStream *inStream in subscribes) {
                if (inStream.streamType != RTCMediaTypeVideo) {
                    continue;
                }
                if (isSuccess) {
                    NSLog(@"subscribeAVStream Success");
                } else {
                    NSLog(@"subscribeAVStream Failed, Desc: %@", @(desc));
                }
            }
        }];
    }
}

#pragma mark - RongRTCRoomDelegate
// 监听发布资源消息
- (void)didPublishStreams:(NSArray<RongRTCAVInputStream *> *)streams{
    // 设置远端渲染视图
    for (RongRTCAVInputStream * stream in streams) {
        if (stream.streamType == RTCMediaTypeVideo) {
            dispatch_async(dispatch_get_main_queue(), ^{
                RongRTCRemoteVideoView *videoView = [[RongRTCRemoteVideoView alloc]initWithFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height/2, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height/2)];
                [stream setVideoRender:videoView];
                [self.view addSubview:videoView];
            });
        }
    }

    // 订阅资源
    [self.room subscribeAVStream:streams tinyStreams:nil completion:^(BOOL isSuccess, RongRTCCode desc) {
    }];
}

@end
