
//
//  VideoTrimmerViewController.m
//  RNVideoTrimmer
//
//  Created by James Kong on 11/9/2018.
//  Copyright © 2018 Creedon Technologies. All rights reserved.
//

#import "VideoTrimmerViewController.h"
#import "ICGVideoTrimmerView.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <AVFoundation/AVFoundation.h>
#define DEFAULT_THEME [UIColor colorWithRed:0.28 green:0.60 blue:0.87 alpha:1.0]
#define EDITED_THEME [UIColor colorWithRed:0.94 green:0.68 blue:0.31 alpha:1.0]
#define DEFAULT_LENGTH 15
@import Photos;
@interface VideoTrimmerViewController () <ICGVideoTrimmerDelegate>

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
@property (weak, nonatomic) IBOutlet UILabel *durationLabel;
@property (weak, nonatomic) IBOutlet UILabel *rangeLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *progressBar;

@property (assign, nonatomic) CGFloat startTime;
@property (assign, nonatomic) CGFloat stopTime;

@property (strong, nonatomic) AVAsset *asset;
@property (nonatomic, assign) PHImageRequestID assetRequestID;
@property (assign, nonatomic) BOOL restartOnPlay;
@end

@implementation VideoTrimmerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidAppear:(BOOL)animated{
    
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    if (_assetRequestID != PHInvalidImageRequestID) {
        
        [[PHImageManager defaultManager] cancelImageRequest:_assetRequestID];
        _assetRequestID = PHInvalidImageRequestID;
        
    }
    if(self.player) {
        [self.player removeObserver:self forKeyPath:@"status"];
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {
    if (object == self.player && [keyPath isEqualToString:@"status"]) {
        if (self.player.status == AVPlayerStatusReadyToPlay) {
            NSLog(@"AVPlayerStatusReadyToPlay");
        } else if (self.player.status == AVPlayerStatusFailed) {
            NSLog(@"AVPlayerStatusFailed");
            // something went wrong. player.error should contain some information
        }
    }
}
-(void) setupAsset:(NSString *)localIdentifier {
    if( localIdentifier == nil) {
        return;
    }
    
    PHFetchResult *results;
    results = [PHAsset fetchAssetsWithLocalIdentifiers:@[localIdentifier] options:nil];
    if (results.count == 0) {
        NSString *errorText = [NSString stringWithFormat:@"Failed to fetch PHAsset with local identifier %@ with no error message.", localIdentifier];
        if([self.delegate respondsToSelector:@selector(videoTrimmerViewController:didFailedWithError:)])
        {
            NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey : errorText}];
            [self.delegate videoTrimmerViewController:self didFailedWithError:error];
        }
    }
    
    PHAsset *phAsset = [results firstObject];
    PHVideoRequestOptions *options = [self getVideoRequestOptions];
    [self.progressBar setHidden:YES];
    options.progressHandler = ^(double progress, NSError * _Nullable error, BOOL * _Nonnull stop, NSDictionary * _Nullable info) {
        if(error) {
            if([self.delegate respondsToSelector:@selector(videoTrimmerViewController:didFailedWithError:)])
            {
                [self.delegate videoTrimmerViewController:self didFailedWithError:error];
            }
        } else {
            //do progress bar
            dispatch_async(dispatch_get_main_queue(), ^{
                if(progress < 1.0) {
                    [self.progressBar setHidden:NO];
                    [self.progressBar setProgress:progress];
                } else {
                    [self.progressBar setHidden:YES];
                }
            });
        }
    };
    __weak __typeof(self) weakSelf = self;
    self.assetRequestID = [[PHImageManager defaultManager] requestAVAssetForVideo:phAsset options:options resultHandler:^(AVAsset * _Nullable avAsset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
        if(weakSelf.assetRequestID == PHInvalidImageRequestID){
            return;
        }
        if (avAsset != nil) {
            if([avAsset isKindOfClass:[AVURLAsset class]]){
                weakSelf.asset = [AVURLAsset assetWithURL:((AVURLAsset*)avAsset).URL];
            } else if (avAsset){
                weakSelf.asset = avAsset;
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.progressBar setHidden:YES];
                AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:weakSelf.asset];
                weakSelf.player = [AVPlayer playerWithPlayerItem:item];
                [weakSelf.player addObserver:weakSelf forKeyPath:@"status" options:0 context:nil];
                weakSelf.playerLayer = [AVPlayerLayer playerLayerWithPlayer:weakSelf.player];
                weakSelf.playerLayer.contentsGravity = AVLayerVideoGravityResizeAspect;
                weakSelf.player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
                NSLog(@"videoLayer %@", NSStringFromCGRect(weakSelf.videoLayer.bounds));
                [weakSelf.videoLayer.layer addSublayer:weakSelf.playerLayer];
                weakSelf.playerLayer.frame = CGRectMake(0, 0, weakSelf.videoLayer.frame.size.width, weakSelf.videoLayer.frame.size.height);
                NSLog(@"playerLayer %@", NSStringFromCGRect(weakSelf.playerLayer.bounds));
                UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:weakSelf action:@selector(tapOnVideoLayer:)];
                [weakSelf.videoLayer addGestureRecognizer:tap];
                
                Float64 duration = CMTimeGetSeconds(weakSelf.asset.duration);
                
                weakSelf.stopTime = duration < weakSelf.maxLength ? duration : weakSelf.maxLength ;
                weakSelf.startTime = 0;
                
                weakSelf.videoPlaybackPosition = 0;
                
                //                [self tapOnVideoLayer:tap];
                
                // set properties for trimmer view
                [weakSelf.trimmerView setThemeColor: DEFAULT_THEME];
                [weakSelf.trimmerView setAsset:weakSelf.asset];
                [weakSelf.trimmerView setShowsRulerView:NO];
                //                [weakSelf.trimmerView setRulerLabelInterval:10];
                [weakSelf.trimmerView setTrackerColor:[UIColor whiteColor]];
                [weakSelf.trimmerView setDelegate:weakSelf];
                [weakSelf.trimmerView setMaxLength: weakSelf.maxLength ];
                [weakSelf.trimmerView setMinLength: weakSelf.minLength ];
                [weakSelf.trimmerView setThumbWidth:12];
                
                // important: reset subviews
                [weakSelf.trimmerView resetSubviews];
            });
        } else {
            NSString *errorText = [NSString stringWithFormat:@"Failed to fetch video with local identifier %@ with no error message.", localIdentifier];
            if([weakSelf.delegate respondsToSelector:@selector(videoTrimmerViewController:didFailedWithError:)])
            {
                NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey : errorText}];
                [weakSelf.delegate videoTrimmerViewController:self didFailedWithError:error];
            }
        }
    }];
}


-(PHVideoRequestOptions *)getVideoRequestOptions {
    PHVideoRequestOptions *videoRequestOptions = [PHVideoRequestOptions new];
    videoRequestOptions.networkAccessAllowed = YES;
    PHVideoRequestOptionsDeliveryMode deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
    deliveryMode = PHVideoRequestOptionsDeliveryModeHighQualityFormat;
    videoRequestOptions.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
    videoRequestOptions.version = PHVideoRequestOptionsVersionCurrent;
    return videoRequestOptions;
}
- (IBAction)onCancelPressed:(id)sender {
    [[PHImageManager defaultManager] cancelImageRequest: self.assetRequestID];
    if (self.isPlaying) {
        [self.player pause];
        [self stopPlaybackTimeChecker];
        self.isPlaying = NO;
    }
    [self dismissViewControllerAnimated:YES completion:nil];
    if([self.delegate respondsToSelector:@selector(didFinishVideoTrimmerViewController:)])
    {
        [self.delegate didFinishVideoTrimmerViewController:self];
    }
}

- (IBAction)onDonePressed:(id)sender {
    if (self.isPlaying) {
        [self.player pause];
        [self stopPlaybackTimeChecker];
        self.isPlaying = NO;
    }
    [self dismissViewControllerAnimated:YES completion:nil];
    if([self.delegate respondsToSelector:@selector(didFinishVideoTrimmerViewController:withStartTime:endTime:)])
    {
        [self.delegate didFinishVideoTrimmerViewController:self withStartTime:self.startTime endTime:self.stopTime];
    }
}


#pragma mark - ICGVideoTrimmerDelegate

- (void)trimmerView:(nonnull ICGVideoTrimmerView *)trimmerView didChangeLeftPosition:(CGFloat)startTime rightPosition:(CGFloat)endTime trimmerViewContentOffset:(CGPoint)trimmerViewContentOffset
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
    
    if( fabs(self.startTime - startTime) < 0.01 && fabs(self.stopTime - endTime) < 0.01 ){
        //        [trimmerView setThemeColor:DEFAULT_THEME];
        //        [self.doneButton setEnabled:NO];
    } else {
        [trimmerView setThemeColor:EDITED_THEME];
        [self.doneButton setEnabled:YES];
        
    }
    self.startTime = startTime;
    self.stopTime = endTime;
    
    [self.durationLabel setText: [self timeFormatted:self.stopTime-self.startTime]];
    [self.rangeLabel setText:[NSString stringWithFormat:@"%@ to %@", [self timeFormatted:self.startTime], [self timeFormatted:self.stopTime]]];
}

- (void)trimmerViewDidEndEditing:(nonnull ICGVideoTrimmerView *)trimmerView{
    NSLog(@"trimmerViewDidEndEditing");
}

-(NSString*) timeFormatted:(CGFloat) sec{
    
    int totalSeconds = roundf(sec);
    int seconds = totalSeconds % 60;
    int minutes = (totalSeconds / 60) % 60;
    
    return [NSString stringWithFormat:@"%02d:%02d", minutes, seconds];
}

-(void) setVideoRangeLabelWithSring:(NSString*) msg{
    
    //    [self.timeRangeLabel setText:[NSString stringWithFormat:HINTS_MESSAGE,@(DEFAULT_VIDEO_LENGTH)]];
    
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
        [self.player pause];
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
