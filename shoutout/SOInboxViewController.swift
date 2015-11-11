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
        
        self.tableView.dataSource = self;
        self.tableView.delegate = self;
        
        getMessages();
    }
    
    func getMessages(){
        let query = PFQuery(className: "Messages");
        query.whereKey("to", equalTo: PFUser.currentUser()!);
        query.includeKey("from");
        query.orderByDescending("createdAt");
        query.findObjectsInBackgroundWithBlock { (results:[PFObject]?, error:NSError?) -> Void in
            self.messages = results;
            for message in results!{
                let read = message.objectForKey("read") as? Bool
                if read != true{
                    message.setObject(NSNumber(bool: true), forKey: "read");
                    message.saveInBackground();
                }
            }
            self.tableView.reloadData();
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
                let cell = tableView.dequeueReusableCellWithIdentifier("messageCell", forIndexPath: indexPath) as! messagesCell;
                
                let message = messages![indexPath.row].objectForKey("message") as? String;
                let from = messages![indexPath.row].objectForKey("from") as! PFObject;
                let fromImage = from.objectForKey("picURL") as? String;
                cell.bodyLabel.text = message;
                cell.usernameLabel.text = from.objectForKey("username") as? String;
                cell.profileImage.layer.cornerRadius = 25.0;
                
                let dateFormatter = NSDateFormatter();
                dateFormatter.dateFormat = "MM/dd/yy HH:mm";
                let date = from.updatedAt;
                let dateString = dateFormatter.stringFromDate(date!);
                cell.dateLabel.text = dateString;
                
                var image = self.profileImageCache.objectForKey(from.objectId!) as? UIImage;
                if(image == nil){
                    if let fromImage = fromImage{
                        image = UIImage(data: NSData(contentsOfURL: NSURL(string: fromImage)!)!);
                        self.profileImageCache.setObject(image!, forKey: from.objectId!)
                        cell.profileImage.image = image;
                    }
                    else{
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
                }
                else{
                    cell.profileImage.image = image;
                }
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
            let fromUsername = from.objectForKey("username") as? String;
            
            self.delegate?.openUpdateStatusViewWithStatus("@" + fromUsername! + " ");
            
            self.dismissViewControllerAnimated(true, completion: nil);
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true);
    }
    
    @IBAction func didPressDoneButton(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil);
    }
    
}

class messagesCell : UITableViewCell{
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var bodyLabel: UILabel!
    @IBOutlet var profileImage: UIImageView!
    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    
    var object : PFObject!
}