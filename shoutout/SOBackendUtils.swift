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
    
    class func validateUsername(username:String) -> Bool{
        let set = NSMutableCharacterSet(charactersInString: "_");
        set.formUnionWithCharacterSet(NSCharacterSet.alphanumericCharacterSet());
        let finalSet = set.invertedSet;
        
        let range = username.rangeOfCharacterFromSet(finalSet)
        if (range != nil) {
            print("invalid character found")
            return false
        }
        return true;
    }
    
    class func checkInUser(locationTitle:String){
        PFCloud.callFunctionInBackground("findFriends", withParameters: ["user":(PFUser.currentUser()?.objectId)!]) { (response:AnyObject?, error:NSError?) -> Void in
            if(error == nil){
                var objects = [PFObject]()
                let friends = response as! [String]
                let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
                dispatch_async(dispatch_get_global_queue(priority, 0)) {
                    for friend in friends{
                        let query = PFUser.query()
                        do{
                            let result = try query?.getObjectWithId(friend)
                            objects.append(result!)
                        } catch{
                            print("error with objectID %s", friend)
                        }
                    }
                    
                    var friendsForPush = [PFObject]()
                    let coordinate = LocationManager.sharedLocationManager().lastLocation
                    
                    for object in objects{
                        if let geo = object["geo"] as? PFGeoPoint{
                            if(CLLocation(latitude: geo.latitude, longitude: geo.longitude).distanceFromLocation(coordinate) < 50000){
                                friendsForPush.append(object)
                                let pushQuery = PFInstallation.query()
                                pushQuery?.whereKey("user", equalTo: object)
                                
                                let username = PFUser.currentUser()!["displayName"] as! String
                                
                                let fullMessage = "Your friend, @" + username + ", just checked in to " + locationTitle
                                
                                let data = [
                                    "alert":fullMessage,
                                    "objectId":PFUser.currentUser()!.objectId!
                                ] as [NSObject:AnyObject]
                                
                                let push = PFPush()
                                push.setQuery(pushQuery)
                                push.setData(data)
                                push.sendPushInBackground()
                            }
                        }
                    }
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        // update some UI
                    }
                }
            }
            else{
                print(error);
            }
        }
    }
}
