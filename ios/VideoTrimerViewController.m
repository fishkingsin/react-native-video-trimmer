
//
//  VideoTrimerViewController.m
//  RNVideoTrimmer
//
//  Created by James Kong on 11/9/2018.
//  Copyright © 2018 Creedon Technologies. All rights reserved.
//

#import "VideoTrimerViewController.h"
#import "ICGVideoTrimmerView.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <AVFoundation/AVFoundation.h>
@import Photos;
@interface VideoTrimerViewController () <ICGVideoTrimmerDelegate>

@property (assign, nonatomic) BOOL isPlaying;
@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) AVPlayerItem *playerItem;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;
@property (strong, nonatomic) NSTimer *playbackTimeCheckerTimer;
@property (assign, nonatomic) CGFloat videoPlaybackPosition;

@property (weak, nonatomic) IBOutlet ICGVideoTrimmerView *trimmerView;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;

@property (weak, nonatomic) IBOutlet UIView *videoPlayer;
@property (weak, nonatomic) IBOutlet UIView *videoLayer;

@property (assign, nonatomic) CGFloat startTime;
@property (assign, nonatomic) CGFloat stopTime;

@property (strong, nonatomic) AVAsset *asset;

@property (assign, nonatomic) BOOL restartOnPlay;
@end

@implementation VideoTrimerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidAppear:(BOOL)animated{

}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void) setupAsset:(NSString *)localIdentifier {
    if( localIdentifier == nil) {
        return;
    }

    PHFetchResult *results;
    results = [PHAsset fetchAssetsWithLocalIdentifiers:@[localIdentifier] options:nil];
    if (results.count == 0) {
        NSString *errorText = [NSString stringWithFormat:@"Failed to fetch PHAsset with local identifier %@ with no error message.", localIdentifier];
    }

    PHAsset *asset = [results firstObject];
    PHVideoRequestOptions *videoRequestOptions = [PHVideoRequestOptions new];
    videoRequestOptions.networkAccessAllowed = YES;
    // TOD show loading
    [[PHImageManager defaultManager] requestAVAssetForVideo:asset options:videoRequestOptions resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
        if (asset != nil) {
            self.asset = asset;

            AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:self.asset];

            self.player = [AVPlayer playerWithPlayerItem:item];
            self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
            self.playerLayer.contentsGravity = AVLayerVideoGravityResizeAspect;
            self.player.actionAtItemEnd = AVPlayerActionAtItemEndNone;

            [self.videoLayer.layer addSublayer:self.playerLayer];

            UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnVideoLayer:)];
            [self.videoLayer addGestureRecognizer:tap];

            self.videoPlaybackPosition = 0;

            [self tapOnVideoLayer:tap];

            // set properties for trimmer view
            [self.trimmerView setThemeColor:[UIColor lightGrayColor]];
            [self.trimmerView setAsset:self.asset];
            [self.trimmerView setShowsRulerView:YES];
            [self.trimmerView setRulerLabelInterval:10];
            [self.trimmerView setTrackerColor:[UIColor cyanColor]];
            [self.trimmerView setDelegate:self];

            // important: reset subviews
            [self.trimmerView resetSubviews];
        } else {
            NSString *errorText = [NSString stringWithFormat:@"Failed to fetch video with local identifier %@ with no error message.", localIdentifier];
            //            self.callback(@[@{@"error": errorText}]);
        }
    }];
}
- (IBAction)onCancelPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onDonePressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - ICGVideoTrimmerDelegate

- (void)trimmerView:(ICGVideoTrimmerView *)trimmerView didChangeLeftPosition:(CGFloat)startTime rightPosition:(CGFloat)endTime
{
    _restartOnPlay = YES;
    [self.player pause];
    self.isPlaying = NO;
    [self stopPlaybackTimeChecker];

    [self.trimmerView hideTracker:true];

    if (startTime != self.startTime) {
        //then it moved the left position, we should rearrange the bar
        [self seekVideoToPos:startTime];
    }
    else{ // right has changed
        [self seekVideoToPos:endTime];
    }
    self.startTime = startTime;
    self.stopTime = endTime;

}

- (void)viewDidLayoutSubviews
{
    self.playerLayer.frame = CGRectMake(0, 0, self.videoLayer.frame.size.width, self.videoLayer.frame.size.height);
}

- (void)tapOnVideoLayer:(UITapGestureRecognizer *)tap
{
    if (self.isPlaying) {
        [self.player pause];
        [self stopPlaybackTimeChecker];
    }else {
        if (_restartOnPlay){
            [self seekVideoToPos: self.startTime];
            [self.trimmerView seekToTime:self.startTime];
            _restartOnPlay = NO;
        }
        [self.player play];
        [self startPlaybackTimeChecker];
    }
    self.isPlaying = !self.isPlaying;
    [self.trimmerView hideTracker:!self.isPlaying];
}

- (void)startPlaybackTimeChecker
{
    [self stopPlaybackTimeChecker];

    self.playbackTimeCheckerTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(onPlaybackTimeCheckerTimer) userInfo:nil repeats:YES];
}

- (void)stopPlaybackTimeChecker
{
    if (self.playbackTimeCheckerTimer) {
        [self.playbackTimeCheckerTimer invalidate];
        self.playbackTimeCheckerTimer = nil;
    }
}

#pragma mark - PlaybackTimeCheckerTimer

- (void)onPlaybackTimeCheckerTimer
{
    CMTime curTime = [self.player currentTime];
    Float64 seconds = CMTimeGetSeconds(curTime);
    if (seconds < 0){
        seconds = 0; // this happens! dont know why.
    }
    self.videoPlaybackPosition = seconds;

    [self.trimmerView seekToTime:seconds];

    if (self.videoPlaybackPosition >= self.stopTime) {
        self.videoPlaybackPosition = self.startTime;
        [self seekVideoToPos: self.startTime];
        [self.trimmerView seekToTime:self.startTime];
    }
}

- (void)seekVideoToPos:(CGFloat)pos
{
    self.videoPlaybackPosition = pos;
    CMTime time = CMTimeMakeWithSeconds(self.videoPlaybackPosition, self.player.currentTime.timescale);
    //NSLog(@"seekVideoToPos time:%.2f", CMTimeGetSeconds(time));
    [self.player seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
}


@end
