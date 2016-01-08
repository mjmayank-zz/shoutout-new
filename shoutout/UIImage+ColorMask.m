//
//  UIImage+ColorMask.m
//  shoutout
//
//  Created by Mayank Jain on 1/24/16.
//  Copyright © 2016 Mayank Jain. All rights reserved.
//

#import "UIImage+ColorMask.h"

@implementation UIImage (ColorMask)

+ (UIImage *)imageNamed:(NSString *)name withColor:(UIColor *)color{
    // load the image
    UIImage *img = [UIImage imageNamed:name];
    
    return [UIImage tintedImage:img withColor:color blendingMode:kCGBlendModeDestinationIn];
}

+ (UIImage *)imageNamed:(NSString *)name withGradientColor:(UIColor *)tintColor
{
    UIImage *img = [UIImage imageNamed:name];
    return [UIImage tintedImage:img withColor:tintColor blendingMode:kCGBlendModeOverlay];
}

+ (UIImage *)tintedImage:(UIImage *)img withColor:(UIColor *)tintColor blendingMode:(CGBlendMode)blendMode
{
    //https://robots.thoughtbot.com/designing-for-ios-blending-modes
    UIGraphicsBeginImageContextWithOptions(img.size, NO, 0.0f);
    [tintColor setFill];
    CGRect bounds = CGRectMake(0, 0, img.size.width, img.size.height);
    UIRectFill(bounds);
    [img drawInRect:bounds blendMode:blendMode alpha:1.0f];
    
    if (blendMode != kCGBlendModeDestinationIn)
        [img drawInRect:bounds blendMode:kCGBlendModeDestinationIn alpha:1.0];
    
    UIImage *tintedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return tintedImage;
}

@end
