//
//  SOListViewController.swift
//  shoutout
//
//  Created by Mayank Jain on 10/27/15.
//  Copyright © 2015 Mayank Jain. All rights reserved.
//

import Foundation
import UIKit

class SOListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource{
    
    @IBOutlet var filterCollectionView: UICollectionView!
    @IBOutlet var tableView: UITableView!
    weak var delegate: ViewController?
    var data = [SOAnnotation]()
    var results = [SOAnnotation]()
    var open = false;
    var countLabel: UILabel!
    var filters = [SOMapFilter]()
    var selectedFilter : SOMapFilter!
    var friends = [String]()
    
    override func viewDidLoad(){
        super.viewDidLoad();
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        self.tableView.reloadData()
        
        self.filterCollectionView.delegate = self;
        self.filterCollectionView.dataSource = self;
        
        let allFilter = SOMapFilter(filter: { (annotation:SOAnnotation) -> Bool in
            return true
            }, title: "All")
        let friendFilter = SOMapFilter(filter: { (annotation:SOAnnotation) -> Bool in
            if(self.friends.contains(annotation.objectId)){
                return true
            }
            return false
            }, title: "Friends")
        let placeFilter = SOMapFilter(filter: { (annotation:SOAnnotation) -> Bool in
            if(annotation.isStatic){
                return true
            }
            return false
            }, title: "Places")
        self.filters = [allFilter, friendFilter, placeFilter]
        self.selectedFilter = allFilter
        queryFriends()
//        self.filterCollectionView.selectItemAtIndexPath(NSIndexPath(index: 0), animated: false, scrollPosition: .None)
    }
    
    func queryFriends(){
        PFCloud.callFunctionInBackground("findFriends", withParameters: ["user":(PFUser.currentUser()?.objectId)!]) { (response:AnyObject?, error:NSError?) -> Void in
            if(error == nil){
                self.friends = response as! [String]
            }
            else{
                print(error);
            }
        }
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filters.count;
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("filterCell",forIndexPath:indexPath) as! FilterCell
        cell.layer.cornerRadius = cell.frame.height/2.0
        cell.clipsToBounds = true
        cell.label.text = self.filters[indexPath.row].title
//        if(!(collectionView.indexPathsForSelectedItems()?.isEmpty)!){
//            let selectedPath = collectionView.indexPathsForSelectedItems()?[0]
//            if(selectedPath == indexPath){
//                cell.backgroundColor = UIColor.whiteColor()
//            }
//        }
//        else{
//            cell.backgroundColor = UIColor(red: 255, green: 255, blue: 255, alpha: 0.8)
//        }
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath)
        cell?.backgroundColor = UIColor.whiteColor()
        self.selectedFilter = self.filters[indexPath.row]
        results = data.filter(selectedFilter.filterFunc)
        self.delegate?.filter = self.selectedFilter
        self.delegate?.filterAnnotations()
        self.tableView.reloadData()
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath)
        cell?.backgroundColor = UIColor(red: 255, green: 255, blue: 255, alpha: 0.8)
    }
    
    // MARK: -TableViewDataSource
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("listViewCell", forIndexPath: indexPath) as! ListViewCell
    
        let annotation = self.results[indexPath.row];
        
        cell.bodyLabel.text = annotation.subtitle;
        cell.usernameLabel.text = annotation.title;
        
        cell.profileImage.layer.cornerRadius = cell.profileImage.bounds.size.height/2.0;
        cell.profileImage.layer.masksToBounds = true;
        
        cell.profileImage.image = annotation.profileImage;
        
        return cell
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
                let from = self.results[indexPath.row].object;
                
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
            
            let from = self.results[indexPath.row].object;
            
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
        
        let reportAction = UITableViewRowAction(style: UITableViewRowActionStyle.Normal, title: "Report") { (action:UITableViewRowAction, indexPath:NSIndexPath) -> Void in
            
            let alertController = UIAlertController(title: "Are you sure?", message: "This will report the status to our moderators", preferredStyle: UIAlertControllerStyle.Alert)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
            let okayAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: { (alert:UIAlertAction) -> Void in
                let from = self.results[indexPath.row].object;
                
                let block = PFObject(className: "Report")
                block.setObject(from, forKey: "reportedUser");
                if let status = from.objectForKey("status"){
                    block.setObject(status, forKey: "status")
                }
                block.saveInBackground();
                
                tableView.setEditing(false, animated: true)
            })
            
            alertController.addAction(cancelAction)
            alertController.addAction(okayAction);
            
            self.presentViewController(alertController, animated: true, completion: nil);
        }
        reportAction.backgroundColor = UIColor.orangeColor()
        
        return [locateAction, blockAction, reportAction]
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        let annotation = self.data[indexPath.row]
        let username = annotation.userInfo["username"] as! String;
        
        NSNotificationCenter.defaultCenter().postNotificationName("replyToShout", object: self, userInfo: ["username": username])
        tableView.deselectRowAtIndexPath(indexPath, animated: true);
    }
    
    func updateAnnotationArray(array: [KPAnnotation]){
        var pins = [SOAnnotation]();
        for kingAnnotation:KPAnnotation in array{
            for annotation in kingAnnotation.annotations{
                pins.append(annotation as! SOAnnotation);
            }
        }
        data = pins;
        results = data.filter(self.selectedFilter.filterFunc);
        countLabel.text = String(format: "%d people on screen", data.count)
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

class FilterCell: UICollectionViewCell{
    @IBOutlet var label: UILabel!
    
}