//
//  VideoTrimmerViewController.h
//  RNVideoTrimmer
//
//  Created by James Kong on 11/9/2018.
//  Copyright © 2018 Creedon Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol VideoTrimmerViewDelegate;
@interface VideoTrimmerViewController : UIViewController
@property (weak, nonatomic, nullable) id<VideoTrimmerViewDelegate> delegate;
@property (assign, nonatomic) Float64 maxLength;
@property (assign, nonatomic) Float64 minLength;
-(void) setupAsset:(NSString *)localIdentifier;
@end


@protocol VideoTrimmerViewDelegate <NSObject>

@optional
- (void)videoTrimmerViewController:(nonnull VideoTrimmerViewController *)videoTrimmerController didChangeStartTime:(Float64)startTime endTime:(Float64)endTime;
- (void)didFinishVideoTrimmerViewController:(nonnull VideoTrimmerViewController *)videoTrimmerController withStartTime:(Float64)startTime endTime:(Float64)endTime;
- (void)didFinishVideoTrimmerViewController:(nonnull VideoTrimmerViewController *)videoTrimmerController;
- (void)videoTrimmerViewController:(nonnull VideoTrimmerViewController *)videoTrimmerController didFailedWithError:(NSError *)error;
@end
