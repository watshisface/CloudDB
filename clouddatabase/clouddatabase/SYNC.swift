//
//  SYNC.swift
//  clouddatabase
//
//  Created by Marvin Manzi on 1/3/19.
//  Copyright © 2019 Marvin Manzi. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import CloudKit
import SystemConfiguration

public protocol CloudKitUpdateDelegate {
    func cloudkitUpdated(record: CKRecord)
}

class SYNC {
    
   
    
    static let shared = SYNC()
    
     public var zoneID: CKRecordZone.ID?
    
    public init() {
        let zone = CKRecordZone(zoneName: "prototype")
        zoneID = zone.zoneID
    }
    
    let nc = NotificationCenter.default
    public var delegate: CloudKitUpdateDelegate?
    // Create the CloudKit subscription
    public let subscriptionID = "cloudkit-person-changes"
    private let subscriptionSavedKey = "ckSubscriptionSaved"
    public func saveSubscription() {
        let alreadySaved = UserDefaults.standard.bool(forKey: subscriptionSavedKey)
        guard !alreadySaved else {
            return
        }

        let predicate = NSPredicate(value: true)
        let subscription = CKQuerySubscription(recordType: "Poeple",
                                               predicate: predicate,
                                               subscriptionID: subscriptionID,
                                               options: [.firesOnRecordCreation, .firesOnRecordDeletion, .firesOnRecordUpdate])
        
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo
        
        let operation = CKModifySubscriptionsOperation(subscriptionsToSave: [subscription], subscriptionIDsToDelete: [])
        operation.modifySubscriptionsCompletionBlock = { (_, _, error) in
            guard error == nil else {
                //print("subscription not saved!!! \(error)")
                return
            }
            
            UserDefaults.standard.set(true, forKey: self.subscriptionSavedKey)
            print("subscription saved!!!")
        }
        operation.qualityOfService = .utility
        
        let container = CKContainer(identifier: "iCloud.cloudCommonWorld")
        let db = container.privateCloudDatabase
        db.add(operation)
    }
    
    
    
    public func createZone(completion: @escaping (Error?) -> Void) {
        
        print("creatinf zone!!!!")
        let recordZone = CKRecordZone(zoneID: self.zoneID!)
        let operation = CKModifyRecordZonesOperation(recordZonesToSave: [recordZone], recordZoneIDsToDelete: [])
        operation.modifyRecordZonesCompletionBlock = { _, _, error in
            guard error == nil else {
                completion(error)
                return
            }
            completion(nil)
        }
        operation.qualityOfService = .utility
        let container = CKContainer(identifier: "iCloud.cloudCommonWorld")
        let db = container.privateCloudDatabase
        db.add(operation)
    }
    
    
    
    func saveToCloud(record: CKRecord) -> Bool {
        let myContainer = CKContainer(identifier: "iCloud.cloudCommonWorld")
        let privateDatabase = myContainer.privateCloudDatabase
        
        privateDatabase.save(record) {
            (record, error) in
            if let error = error {
                // Insert error handling
                print(error)
                return
            }

            self.recordSycned(id: (record?.recordID.recordName)!)
        }
        
        return true
    }
    
    
    
    private let serverChangeTokenKey = "ckServerChangeToken"
    public func handleNotification() {
        print("dealing with subscription")

        var changeToken: CKServerChangeToken? = nil
        let changeTokenData = UserDefaults.standard.data(forKey: serverChangeTokenKey)
        if changeTokenData != nil {
            changeToken = NSKeyedUnarchiver.unarchiveObject(with: changeTokenData!) as! CKServerChangeToken?
        }
        let options = CKFetchRecordZoneChangesOperation.ZoneOptions()
        options.previousServerChangeToken = changeToken
        
        
        print("setting up operation...")
        let optionsMap = [zoneID: options]
        let operation = CKFetchRecordZoneChangesOperation(recordZoneIDs: [zoneID!], optionsByRecordZoneID: optionsMap as! [CKRecordZone.ID : CKFetchRecordZoneChangesOperation.ZoneOptions])
        operation.fetchAllChanges = true
        operation.recordChangedBlock = { record in
            
            print("Record!!!!!! \(record.recordID.recordName)")
           // self.delegate?.cloudkitUpdated(record: record)
            let recordname = record.recordID.recordName
           // print("first ---\(record.value(forKey: "first")) ---- last \(record.value(forKey: "first"))")
            if record.value(forKey: "first") != nil {
                let first = record.value(forKey: "first") as! String
                let last = record.value(forKey: "last") as! String
                self.updateCore(recordName: recordname, first: first, last: last)
            }else{
                print("doesnt have record Values")
            }
        }
        
        operation.recordWithIDWasDeletedBlock = { recordID, recordType in
            //print("Record!!!!!! \(recordID.recordName)")
            self.deletePerson(id: recordID.recordName)
            
        }
        

        operation.recordZoneChangeTokensUpdatedBlock = { zoneID, changeToken, data in
           // print("sdfdsfd : \(changeToken) --- sdcds: \(data)")
            guard let changeToken = changeToken else {
                print("failed1")
                return
            }
            
            let changeTokenData = NSKeyedArchiver.archivedData(withRootObject: changeToken)
            UserDefaults.standard.set(changeTokenData, forKey: self.serverChangeTokenKey)
        }
        
        operation.recordZoneFetchCompletionBlock = { zoneID, changeToken, data, more, error in
        //print("From zone: \(zoneID) -- \(changeToken) -- Data \(data) -- \(more) -- \(error)")
            guard error == nil else {
                //print("failed2 \(error)")
                return
            }
            guard let changeToken = changeToken else {
             //   print("failed3 \(error)")
                return
            }
            
            let changeTokenData = NSKeyedArchiver.archivedData(withRootObject: changeToken)
            UserDefaults.standard.set(changeTokenData, forKey: self.serverChangeTokenKey)
        }
        operation.fetchRecordZoneChangesCompletionBlock = { error in
            guard error == nil else {
             //   print("failed4 \(error)")
                return
            }
        }
        operation.qualityOfService = .utility
        
        let container = CKContainer(identifier: "iCloud.cloudCommonWorld")
        let db = container.privateCloudDatabase
        db.add(operation)
    }

    
    func updateCore(recordName: String, first: String, last: String) {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let managedObjectContext = appDelegate?.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "People")
        fetchRequest.predicate = NSPredicate(format: "id = %@", recordName)
        
        do {
            let contacts = try managedObjectContext?.fetch(fetchRequest) as! [People]
            print("number of found records!!!! : \(contacts.count) --- \(recordName)")
            if contacts.count > 0 {
                guard let _context = managedObjectContext else { return }
                let object = managedObjectContext?.object(with: contacts[0].objectID) as! People
                //print("found\(object.firstname)")
                object.firstname = first
                object.lastname = last
                do {
                    
                    try _context.save()
                    nc.post(name: Notification.Name("peopleupdated"), object: nil)
                    nc.post(name: Notification.Name("reloadcore"), object: nil)
                } catch {
                    print("not Saved")
                }
            }else{
                guard let _context = managedObjectContext else { return  }
                let object = NSEntityDescription.insertNewObject(forEntityName: "People", into: managedObjectContext!) as! People
                object.firstname = first
                object.lastname = last
                object.id = recordName
                object.synced = true
                print(object)
                do {
                    try _context.save()
                    nc.post(name: Notification.Name("peopleupdated"), object: nil)
                    nc.post(name: Notification.Name("reloadcore"), object: nil)
                    //TODO: put check for internet connection
                } catch {
                    print("not Saved")
                }
            }
        } catch {
            //return nil
            // handle error
        }
        //return nil
    }
    
    
    
    func deletePerson(id: String) {
        print("deleting!!!! \(id)")
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let managedObjectContext = appDelegate?.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "People")
        fetchRequest.predicate = NSPredicate(format: "id = %@", id)
        
        do {
            let contacts = try managedObjectContext?.fetch(fetchRequest) as! [People]
            print("number of found records!!!! : \(contacts.count)")
            if contacts.count > 0 {
                guard let _context = managedObjectContext else { return }
                let object = managedObjectContext?.object(with: contacts[0].objectID) as! People
                _context.delete(object)
                nc.post(name: Notification.Name("peopleupdated"), object: nil)
                nc.post(name: Notification.Name("reloadcore"), object: nil)
            }
        } catch {
            print("not Saved")
        }
    }
    
    func recordSycned(id: String) {
        print("changing to synced!!!! \(id)")
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let managedObjectContext = appDelegate?.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "People")
        fetchRequest.predicate = NSPredicate(format: "id = %@", id)
        
        do {
            let contacts = try managedObjectContext?.fetch(fetchRequest) as! [People]
            print("number of found records!!!! : \(contacts.count)")
            if contacts.count > 0 {
                guard let _context = managedObjectContext else { return }
                let object = managedObjectContext?.object(with: contacts[0].objectID) as! People
                //print("found\(object.firstname)")
                object.synced = true
                do {
                    
                    try _context.save()
                } catch {
                    print("not Saved")
                }
            }
        } catch {
            print("not Saved")
        }
    }
    
    
    func deleteFromCloud(recordName: String){
        //let recordID = CKRecord.ID(recordName: recordName)
        let recordID = CKRecord.ID(recordName: recordName, zoneID: zoneID!)
        let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: [recordID])
        operation.savePolicy = .allKeys
        operation.modifyRecordsCompletionBlock = { added, deleted, error in
            //print("deleting: \(added)  ---   \(deleted)  ---  \(error)")
            if error != nil {
              //  print(error) // print error if any
            } else {
                // no errors, all set!
                self.deletePerson(id: recordName)
            }
        }
        
        let myContainer = CKContainer(identifier: "iCloud.cloudCommonWorld")
        //let publicDatabase = myContainer.publicCloudDatabase
        let database = myContainer.privateCloudDatabase
        database.add(operation)
    }
    
    
    func pushToCloud(){
        print("pushing to the cloud!!!")
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let managedObjectContext = appDelegate?.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "People")
        let sortDescriptor = NSSortDescriptor(key: "firstname", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        do {
            let contacts = try managedObjectContext?.fetch(fetchRequest) as! [People]
            //print("Frist contacts count**********\(contacts.count)")
            if contacts.count > 0 {
                for contact in contacts {
                    if contact.synced {
                        print("no need to sync: \(contact.firstname)")
                    }else{
                        let recordID = CKRecord.ID(recordName: contact.id!, zoneID: zoneID!)
                        //self.personRecord?["version"] = NSNumber(value:self.version)
                        let record = CKRecord(recordType: "Poeple", recordID: recordID)
                        
                        record["first"] = contact.firstname! as NSString
                        record["last"] = contact.lastname! as NSString
                        
                        if saveToCloud(record: record) {
                            print("uploaded \(contact.firstname)")
                        }
                    }
                }
                
                nc.post(name: Notification.Name("peopleupdated"), object: nil)
                nc.post(name: Notification.Name("reloadcore"), object: nil)
            }
        } catch {
            // handle error
        }
    }
    



    

    
}
