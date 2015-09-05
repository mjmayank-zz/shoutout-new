//
//  SOAnnotation.h
//  shoutout
//
//  Created by Mayank Jain on 9/3/15.
//  Copyright (c) 2015 Mayank Jain. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Mapbox/Mapbox.h>

@interface SOAnnotation : MGLPointAnnotation

@property (strong, nonatomic) NSDictionary *userInfo;
@property (strong, nonatomic) UIImage *image;

@end
