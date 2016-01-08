//
//  UIImage+ColorMask.h
//  shoutout
//
//  Created by Mayank Jain on 1/24/16.
//  Copyright © 2016 Mayank Jain. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (ColorMask)

+ (UIImage *)imageNamed:(NSString *)name withColor:(UIColor *)color;
+ (UIImage *)imageNamed:(NSString *)name withGradientColor:(UIColor *)tintColor;

@end
