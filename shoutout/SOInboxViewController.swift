//
//  SOInboxViewController.swift
//  shoutout
//
//  Created by Mayank Jain on 9/21/15.
//  Copyright © 2015 Mayank Jain. All rights reserved.
//

import Foundation
import UIKit

class SOInboxViewController : UIViewController, UITableViewDataSource, UITableViewDelegate{
    
    @IBOutlet var tableView: UITableView!
    var messages: [PFObject]?
    var delegate: ViewController?
    var profileImageCache : NSCache!
    
    override func viewDidLoad(){
        super.viewDidLoad();
        
        PFAnalytics.trackEvent("openedInbox", dimensions:nil);
        
        if(profileImageCache == nil){
            profileImageCache = NSCache();
        }
        
        self.tableView.dataSource = self;
        self.tableView.delegate = self;
        
        self.view.layer.cornerRadius = 20;
        self.view.layer.masksToBounds = true;
    }
    
    func getMessages(){
        let queryTo = PFQuery(className: "Messages");
        queryTo.whereKey("toArray", equalTo: PFUser.currentUser()!);
        
        let queryFrom = PFQuery(className: "Messages");
        queryFrom.whereKey("from", equalTo: PFUser.currentUser()!);
        
        let query = PFQuery.orQueryWithSubqueries([queryTo, queryFrom]);
        query.orderByDescending("createdAt");
        query.findObjectsInBackgroundWithBlock { (results:[PFObject]?, error:NSError?) -> Void in
            self.messages = results;
            for message in results!{
                let read = message.objectForKey("read") as? Bool
                let from = message.objectForKey("from") as? PFObject
                if read != true && from?.objectId != PFUser.currentUser()?.objectId{
                    message.setObject(NSNumber(bool: true), forKey: "read");
                    message.saveInBackground();
                }
            }
            self.tableView.reloadData();
        }
        let currentInstallation = PFInstallation.currentInstallation();
        if (currentInstallation.badge != 0) {
            currentInstallation.badge = 0;
            currentInstallation.saveEventually();
        }
    }
    
    func tableView(tableView: UITableView,
        numberOfRowsInSection section: Int) -> Int{
            if let messages = messages{
                return messages.count;
            }
            return 1;
    }
    
    func tableView(tableView: UITableView,
        cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
            if (messages != nil && messages?.count > 0){
                var cell: messagesCell;
                let from = messages![indexPath.row].objectForKey("from") as! PFObject;
                if(from.objectId == PFUser.currentUser()?.objectId){
                    cell = tableView.dequeueReusableCellWithIdentifier("sentMessageCell", forIndexPath: indexPath) as! messagesCell
                }
                else{
                    cell = tableView.dequeueReusableCellWithIdentifier("messageCell", forIndexPath: indexPath) as! messagesCell;
                }
                
                let message = messages![indexPath.row].objectForKey("message") as? String;
                from.fetchInBackgroundWithBlock({ (object:PFObject?, error:NSError?) -> Void in
                    cell.usernameLabel.text = from.objectForKey("username") as? String;
                    var image = self.profileImageCache.objectForKey(from.objectId!) as? UIImage;
                    if(image == nil){
                        from.objectForKey("profileImage")?.fetchIfNeededInBackgroundWithBlock({ (obj:PFObject?, error:NSError?) -> Void in
                            
                            obj?.objectForKey("image")?.getDataInBackgroundWithBlock({ (data:NSData?, error:NSError?) -> Void in
                                if let data = data{
                                    image = UIImage(data:data);
                                    self.profileImageCache.setObject(image!, forKey: from.objectId!)
                                    cell.profileImage.image = image;
                                }
                                
                            })
                        })
                    }
                    else{
                        cell.profileImage.image = image;
                    }
                })
                cell.bodyLabel.text = message;

                cell.profileImage.layer.cornerRadius = cell.profileImage.frame.size.width / 2;
                cell.profileImage.clipsToBounds = true;
                
                let dateFormatter = NSDateFormatter();
                dateFormatter.dateFormat = "MMM dd hh:mm a";
                let date = messages![indexPath.row].createdAt;
                let dateString = dateFormatter.stringFromDate(date!);
                cell.dateLabel.text = dateString;
                
                return cell;
            }
            else{
                let cell = UITableViewCell()
                cell.textLabel?.text = "No messages to show"
                return cell;
            }
    }
    
    func tableView(tableView: UITableView,
        editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]?{
            
            var blockString:String!;
            if(true){
                blockString = "Block";
            }
            else{
                blockString = "Unblock";
            }
            
            let blockAction = UITableViewRowAction(style: UITableViewRowActionStyle.Normal, title: blockString) { (action:UITableViewRowAction, indexPath:NSIndexPath) -> Void in
                
                let alertController = UIAlertController(title: "Are you sure?", message: "This will prevent either of you from seeing each other on the map", preferredStyle: UIAlertControllerStyle.Alert)
                
                let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
                let okayAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (alert:UIAlertAction) -> Void in
                    let from = self.messages![indexPath.row].objectForKey("from") as! PFObject;
                    
                    let block = PFObject(className: "Block")
                    block.setObject(from, forKey: "blockedUser");
                    block.setObject(PFUser.currentUser()!, forKey: "fromUser")
                    block.saveInBackground();
                    
                    tableView.setEditing(false, animated: true)
                })
                
                alertController.addAction(cancelAction)
                alertController.addAction(okayAction);
                
                self.presentViewController(alertController, animated: true, completion: nil);
            }
            blockAction.backgroundColor = UIColor.redColor()
            
            let locateAction = UITableViewRowAction(style: UITableViewRowActionStyle.Normal, title: "Locate") { (action:UITableViewRowAction, indexPath:NSIndexPath) -> Void in
                
                let from = self.messages![indexPath.row].objectForKey("from") as! PFObject;
                
                if let visible = from.objectForKey("visible") as? Bool{
                    if(visible){
                        let loc = from.objectForKey("geo") as! PFGeoPoint;
                        self.delegate?.mapView.setCenterCoordinate(CLLocationCoordinate2DMake(loc.latitude, loc.longitude), animated: true);
                    }
                    else{
                        
                    }
                }
                
                tableView.setEditing(false, animated: true)
            }
            
            return [blockAction, locateAction]
    }
    
    func tableView(tableView: UITableView,
        accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath){
            
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let messages = messages{
            let from = messages[indexPath.row].objectForKey("from") as! PFObject;
            var toArray = messages[indexPath.row].objectForKey("toArray") as! [PFObject]
            toArray += [from];
            var count = toArray.count
            var usernames = ""
            for obj in toArray{
                if(obj.objectId != PFUser.currentUser()?.objectId){
                    obj.fetchIfNeededInBackgroundWithBlock({ (object:PFObject?, error:NSError?) -> Void in
                        count--
                        if let username = object!.objectForKey("username") as? String{
                            usernames += "@" + username + " ";
                        }
                    })
                }
                else{
                    count--
                }
            }
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
                while(count != 0){
                    
                }
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.delegate?.openUpdateStatusViewWithStatus(usernames);
                    //            self.dismissViewControllerAnimated(true, completion: nil);
                    });
            })
        
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true);
    }
    
}

class messagesCell : UITableViewCell{
    @IBOutlet var bodyLabel: UILabel!
    @IBOutlet var profileImage: UIImageView!
    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    
    var object : PFObject!
}