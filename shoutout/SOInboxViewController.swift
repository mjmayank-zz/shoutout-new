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
    
    override func viewDidLoad(){
        super.viewDidLoad();
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
            return 0;
    }
    
    func tableView(tableView: UITableView,
        cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
            let cell = tableView.dequeueReusableCellWithIdentifier("messageCell", forIndexPath: indexPath) as! messagesCell;
            if let messages = messages{
                let message = messages[indexPath.row].objectForKey("message") as? String;
                let from = messages[indexPath.row].objectForKey("from") as! PFObject;
                let fromImage = from.objectForKey("picURL") as? String;
                cell.bodyLabel.text = message;
                cell.profileImage.layer.cornerRadius = 25.0;
                cell.profileImage.image = UIImage(data: NSData(contentsOfURL: NSURL(string: fromImage!)!)!);
            }
            return cell;
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let messages = messages{
            let from = messages[indexPath.row].objectForKey("from") as! PFObject;
            let fromUsername = from.objectForKey("username") as? String;
            
            self.delegate?.openUpdateStatusViewWithStatus("@" + fromUsername!);
            
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
    
    var object : PFObject!
}