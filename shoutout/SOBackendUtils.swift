//
//  BackendUtils.swift
//  shoutout
//
//  Created by Mehul Goyal on 3/8/16.
//  Copyright © 2016 Mayank Jain. All rights reserved.
//

class SOBackendUtils : NSObject {
    
    class func incrementScore(value: Int) {
        var score : Int
        if let currScore = PFUser.currentUser()?["score"] as? Int{
            score = currScore + value;
            
        }
        else{
            score = value
        }
        PFUser.currentUser()?.setValue(score, forKey: "score");
        PFUser.currentUser()?.saveInBackground();
        let shoutoutRootScore = Firebase(url: "https://shoutout.firebaseio.com/score");
        shoutoutRootScore.childByAppendingPath(PFUser.currentUser()?.objectId).setValue(score);
        NSNotificationCenter.defaultCenter().postNotificationName("scoreUpdated", object: self)
    }
}
