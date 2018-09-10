
#import "RNVideoTrimmer.h"

@implementation RNVideoTrimmer

RCT_EXPORT_MODULE()

- (UIView *)view
{
    return [[ICGVideoTrimmerView alloc] init];
}

@end
  
