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


@interface ViewController () <RCRTCRoomEventDelegate>

@property (nonatomic, strong) NSString *appKey, *token;
@property (nonatomic, strong) RCRTCRoom *room;
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
                                           dbOpened:^(RCDBErrorCode code) {}
                                            success:^(NSString *userId) {
        NSLog(@"MClient connectWithToken Success userId: %@", userId);
        [self joinRoom];
    }
                                              error:^(RCConnectErrorCode status) {
        NSLog(@"MClient connectWithToken Error: %zd", status);
    }];
}

- (void)joinRoom
{
    // 设置本地渲染视图
    dispatch_async(dispatch_get_main_queue(), ^{
        RCRTCLocalVideoView *localView = [[RCRTCLocalVideoView alloc] initWithFrame:CGRectMake(0,
                                                                                               0,
                                                                                               [UIScreen mainScreen].bounds.size.width,
                                                                                               [UIScreen mainScreen].bounds.size.height/2)];
        localView.fillMode = RCRTCVideoFillModeAspect;
        [[RCRTCEngine sharedInstance].defaultVideoStream setVideoView:localView];
        [self.view addSubview:localView];
    });
    
    // 加入房间
    [[RCRTCEngine sharedInstance] joinRoom:@"85730573"
                                completion:^(RCRTCRoom * _Nullable room, RCRTCCode code) {
        room.delegate = self;
        self.room = room;
        
        if (code == RCRTCCodeSuccess) {
            //打开摄像头
            [[RCRTCEngine sharedInstance].defaultVideoStream startCapture];
            // 发布资源
            [self.room.localUser publishDefaultStreams:^(BOOL isSuccess, RCRTCCode code) {
                if (isSuccess) {
                    NSLog(@"publishDefaultAVStream Success");
                } else {
                    NSLog(@"publishDefaultAVStream Failed code: %zd", code);
                }
            }];
            
            [self subscribeRemoteUser];
        }
    }];
    
    [RCRTCEngine sharedInstance].defaultVideoStream.videoSendBufferCallback = ^CMSampleBufferRef _Nullable(BOOL valid, CMSampleBufferRef  _Nullable sampleBuffer) {
        CMSampleBufferRef processedSampleBuffer = [self.chatGPUImageHandler onGPUFilterSource:sampleBuffer]; //自定义美颜处理
        return processedSampleBuffer;
    };
}

- (void)subscribeRemoteUser
{
    if (self.room.remoteUsers.count == 0) {
        return;
    }
    
    NSMutableArray *streams = [NSMutableArray array];
    for (RCRTCRemoteUser *user in self.room.remoteUsers) {
        for (RCRTCInputStream *stream in user.remoteStreams) {
            [streams addObject:stream];
        }
    }
    
    NSMutableArray *subscribes = [NSMutableArray new];
    for (RCRTCInputStream *stream in streams) {
        [subscribes addObject:stream];
        if (stream.mediaType == RTCMediaTypeVideo) {
            RCRTCRemoteVideoView *videoView = [[RCRTCRemoteVideoView alloc] initWithFrame:CGRectMake(0,
                                                                                                     [UIScreen mainScreen].bounds.size.height / 2,
                                                                                                     [UIScreen mainScreen].bounds.size.width,
                                                                                                     [UIScreen mainScreen].bounds.size.height / 2)];
            videoView.fillMode = RCRTCVideoFillModeAspect;
            
            if ([stream isKindOfClass:[RCRTCVideoInputStream class]]) {
                RCRTCVideoInputStream *tmpVideoInputStream = (RCRTCVideoInputStream *)stream;
                [tmpVideoInputStream setVideoView:videoView];
            }
            
            [self.view addSubview:videoView];
        }
    }
    
    if (subscribes.count > 0) {
        FwLogI(RC_Type_RTC,@"A-appSubscribeStream-T",@"%@all subscribe streams",@"sealRTCApp:");
        [self.room.localUser subscribeStream:subscribes
                                 tinyStreams:nil
                                  completion:^(BOOL isSuccess, RCRTCCode code) {
            if (isSuccess) {
                NSLog(@"subscribeAVStream Success");
            } else {
                NSLog(@"subscribeAVStream Failed, Desc: %@", @(code));
            }
        }];
    }
}

#pragma mark - RongRTCRoomDelegate
// 监听发布资源消息
- (void)didPublishStreams:(NSArray <RCRTCInputStream *> *)streams {
    // 设置远端渲染视图
    for (RCRTCInputStream *stream in streams) {
        if (stream.mediaType == RTCMediaTypeVideo) {
            dispatch_async(dispatch_get_main_queue(), ^{
                RCRTCRemoteVideoView *videoView = [[RCRTCRemoteVideoView alloc]initWithFrame:CGRectMake(0,
                                                                                                        [UIScreen mainScreen].bounds.size.height / 2,
                                                                                                        [UIScreen mainScreen].bounds.size.width,
                                                                                                        [UIScreen mainScreen].bounds.size.height/2)];
                videoView.fillMode = RCRTCVideoFillModeAspect;
                
                if ([stream isKindOfClass:[RCRTCVideoInputStream class]]) {
                    RCRTCVideoInputStream *tmpVideoInputStream = (RCRTCVideoInputStream *)stream;
                    [tmpVideoInputStream setVideoView:videoView];
                }
                
                [self.view addSubview:videoView];
            });
        }
    }

    // 订阅资源
    [self.room.localUser subscribeStream:streams
                             tinyStreams:nil
                              completion:^(BOOL isSuccess, RCRTCCode code) {
    }];
}

@end
