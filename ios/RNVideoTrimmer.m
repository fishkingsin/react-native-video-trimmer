#import "RNVideoTrimmer.h"
#import <React/RCTConvert.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>
#import <React/RCTUtils.h>
#import "VideoTrimmerViewController.h"
#import "AVAsset+VideoOrientation.h"
#import "SDAVAssetExportSession.h"
#define DEFAULT_VIDEO_LENGTH 15
@import Photos;
@interface RNVideoTrimmer () <VideoTrimmerViewDelegate>

@property (nonatomic, strong) RCTResponseSenderBlock callback;
@property (nonatomic, strong) NSDictionary *defaultOptions;
@property (nonatomic, retain) NSMutableDictionary *options, *response;
@property (nonatomic, strong) NSArray *customButtons;
@property (nonatomic, strong) SDAVAssetExportSession* exportSession;
@property (nonatomic, assign) BOOL cancelExport;
@end


@implementation RNVideoTrimmer

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(showVideoTrimmer:(NSDictionary *)options callback:(RCTResponseSenderBlock)callback)
{
    self.callback = callback; // Save the callback so we can use it from the delegate methods
    self.options = [NSMutableDictionary dictionaryWithDictionary:options];

    NSString *assetID = @"";
    NSString *uri = self.options[@"uri"];

    assetID = [uri substringFromIndex:@"ph://".length];
    float maxLength = 15;
    float minLength = 0;
    if(self.options[@"maxLength"]){
        maxLength = [self.options[@"maxLength"] floatValue];
    }
    if(self.options[@"minLength"]){
        minLength = [self.options[@"minLength"] floatValue];
    }
    PHFetchResult *results;
    results = [PHAsset fetchAssetsWithLocalIdentifiers:@[assetID] options:nil];
    PHAsset *result;
    if([uri hasPrefix:@"ph://"]){
        assetID = [uri substringFromIndex:@"ph://".length];
        result = [PHAsset fetchAssetsWithLocalIdentifiers:@[assetID] options:nil].lastObject;
    } else if ([uri hasPrefix:@"assets-library://"]){
        result = [PHAsset fetchAssetsWithALAssetURLs:@[[NSURL URLWithString:uri]] options:nil].lastObject;
        assetID = result.localIdentifier;
    }
    if (result == nil) {
        NSString *errorText = [NSString stringWithFormat:@"Failed to fetch PHAsset with local identifier %@ with no error message.", assetID];
        self.callback(@[@{@"error": errorText}]);
        self.callback = nil;
        return;
    }


    NSBundle *podBundle = [NSBundle bundleForClass:[VideoTrimmerViewController class]];
    VideoTrimmerViewController *vc;
    NSBundle *bundle;
    id data = [podBundle URLForResource:@"RNVideoTrimmer" withExtension:@"bundle"];
    if(data != nil) {
        bundle = [NSBundle bundleWithURL:data];
    } else {
        bundle = podBundle;
    }
    vc = [[VideoTrimmerViewController alloc]initWithNibName:@"VideoTrimmerViewController" bundle:bundle];
    [vc setDelegate:self];
	[vc setMaxLength: maxLength];
    [vc setMinLength: minLength];
    dispatch_async(dispatch_get_main_queue(), ^{
        [vc setupAsset:assetID];
        UIViewController *root = RCTPresentedViewController();
        [root presentViewController:vc animated:YES completion:nil];
    });


}

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

+ (BOOL)requiresMainQueueSetup
{
    return YES;
}

#pragma VideoTrimerViewDelegate
- (void)VideoTrimmerViewController:(nonnull VideoTrimmerViewController *)videoTrimmerController didChangeStartTime:(Float64)startTime endTime:(Float64)endTime{
    NSLog(@"VideoTrimmerViewController didChangeStartTime %f %f", startTime, endTime);
}
- (void)didFinishVideoTrimmerViewController:(nonnull VideoTrimmerViewController *)videoTrimmerController withStartTime:(Float64)startTime endTime:(Float64)endTime avasset:(AVAsset*) avasset{
    NSLog(@"didFinishVideoTrimmerViewController withStartTime endTime %f %f", startTime, endTime);
    if([self.options[@"save"] boolValue]) {

        CMTimeScale timeScale = avasset.duration.timescale;
        CMTimeScale lowtiemScale = 24;
        timeScale = lowtiemScale;
        NSString* docsPath = [NSTemporaryDirectory()stringByStandardizingPath];
        NSString *filePath = [NSString stringWithFormat:@"%@/%@.%@", docsPath, [[NSUUID UUID] UUIDString], @"mp4"];
        NSURL *furl = [NSURL URLWithString:filePath];
        CMTime start = CMTimeMakeWithSeconds(startTime, timeScale);
        CMTime tempDuration = CMTimeMakeWithSeconds(endTime - startTime, timeScale);
        float tempDurationSecond = CMTimeGetSeconds(tempDuration);
        float assetDuration = CMTimeGetSeconds(avasset.duration);
        CMTime fifteen = CMTimeMakeWithSeconds( DEFAULT_VIDEO_LENGTH, timeScale);
        CMTime duration = (tempDurationSecond > 1 && tempDurationSecond < DEFAULT_VIDEO_LENGTH) ? tempDuration : (assetDuration < DEFAULT_VIDEO_LENGTH ) ? avasset.duration : fifteen;
        
        
        CMTimeRange range = CMTimeRangeMake(start, duration);
        NSArray *tracks = [avasset tracksWithMediaType:AVMediaTypeVideo];
        AVAssetTrack *track = [tracks objectAtIndex:0];
        CGSize mediaSize = track.naturalSize;
        NSString *videoType = @"normal";
        CGSize mediaResize =mediaSize;
        NSString * orientationString = @"unknown";
        {
            
            CGFloat scale  = mediaSize.width > mediaSize.height ? 1280.0f/mediaSize.width : 1280.0f/mediaSize.height;
            scale = scale > 1.0 ? 1.0 : scale;
            
            LBVideoOrientation orientation = [avasset videoOrientation];
            
            switch(orientation){
                case LBVideoOrientationUp:
                    orientationString = @"up";
                    break;
                case LBVideoOrientationDown:
                    orientationString = @"down";
                    break;
                case LBVideoOrientationLeft:
                    orientationString = @"left";
                    break;
                case LBVideoOrientationRight:
                    orientationString = @"right";
                    break;
                case LBVideoOrientationNotFound:
                    orientationString = @"notfound";
                    break;
            }
            float letterBoxWidth = 0;
            mediaResize = (orientation == LBVideoOrientationUp || orientation == LBVideoOrientationDown ) ?
            (mediaSize.width > mediaSize.height ? CGSizeMake(mediaSize.height*scale+letterBoxWidth, mediaSize.width*scale) : CGSizeMake(mediaSize.width*scale+letterBoxWidth, mediaSize.height*scale))
            : CGSizeMake(mediaSize.width*scale, mediaSize.height*scale);
        }
        __block NSDictionary *metaDic = @{
                                          @"duration": @((int)((CMTimeGetSeconds(duration)*1000))),
                                          @"width": @((int)mediaSize.width),
                                          @"height":@((int)mediaSize.height),
                                          @"originalDuration":@((int)(CMTimeGetSeconds(avasset.duration)*1000)),
                                          @"videoType":videoType,
                                          @"orientation": orientationString
                                          };
        if(self.exportSession != nil) {
            [self.exportSession cancelExport];
            self.exportSession = nil;
        }
        self.exportSession = [[SDAVAssetExportSession alloc] initWithAsset:avasset ];
        self.exportSession.shouldOptimizeForNetworkUse = YES;
        self.exportSession.outputFileType = AVFileTypeMPEG4;
        self.exportSession.outputURL = furl;
        self.exportSession.timeRange = range;
        self.exportSession.shouldOptimizeForNetworkUse = YES;
#if TARGET_IPHONE_SIMULATOR
        NSDictionary * compressionPropertiesKey = @{
                                                    AVVideoAverageBitRateKey: @5000000,
                                                    AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
                                                    AVVideoExpectedSourceFrameRateKey: @(24),
                                                    AVVideoMaxKeyFrameIntervalKey:@(24), // Nixplay Frame specfic
                                                    };
#else
        NSDictionary * compressionPropertiesKey = @{
                                                    AVVideoAverageBitRateKey: @5000000,
                                                    AVVideoProfileLevelKey: AVVideoProfileLevelH264High40,
                                                    AVVideoExpectedSourceFrameRateKey: @(24),
                                                    AVVideoMaxKeyFrameIntervalKey:@(24), // Nixplay Frame specfic
                                                    };
#endif
        
        self.exportSession.videoSettings = @
        {
        AVVideoCodecKey: AVVideoCodecH264,
        AVVideoWidthKey: @(mediaResize.width),
        AVVideoHeightKey: @(mediaResize.height),
        AVVideoCompressionPropertiesKey: compressionPropertiesKey,
        };
        self.exportSession.audioSettings = @
        {
        AVFormatIDKey: @(kAudioFormatMPEG4AAC),
        AVNumberOfChannelsKey: @2,
        AVSampleRateKey: @44100,
        AVEncoderBitRateKey: @128000,
        };
        
        dispatch_semaphore_t sessionWaitSemaphore = dispatch_semaphore_create(0);
        
        void (^completionHandler)(void) = ^(void)
        {
            dispatch_semaphore_signal(sessionWaitSemaphore);
        };
        
        
        [self.exportSession exportAsynchronouslyWithCompletionHandler:completionHandler];
        do {
            dispatch_time_t dispatchTime = DISPATCH_TIME_FOREVER;  // if we dont want progress, we will wait until it finishes.
            dispatchTime = getDispatchTimeFromSeconds((float)1.0);
            double progress = [self.exportSession progress];
            if(self.cancelExport){
                
            }else{
                
            }
            dispatch_semaphore_wait(sessionWaitSemaphore, dispatchTime);
        } while( [self.exportSession status] < AVAssetExportSessionStatusCompleted && !self.cancelExport);
        
        switch ([self.exportSession status]) {
            case AVAssetExportSessionStatusFailed:
                break;
            case AVAssetExportSessionStatusWaiting:
                
                break;
            case AVAssetExportSessionStatusExporting:
                
                break;
            case AVAssetExportSessionStatusUnknown:
                break;
            case AVAssetExportSessionStatusCancelled:
                break;
            case AVAssetExportSessionStatusCompleted:
            {
                unsigned long long fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil] fileSize];
                NSMutableDictionary *response = [NSMutableDictionary dictionary];
                [response setObject:filePath forKey:@"fullFilePath"];
                [response setValue:@(fileSize) forKey:@"fileSize"];
            }
                break;
        }
        
    } else {
        if(self.callback != nil) {
            self.callback(@[@{
                                @"uri":self.options[@"uri"],
                                @"startTime":@(startTime),
                                @"endTime":@(endTime)
                                }]);
            self.callback = nil;
        }
    }
}
- (void)didFinishVideoTrimmerViewController:(nonnull VideoTrimmerViewController *)videoTrimmerController{
    NSLog(@"didFinishVideoTrimmerViewController");
    if(self.callback != nil) {
        self.callback(@[@{@"error": @"user cancel"}]);
        self.callback = nil;
    }
}
- (void)VideoTrimmerViewController:(nonnull VideoTrimmerViewController *)videoTrimmerController didFailedWithError:(NSError *)error{
    if(self.callback != nil) {
        self.callback(@[@{@"error": error.localizedDescription}]);
        self.callback = nil;
    }
}

static dispatch_time_t getDispatchTimeFromSeconds(float seconds) {
    long long milliseconds = seconds * 1000.0;
    dispatch_time_t waitTime = dispatch_time( DISPATCH_TIME_NOW, 1000000LL * milliseconds );
    return waitTime;
}


@end
