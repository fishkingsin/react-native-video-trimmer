#import "RNVideoTrimmer.h"
#import <React/RCTConvert.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>
#import <React/RCTUtils.h>
#import "VideoTrimerViewController.h"
@import Photos;
@interface RNVideoTrimmer ()

@property (nonatomic, strong) RCTResponseSenderBlock callback;
@property (nonatomic, strong) NSDictionary *defaultOptions;
@property (nonatomic, retain) NSMutableDictionary *options, *response;
@property (nonatomic, strong) NSArray *customButtons;

@end


@implementation RNVideoTrimmer

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(showVideoTrimmer:(NSDictionary *)options callback:(RCTResponseSenderBlock)callback)
{
    self.callback = callback; // Save the callback so we can use it from the delegate methods
    self.options = [NSMutableDictionary dictionaryWithDictionary:options];


    NSString *assetID = @"";


    assetID = [self.options[@"uri"] substringFromIndex:@"ph://".length];

    PHFetchResult *results;
    results = [PHAsset fetchAssetsWithLocalIdentifiers:@[assetID] options:nil];
    if (results.count == 0) {
        NSString *errorText = [NSString stringWithFormat:@"Failed to fetch PHAsset with local identifier %@ with no error message.", assetID];
        self.callback(@[@{@"error": errorText}]);
    }


    NSBundle *podBundle = [NSBundle bundleForClass:[VideoTrimerViewController class]];
    id data = [podBundle URLForResource:@"RNVideoTrimmer" withExtension:@"bundle"];
    NSBundle *bundle = [NSBundle bundleWithURL:data];
    VideoTrimerViewController *vc = [[VideoTrimerViewController alloc]initWithNibName:@"VideoTrimerViewController" bundle:bundle];

    dispatch_async(dispatch_get_main_queue(), ^{
        UIViewController *root = RCTPresentedViewController();
        [root presentViewController:vc animated:YES completion:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [vc setupAsset:assetID];
            });
        }];
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

@end
