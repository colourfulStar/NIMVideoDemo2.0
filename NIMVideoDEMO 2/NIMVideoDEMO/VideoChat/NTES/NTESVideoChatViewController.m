//
//  NTESVideoChatViewController.m
//  NIM
//
//  Created by chris on 15/5/5.
//  Copyright (c) 2015年 Netease. All rights reserved.
//

#import "NTESVideoChatViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "GLView.h"
#import "NIMAVChat.h"


@interface NTESVideoChatViewController ()<NIMNetCallManagerDelegate>

//@property (nonatomic,assign) NIMNetCallCamera cameraType;

@property (nonatomic,strong) CALayer *localVideoLayer;

@property (nonatomic,assign) BOOL oppositeCloseVideo;

//#if defined (NTESUseGLView)
//@property (nonatomic, strong) NTESGLView *remoteGLView;
//#endif

@property (nonatomic,strong) NSMutableArray *chatRoom;

@end

@implementation NTESVideoChatViewController


- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.callInfo.callType = NIMNetCallTypeVideo;
//        _cameraType = [[NTESBundleSetting sharedConfig] startWithBackCamera] ? NIMNetCallCameraBack :NIMNetCallCameraFront;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self initUI];
    
    //设置视屏屏幕常亮
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    [[NIMSDK sharedSDK].netCallManager addDelegate:self];
    
    //callInfo初始化赋值
    self.callInfo = [[NetCallChatInfo alloc] init];
    NSString *currentCaller = [[NIMSDK sharedSDK].loginManager currentAccount];
    self.callInfo.caller = currentCaller;
    self.callInfo.callee = kAccount2;
}

#pragma mark - UI
- (void)initUI
{
    self.remoteView.userInteractionEnabled = YES;
    
    self.localRecordingView.layer.cornerRadius = 10.0;
    self.localRecordingRedPoint.layer.cornerRadius = 4.0;
    self.lowMemoryView.layer.cornerRadius = 10.0;
    self.lowMemoryRedPoint.layer.cornerRadius = 4.0;
    self.refuseBtn.exclusiveTouch = YES;
    self.acceptBtn.exclusiveTouch = YES;
    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
        [self initRemoteGLView];
    }
    
    UIButton *btn = [[UIButton alloc]initWithFrame:CGRectMake(10, 20, 100, 30)];
    [btn setTitle:@"开始视频" forState:UIControlStateNormal];
    btn.titleLabel.textColor = [UIColor blackColor];
    [btn addTarget:self action:@selector(btnAction:) forControlEvents:UIControlEventTouchUpInside];
    btn.backgroundColor = [UIColor orangeColor];
    [self.remoteView addSubview:btn];
}

#pragma mark - Interface
//正在接听中界面
- (void)startInterface{
    self.acceptBtn.hidden = YES;
    self.refuseBtn.hidden   = YES;
    self.hungUpBtn.hidden   = NO;
    self.connectingLabel.hidden = NO;
    self.connectingLabel.text = @"正在呼叫，请稍候...";
    self.switchModelBtn.hidden = YES;
    self.switchCameraBtn.hidden = YES;
    self.muteBtn.hidden = YES;
    self.disableCameraBtn.hidden = YES;
    self.localRecordBtn.hidden = YES;
    self.localRecordingView.hidden = YES;
    self.lowMemoryView.hidden = YES;
    [self.hungUpBtn removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
    [self.hungUpBtn addTarget:self action:@selector(hangup) forControlEvents:UIControlEventTouchUpInside];
}

//选择是否接听界面
- (void)waitToCallInterface{
    self.acceptBtn.hidden = NO;
    self.refuseBtn.hidden   = NO;
    self.hungUpBtn.hidden   = YES;
//    NSString *nick = [NTESSessionUtil showNick:self.callInfo.caller inSession:nil];
//    self.connectingLabel.text = [nick stringByAppendingString:@"的来电"];
    self.muteBtn.hidden = YES;
    self.switchCameraBtn.hidden = YES;
    self.disableCameraBtn.hidden = YES;
    self.localRecordBtn.hidden = YES;
    self.localRecordingView.hidden = YES;
    self.lowMemoryView.hidden = YES;
    self.switchModelBtn.hidden = YES;
}

//连接对方界面
- (void)connectingInterface{
    self.acceptBtn.hidden = YES;
    self.refuseBtn.hidden   = YES;
    self.hungUpBtn.hidden   = NO;
    self.connectingLabel.hidden = NO;
    self.connectingLabel.text = @"正在连接对方...请稍后...";
    self.switchModelBtn.hidden = YES;
    self.switchCameraBtn.hidden = YES;
    self.muteBtn.hidden = YES;
    self.disableCameraBtn.hidden = YES;
    self.localRecordBtn.hidden = YES;
    self.localRecordingView.hidden = YES;
    self.lowMemoryView.hidden = YES;
    [self.hungUpBtn removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
    [self.hungUpBtn addTarget:self action:@selector(hangup) forControlEvents:UIControlEventTouchUpInside];
}

//接听中界面(视频)
- (void)videoCallingInterface{
//    NIMNetCallNetStatus status = [NIMSDK sharedSDK].netCallManager.netStatus;
//    [self.netStatusView refreshWithNetState:status];
    self.acceptBtn.hidden = YES;
    self.refuseBtn.hidden   = YES;
    self.hungUpBtn.hidden   = NO;
    self.connectingLabel.hidden = YES;
    self.muteBtn.hidden = NO;
    self.switchCameraBtn.hidden = NO;
    self.disableCameraBtn.hidden = NO;
    self.localRecordBtn.hidden = NO;
//    self.switchModelBtn.hidden = NO;
    self.muteBtn.selected = self.callInfo.isMute;
    self.disableCameraBtn.selected = self.callInfo.disableCammera;
    self.localRecordBtn.selected = self.callInfo.localRecording;
    self.localRecordingView.hidden = !self.callInfo.localRecording;
    self.lowMemoryView.hidden = YES;
//    [self.switchModelBtn setTitle:@"语音模式" forState:UIControlStateNormal];
    [self.hungUpBtn removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
    [self.hungUpBtn addTarget:self action:@selector(hangup) forControlEvents:UIControlEventTouchUpInside];
    self.localVideoLayer.hidden = NO;
}

- (void)udpateLowSpaceWarning:(BOOL)show {
    self.lowMemoryView.hidden = !show;
    self.localRecordingView.hidden = show;
}


#pragma mark - IBAction
-(void)btnAction:(id)sender
{
    [self startByCaller];
    [self startInterface];
}

- (IBAction)acceptToCall:(id)sender{
    BOOL accept = (sender == self.acceptBtn);
    //防止用户在点了接收后又点拒绝的情况
    [self response:accept];
}

- (IBAction)mute:(BOOL)sender{
    self.callInfo.isMute = !self.callInfo.isMute;
//    self.player.volume = !self.callInfo.isMute;
    [[NIMSDK sharedSDK].netCallManager setMute:self.callInfo.isMute];
    self.muteBtn.selected = self.callInfo.isMute;
}

- (IBAction)switchCamera:(id)sender{
//    if (self.cameraType == NIMNetCallCameraFront) {
//        self.cameraType = NIMNetCallCameraBack;
//    }else{
//        self.cameraType = NIMNetCallCameraFront;
//    }
//    [[NIMSDK sharedSDK].netCallManager switchCamera:self.cameraType];
//    self.switchCameraBtn.selected = (self.cameraType == NIMNetCallCameraBack);
}


- (IBAction)disableCammera:(id)sender{
    self.callInfo.disableCammera = !self.callInfo.disableCammera;
    [[NIMSDK sharedSDK].netCallManager setCameraDisable:self.callInfo.disableCammera];
    self.disableCameraBtn.selected = self.callInfo.disableCammera;
    if (self.callInfo.disableCammera) {
        [self.localVideoLayer removeFromSuperlayer];
        [[NIMSDK sharedSDK].netCallManager control:self.callInfo.callID type:NIMNetCallControlTypeCloseVideo];
    }else{
        [self.localView.layer addSublayer:self.localVideoLayer];
        [[NIMSDK sharedSDK].netCallManager control:self.callInfo.callID type:NIMNetCallControlTypeOpenVideo];
    }
}

- (IBAction)localRecord:(id)sender {
    
//    if (self.callInfo.localRecording) {
//        if (![self stopLocalRecording]) {
//            [self.view makeToast:@"无法结束录制"
//                        duration:3
//                        position:CSToastPositionCenter];
//        }
//    }
//    else {
//        NSString *toastText;
//        if ([self startLocalRecording]) {
//            toastText = @"仅录制你的声音和图像";
//        }
//        else {
//            toastText = @"无法开始录制";
//        }
//        [self.view makeToast:toastText
//                    duration:3
//                    position:CSToastPositionCenter];
//    }
}


- (IBAction)switchCallingModel:(id)sender{
//    [[NIMSDK sharedSDK].netCallManager control:self.callInfo.callID type:NIMNetCallControlTypeToAudio];
//    [self switchToAudio];
}


#pragma mark - Call Life
- (void)onCalling
{
    [self videoCallingInterface];
}

- (void)startByCallee{
    [self waitToCallInterface];
    
    self.callInfo.isStart = YES;
    
    NSMutableArray *room = [[NSMutableArray alloc] init];
    [room addObject:self.callInfo.caller];
    self.chatRoom = room;
    
    [[NIMSDK sharedSDK].netCallManager control:self.callInfo.callID type:NIMNetCallControlTypeFeedabck];
}

- (void)startByCaller{
    __weak typeof(self) wself = self;
    if (!wself)
    {
        return;
    }
    wself.callInfo.isStart = YES;
    
#warning 默认是kAccount1发送视频请求到kAccount2。在此处更改
    NSString *callee = kAccount2;
    NSArray *callees = @[callee];
    
    NIMNetCallOption *option = [[NIMNetCallOption alloc] init];
    option.apnsContent = [NSString stringWithFormat:@"%@请求", wself.callInfo.callType == NIMNetCallTypeAudio ? @"网络通话" : @"视频聊天"];
    option.extendMessage = @"音视频请求扩展信息";
    option.preferredVideoQuality = NIMNetCallVideoQualityLow;
    
    [[NIMSDK sharedSDK].netCallManager start:callees type:wself.callInfo.callType option:option completion:^(NSError *error, UInt64 callID) {
        if (!error && wself) {
            //发起成功，给一个callID
            wself.callInfo.callID = callID;
            wself.chatRoom = [[NSMutableArray alloc]init];
            
            //十秒之后如果还是没有收到对方响应的control字段，则自己发起一个假的control，用来激活铃声并自己先进入聊天室
            NSTimeInterval delayTime = 10;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [wself onControl:callID from:wself.callInfo.callee type:NIMNetCallControlTypeFeedabck];
            });
            
        }else{
            if (error) {
                NSLog(@"%@",error);
                
            }else{
                //说明在start的过程中把页面关了
                [[NIMSDK sharedSDK].netCallManager hangup:callID];
                [wself dismiss:nil];
            }
        }
    }];
}

- (void)waitForConnectiong{
    //    [super waitForConnectiong];
    [self connectingInterface];
}



#pragma mark -NIMNetCallManagerDelegate
- (void)onReceive:(UInt64)callID from:(NSString *)caller type:(NIMNetCallType)type message:(NSString *)extendMessage{
    
    self.callInfo.callID = callID;
    
    if ([NIMSDK sharedSDK].netCallManager.currentCallID > 0)
    {
        [[NIMSDK sharedSDK].netCallManager control:callID type:NIMNetCallControlTypeBusyLine];
        return;
    };
    switch (type)
    {
        case NIMNetCallTypeVideo:
        {
            //检查设备可用性，进行视频
            __weak typeof(self) wself = self;
            [self checkServiceEnable:^(BOOL result) {
                if (result) {
                    [wself afterCheckService];
                }else{
                    [wself dismiss:nil];
                }
            }];
        }
    }
}


- (void)afterCheckService{
    if (self.callInfo.isStart)
    {
        [self onCalling];
    }
    else if (self.callInfo.callID)
    {
        [self startByCallee];
    }
    else
    {
        
    }
}


- (void)dismiss:(void (^)(void))completion{
    //只要页面消失，就挂断
    if (self.callInfo.callID != 0) {
        [[NIMSDK sharedSDK].netCallManager hangup:self.callInfo.callID];
        
        self.chatRoom = nil;
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)hangup{
    [[NIMSDK sharedSDK].netCallManager hangup:self.callInfo.callID];
    [self dismissViewControllerAnimated:YES completion:nil];
    
//    if (self.callInfo.localRecording) {
//        __weak typeof(self) wself = self;
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            wself.chatRoom = nil;
//            [wself dismiss:nil];
//        });
//    }
//    else {
//        self.chatRoom = nil;
//        [self dismiss:nil];
//    }
}

- (void)onHangup:(UInt64)callID
              by:(NSString *)user{
    if (self.callInfo.callID == callID) {
        if (self.callInfo.localRecording) {
            __weak typeof(self) wself = self;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [wself dismiss:nil];
            });
        }
        else {
            [self dismiss:nil];
        }
    }
}

- (void)response:(BOOL)accept{
    __weak typeof(self) wself = self;
    
    NIMNetCallOption *option = [[NIMNetCallOption alloc] init];
    
    [[NIMSDK sharedSDK].netCallManager response:self.callInfo.callID accept:accept option:option completion:^(NSError *error, UInt64 callID) {
        if (!error) {
            [wself onCalling];
            [wself.chatRoom addObject:wself.callInfo.callee];
            NSTimeInterval delay = 10.f; //10秒后判断下聊天室
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (wself.chatRoom.count == 1) {
                    
                    [wself dismiss:nil];
                }
            });
        }else{
            wself.chatRoom = nil;
            [wself dismiss:nil];
        }
    }];
    //dismiss需要放在self后面，否在ios7下会有野指针
    if (accept) {
        
    }else{
        [self dismiss:nil];
    }
}


- (void)setLocalVideoLayer:(CALayer *)localVideoLayer{
    if (_localVideoLayer != localVideoLayer) {
        _localVideoLayer = localVideoLayer;
    }
}

- (void)onLocalPreviewReady:(CALayer *)layer{
    if (self.localVideoLayer) {
        [self.localVideoLayer removeFromSuperlayer];
    }
    self.localVideoLayer = layer;
    layer.frame = self.localView.bounds;
    [self.localView.layer addSublayer:layer];
}



#if defined(NTESUseGLView)
- (void)onRemoteYUVReady:(NSData *)yuvData
                   width:(NSUInteger)width
                  height:(NSUInteger)height
{
    if (([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) && !self.oppositeCloseVideo) {
        
        if (!_remoteGLView) {
            [self initRemoteGLView];
        }
        [_remoteGLView render:yuvData width:width height:height];
        
        //把本地view设置在对方的view之上
        [self.remoteGLView addSubview:self.localView];
        [self.remoteGLView addSubview:dismissBtn];
    }
}
#else
- (void)onRemoteImageReady:(CGImageRef)image{
    
    self.remoteView.contentMode = UIViewContentModeScaleAspectFill;
    self.remoteView.image = [UIImage imageWithCGImage:image];
}
#endif




- (void)initRemoteGLView {
#if defined (NTESUseGLView)
    _remoteGLView = [[GLView alloc] initWithFrame:_remoteView.bounds];
    
    [_remoteGLView setContentMode:UIViewContentModeCenter];
    [_remoteGLView setBackgroundColor:[UIColor clearColor]];
    _remoteGLView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [_remoteView addSubview:_remoteGLView];
    
#endif
}



- (void)onControl:(UInt64)callID
             from:(NSString *)user
             type:(NIMNetCallControlType)control{
    switch (control) {
        case NIMNetCallControlTypeFeedabck:{
            NSMutableArray *room = self.chatRoom;
            if (room && !room.count) {
                
                if (!self.callInfo.caller) {
                    return;
                }
                [room addObject:self.callInfo.caller];
                
                //40秒之后查看一下聊天室状态，如果聊天室还在一个人的话，就播放铃声超时
                __weak typeof(self) wself = self;
                uint64_t callId = self.callInfo.callID;
                NSTimeInterval delayTime = 30;//超时时间
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    NSMutableArray *room = wself.chatRoom;
                    if (wself && room && room.count == 1)
                    {
                        //如果超时后，也没有响应，房间存在，就挂断本次通话callID
                        [[NIMSDK sharedSDK].netCallManager hangup:callId];
                        wself.chatRoom = nil;
                        [self dismiss:nil];
                    }
                });
            }
            break;
        }
            
        case NIMNetCallControlTypeBusyLine:
            NSLog(@"占线");
            
            break;
        default:
            break;
    }
}

- (void)onResponse:(UInt64)callID from:(NSString *)callee accepted:(BOOL)accepted{
    
    if (self.callInfo.callID == callID) {
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (!accepted) {
                self.chatRoom = nil;
                [self dismiss:nil];
            }else{
                [self onCalling];
                [self.chatRoom addObject:callee];
            }
        });
        
    }
}


#pragma mark - Misc
//检查设备可用性
- (void)checkServiceEnable:(void(^)(BOOL))result{
    if ([[AVAudioSession sharedInstance] respondsToSelector:@selector(requestRecordPermission:)]) {
        [[AVAudioSession sharedInstance] performSelector:@selector(requestRecordPermission:) withObject:^(BOOL granted) {
            dispatch_async_main_safe(^{
                if (granted) {
                    NSString *mediaType = AVMediaTypeVideo;
                    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
                    if(authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied){
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                                        message:@"相机权限受限,无法视频聊天"
                                                                       delegate:nil
                                                              cancelButtonTitle:@"确定"
                                                              otherButtonTitles:nil];
                        [alert show];
                        
                    }else{
                        //成功，相机麦克风都可用
                        if (result) {
                            result(YES);
                        }
                    }
                }
                else {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                                    message:@"麦克风权限受限,无法聊天"
                                                                   delegate:nil
                                                          cancelButtonTitle:@"确定"
                                                          otherButtonTitles:nil];
                    [alert show];
                }
                
            });
        }];
    }
}


- (void)resetRemoteImage{
#if defined (NTESUseGLView)
    [self.remoteGLView render:nil width:0 height:0];
#endif

    self.remoteView.image = [UIImage imageNamed:@"netcall_bkg.jpg"];
}

@end
