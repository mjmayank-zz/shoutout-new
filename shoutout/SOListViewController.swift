//
//  SOListViewController.swift
//  shoutout
//
//  Created by Mayank Jain on 10/27/15.
//  Copyright © 2015 Mayank Jain. All rights reserved.
//

import Foundation
import UIKit

class SOListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{
    
    @IBOutlet var tableView: UITableView!
    var data:[SOAnnotation]!
    var open = false;
    
    override func viewDidLoad(){
        super.viewDidLoad();
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        data = [SOAnnotation]();
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let data = data{
            return data.count
        }
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("listViewCell", forIndexPath: indexPath) as! ListViewCell
    
        let annotation = self.data[indexPath.row];
        
        cell.bodyLabel.text = annotation.subtitle;
        cell.usernameLabel.text = annotation.title;
        
        cell.profileImage.layer.cornerRadius = cell.profileImage.bounds.size.height/2.0;
        cell.profileImage.layer.masksToBounds = true;
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true);
    }
    
    func updateAnnotationArray(array: [KPAnnotation]){
        NSLog("update list view");
        var pins = [SOAnnotation]();
        for kingAnnotation:KPAnnotation in array{
            for annotation in kingAnnotation.annotations{
                pins.append(annotation as! SOAnnotation);
            }
        }
        data = pins;
        tableView.reloadData();
    }
}

class ListViewCell: UITableViewCell{
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var bodyLabel: UILabel!
    @IBOutlet var profileImage: UIImageView!
    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    
    var object : PFObject!
}