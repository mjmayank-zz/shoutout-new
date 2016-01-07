//
//  SOBusinessPinVew.swift
//  shoutout
//
//  Created by Mayank Jain on 1/7/16.
//  Copyright © 2016 Mayank Jain. All rights reserved.
//

import UIKit

class SOBusinessPinVew: UIView {
    @IBOutlet var graphView: UIView!

    override func init{
        
        graphView = NSBundle.mainBundle().loadNibNamed("SOBusinessPinView", owner: self, options: nil).first;

        //For Pie Chart
        let items = [PNPieChartDataItem(dataItemWithValue), PNPieChartDataItem()];
        
        NSArray *items = @[[PNPieChartDataItem dataItemWithValue:10 color:[UIColor colorWithRed:0.905 green:0.0 blue:0.552 alpha:1.0]  description:@"Female"],
        [PNPieChartDataItem dataItemWithValue:20 color:PNLightBlue description:@"Male"],
        ];
        
        PNPieChart *pieChart = [[PNPieChart alloc] initWithFrame:CGRectMake(110.0, 10.0, 100.0, 100.0) items:items];
        pieChart.descriptionTextColor = [UIColor whiteColor];
        pieChart.descriptionTextFont  = [UIFont fontWithName:@"Avenir-Medium" size:14.0];
        [pieChart strokeChart];
        [self.businessSubview addSubview:pieChart];
    }
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

}
