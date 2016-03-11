//
//  SOInviteFriendsViewController.swift
//  shoutout
//
//  Created by Mayank Jain on 3/8/16.
//  Copyright © 2016 Mayank Jain. All rights reserved.
//

import Foundation
import Contacts
import MessageUI

@available(iOS 9.0, *)
class SOInviteFriendsViewController : UIViewController, UITableViewDelegate, UITableViewDataSource, MFMessageComposeViewControllerDelegate, UISearchBarDelegate{
    
    var contactStore = CNContactStore()
    var contacts = [String:[CNContact]]()
    var contactsArray = [CNContact]()
    var searchResults = [CNContact]()
    var selected:Set = Set<CNContact>()
    var letters = (97...122).map({String(UnicodeScalar($0))})
    var searchActive = false
    @IBOutlet var tableView: UITableView!
    @IBOutlet var searchBar: UISearchBar!
    
    override func viewDidLoad(){
        super.viewDidLoad();
        for letter in self.letters{
            contacts[letter] = [CNContact]()
        }
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.allowsMultipleSelection = true;
        self.searchBar.delegate = self;
        self.requestForAccess()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int{
        if(self.searchActive == true){
            return self.searchResults.count
        }
        return contacts[letters[section]]!.count
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int{
        if(self.searchActive == true){
            return 1;
        }
        return letters.count
    }
    
    func sectionIndexTitlesForTableView(tableView: UITableView) -> [String]?{
        return letters
    }
    
    func tableView(tableView: UITableView,
                     titleForHeaderInSection section: Int) -> String?{
        if(self.searchActive == true){
            return "Results"
        }
        return letters[section].uppercaseString;
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell{
        let cell = tableView.dequeueReusableCellWithIdentifier("inviteFriendsCell") as! SOInviteFriendsTableViewCell
        let contact : CNContact
        if(self.searchActive){
            contact = self.searchResults[indexPath.row]
        }
        else{
            contact = self.contacts[self.letters[indexPath.section]]![indexPath.row]
        }
        cell.nameLabel.text = contact.givenName + " " + contact.familyName;
        if(contact.phoneNumbers.count > 0){
            cell.typeLabel.text = CNLabeledValue.localizedStringForLabel(contact.phoneNumbers[0].label)
            let phoneNumber = contact.phoneNumbers[0].value as! CNPhoneNumber
            cell.phoneNumberLabel.text = phoneNumber.stringValue
        }
        else{
            cell.typeLabel.text = ""
            cell.phoneNumberLabel.text = ""
        }
        if (self.selected.contains(contact)) {
            cell.accessoryType = .Checkmark;
        } else {
            cell.accessoryType = .None;
        }
        return cell
    }
    
    func tableView(tableView: UITableView,
                     didSelectRowAtIndexPath indexPath: NSIndexPath){
        let contact : CNContact
        if(self.searchActive){
            contact = self.searchResults[indexPath.row]
        }
        else{
            contact = self.contacts[self.letters[indexPath.section]]![indexPath.row]
        }
        if self.selected.contains(contact){
            self.selected.remove(contact)
            let cell = tableView.cellForRowAtIndexPath(indexPath)!;
            cell.accessoryType = .None;
        }
        else{
            self.selected.insert(contact)
            let cell = tableView.cellForRowAtIndexPath(indexPath)!;
            cell.accessoryType = .Checkmark;
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func tableView(tableView: UITableView,
                     didDeselectRowAtIndexPath indexPath: NSIndexPath){
        
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        self.searchBar.resignFirstResponder()
    }
    
    func requestForAccess() {
        let authorizationStatus = CNContactStore.authorizationStatusForEntityType(CNEntityType.Contacts)
        switch authorizationStatus {
        case .Authorized:
            self.loadContacts();
            
        case .Denied, .NotDetermined:
            self.contactStore.requestAccessForEntityType(CNEntityType.Contacts, completionHandler: { (access, accessError) -> Void in
                if access {
                    self.loadContacts();
                }
                else {
                    if authorizationStatus == CNAuthorizationStatus.Denied {
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            let message = "\(accessError!.localizedDescription)\n\nPlease allow the app to access your contacts through the Settings."
                            let alertController = UIAlertController(title: "We need your permission", message: message, preferredStyle: UIAlertControllerStyle.Alert)
                            
                            let dismissAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) { (action) -> Void in
                                UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
                            }
                            
                            alertController.addAction(dismissAction)
                            
                            self.presentViewController(alertController, animated: true, completion: nil)
                        })
                    }
                }
            })
            
        default:
            print("nothing happneed")
        }
        

    }
    
    func loadContacts(){
        let keysToFetch = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey]
        let containerId = CNContactStore().defaultContainerIdentifier()
        let predicate: NSPredicate = CNContact.predicateForContactsInContainerWithIdentifier(containerId)
        var contactsArr = try! CNContactStore().unifiedContactsMatchingPredicate(predicate, keysToFetch: keysToFetch)
        contactsArr = contactsArr.filter({ (contact:CNContact) -> Bool in
            return contact.phoneNumbers.count > 0
        })
        contactsArr.sortInPlace { (contact1:CNContact, contact2:CNContact) -> Bool in
            if(contact1.givenName == contact2.givenName){
                return contact1.familyName < contact2.familyName
            }
            return contact1.givenName < contact2.givenName
        }
        self.contactsArray = contactsArr
        for contact in contactsArr{
            let name = contact.givenName
            if(!name.isEmpty){
                let range = name.startIndex..<name.startIndex.advancedBy(1)
                let key = name[range].lowercaseString
                self.contacts[key]!.append(contact)
            }
        }
        dispatch_async(dispatch_get_main_queue(), {
            self.tableView.reloadData()
        })
    }
    
    @IBAction func cancelButtonPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil);
    }
    
    @IBAction func doneButtonPressed(sender: AnyObject) {
        let messageVC = MFMessageComposeViewController()
        var recipients = [String]()
//        if let selected = self.tableView.indexPathsForSelectedRows{
            for contact in self.selected{
//                let contact = self.contacts[self.letters[indexPath.section]]![indexPath.row]
                let number = contact.phoneNumbers[0].value as! CNPhoneNumber
                recipients.append(number.stringValue)
            }
            
            messageVC.body = "Hey! Check out this cool new app that lets you know what's going on around campus. http://www.getshoutout.co/download";
            messageVC.recipients = recipients
            messageVC.messageComposeDelegate = self;
            
            if(MFMessageComposeViewController.canSendText()){
                self.presentViewController(messageVC, animated: true, completion: nil)
            }
//        }
    }
    
    func messageComposeViewController(controller: MFMessageComposeViewController, didFinishWithResult result: MessageComposeResult) {
        switch (result.rawValue) {
        case MessageComposeResultCancelled.rawValue:
            print("Message was cancelled")
            self.dismissViewControllerAnimated(true, completion: nil)
        case MessageComposeResultFailed.rawValue:
            print("Message failed")
            self.dismissViewControllerAnimated(true, completion: nil)
        case MessageComposeResultSent.rawValue:
            print("Message was sent")
            if(self.selected.count > 0){
                let pointsEarned = 50 * self.selected.count
                SOBackendUtils.incrementScore(pointsEarned)
            }
            self.dismissViewControllerAnimated(true, completion: nil)
        default:
            break;
        }
    }
    
    func searchBar(searchBar: UISearchBar,
                     textDidChange searchText: String){
        if(searchText.isEmpty){
            self.searchActive = false
        }
        else{
            self.searchActive = true
            self.searchResults = self.contactsArray.filter({ (contact:CNContact) -> Bool in
                if(contact.givenName.containsString(searchText)){
                    return true
                }
                if(contact.familyName.containsString(searchText)){
                    return true
                }
                return false
            })
        }
        self.tableView.reloadData()
    }
}

class SOInviteFriendsTableViewCell:UITableViewCell{
    @IBOutlet var phoneNumberLabel: UILabel!
    @IBOutlet var typeLabel: UILabel!
    @IBOutlet var nameLabel: UILabel!
    
}