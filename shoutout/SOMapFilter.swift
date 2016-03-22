//
//  SOMapFilter.swift
//  shoutout
//
//  Created by Mayank Jain on 3/19/16.
//  Copyright © 2016 Mayank Jain. All rights reserved.
//

import Foundation

class SOMapFilter : NSObject {
    var filterFunc: (SOAnnotation) -> Bool
    var title: String!
    
    init(filter: (SOAnnotation) -> Bool, title:String){
        self.filterFunc = filter
        self.title = title
        super.init()
    }
    
    func filterArray(array:[SOAnnotation]) -> [SOAnnotation]{
        return array.filter(self.filterFunc)
    }
}