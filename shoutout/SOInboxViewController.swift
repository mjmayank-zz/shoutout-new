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
    
    override func viewDidLoad(){
        super.viewDidLoad();
        self.tableView.dataSource = self;
        self.tableView.delegate = self;
        
        getMessages();
    }
    
    func getMessages(){
        let query = PFQuery(className: "Messages");
        query.whereKey("to", equalTo: PFUser.currentUser()!);
        query.findObjectsInBackgroundWithBlock { (results:[PFObject]?, error:NSError?) -> Void in
            self.messages = results;
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
                cell.bodyLabel.text = message;
            }
            return cell;
    }
    
    @IBAction func didPressDoneButton(sender: AnyObject) {
        self .dismissViewControllerAnimated(true, completion: nil);
    }
    
}

class messagesCell : UITableViewCell{
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var bodyLabel: UILabel!
    var object : PFObject!
}