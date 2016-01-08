//
//  PNFilledPieChart.swift
//  shoutout
//
//  Created by Mayank Jain on 1/8/16.
//  Copyright © 2016 Mayank Jain. All rights reserved.
//

import UIKit

class PNFilledPieChart: PNPieChart {

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

    override func recompute() {
        self.outerCircleRadius = CGRectGetWidth(self.bounds) / 2;
        self.innerCircleRadius = 0;
    }
}
