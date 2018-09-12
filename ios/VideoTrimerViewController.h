//
//  VideoTrimerViewController.h
//  RNVideoTrimmer
//
//  Created by James Kong on 11/9/2018.
//  Copyright © 2018 Creedon Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol VideoTrimerViewDelegate;
@interface VideoTrimerViewController : UIViewController
@property (weak, nonatomic, nullable) id<VideoTrimerViewDelegate> delegate;
@property (assign, nonatomic) Float64 maxLength;
-(void) setupAsset:(NSString *)localIdentifier;
@end


@protocol VideoTrimerViewDelegate <NSObject>

@optional
- (void)videoTrimerViewController:(nonnull VideoTrimerViewController *)videoTrimmerController didChangeStartTime:(Float64)startTime endTime:(Float64)endTime;
- (void)didFinishVideoTrimerViewController:(nonnull VideoTrimerViewController *)videoTrimmerController withStartTime:(Float64)startTime endTime:(Float64)endTime;
- (void)didFinishVideoTrimerViewController:(nonnull VideoTrimerViewController *)videoTrimmerController;
- (void)videoTrimerViewController:(nonnull VideoTrimerViewController *)videoTrimmerController didFailedWithError:(NSError *)error;
@end
