//
//  AVAsset+VideoOrientation.m
//
//  Created by Luca Bernardi on 19/09/12.
//  Copyright (c) 2012 Luca Bernardi. All rights reserved.
//

#import "AVAsset+VideoOrientation.h"


static inline CGFloat RadiansToDegrees(CGFloat radians) {
    return radians * 180 / M_PI;
};

@implementation AVAsset (VideoOrientation)
@dynamic videoOrientation;

- (LBVideoOrientation)  videoOrientation
{
    NSArray *videoTracks = [self tracksWithMediaType:AVMediaTypeVideo];
    if ([videoTracks count] == 0) {
        return LBVideoOrientationNotFound;
    }
    
    AVAssetTrack* videoTrack    = [videoTracks objectAtIndex:0];
    CGSize mediaSize = videoTrack.naturalSize;
    CGAffineTransform txf       = [videoTrack preferredTransform];
    CGFloat videoAngleInDegree  = RadiansToDegrees(atan2(txf.b, txf.a));
    
    LBVideoOrientation orientation = LBVideoOrientationUp;
    switch ((int)videoAngleInDegree) {
        case 0:
            if(mediaSize.width > mediaSize.height) orientation = LBVideoOrientationRight;
            else orientation = LBVideoOrientationUp;
            break;
        case 90:
            if(mediaSize.width > mediaSize.height) orientation = LBVideoOrientationUp;
            else orientation = LBVideoOrientationLeft;
            break;
        case 180:
            if(mediaSize.width > mediaSize.height) orientation = LBVideoOrientationLeft;
            else orientation = LBVideoOrientationRight;
            break;
        case -90:
            if(mediaSize.width > mediaSize.height) orientation	= LBVideoOrientationDown;
            else orientation = LBVideoOrientationDown;
            break;
        default:
            orientation = LBVideoOrientationNotFound;
            break;
    }
    
    return orientation;
}

@end
