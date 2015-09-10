//
//  SOAnnotation.m
//  shoutout
//
//  Created by Mayank Jain on 9/3/15.
//  Copyright (c) 2015 Mayank Jain. All rights reserved.
//

#import "SOAnnotation.h"

@implementation SOAnnotation

-(id)initWithTitle:(NSString *)title Subtitle:(NSString *)subtitle Location:(CLLocationCoordinate2D)coordinate{
    self = [super init];
    
    if(self){
        _title = title;
        _coordinate = coordinate;
        _subtitle = subtitle;
    }
    
    return self;
}

- (void)setCoordinate:(CLLocationCoordinate2D)newCoordinate{
    _coordinate = newCoordinate;
}

@end
