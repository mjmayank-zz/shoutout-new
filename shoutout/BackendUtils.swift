//
//  BackendUtils.swift
//  shoutout
//
//  Created by Mehul Goyal on 3/8/16.
//  Copyright © 2016 Mayank Jain. All rights reserved.
//

class BackendUtils : NSObject {
    
    class func incrementScore(value: Int) {
        let score = PFUser.currentUser()?["score"] as! Int + value;
        PFUser.currentUser()?.setValue(score, forKey: "score");
        PFUser.currentUser()?.saveInBackground();
        let shoutoutRootScore = Firebase(url: "https://shoutout.firebaseio.com/score");
        shoutoutRootScore.childByAppendingPath(PFUser.currentUser()?.objectId).setValue(score);
    }
}
