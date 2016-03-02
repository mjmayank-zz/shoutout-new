//
//  SOMarkerSubView.m
//  shoutout
//
//  Created by Mayank Jain on 10/3/15.
//  Copyright © 2015 Mayank Jain. All rights reserved.
//

#import "SOMarkerSubView.h"
#import "ShoutRMMarker.h"

@implementation SOMarkerSubView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (IBAction)pressedMarkerButton:(id)sender {
    self.messageOverlayView.hidden = NO;
}
- (IBAction)pressedMessageButton:(id)sender {
    if(self.superview){
        ShoutRMMarker * marker = (ShoutRMMarker *)self.superview;
        [marker sendMessage];
    }
    [PFAnalytics trackEvent:@"pressedMessageFromPin" dimensions:nil];
}

@end