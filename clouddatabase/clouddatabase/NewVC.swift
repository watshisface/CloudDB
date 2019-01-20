//
//  NewVC.swift
//  clouddatabase
//
//  Created by Marvin Manzi on 12/11/18.
//  Copyright © 2018 Marvin Manzi. All rights reserved.
//

import UIKit
import CloudKit
import CoreData


class NewVC: UIViewController {

    @IBOutlet weak var first: UITextField!
    @IBOutlet weak var last: UITextField!
    @IBOutlet weak var saveBtn: UIButton!
    
    
    
    
    var person: People?
    var firstname: String?
    var lastname: String?
    var recordName: String?
    
    var sync: SYNCPerson = SYNCPerson()
    var cloudSYNC : SYNC = SYNC()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        if person != nil {
            first.text = person?.firstname
            last.text =  person?.lastname
            saveBtn.setTitle("Update", for: UIControl.State.normal)
        }
        
        
    }

    func update(){
        //let myContainer = CKContainer.default()
        let myContainer = CKContainer(identifier: "iCloud.cloudCommonWorld")
        //let publicDatabase = myContainer.publicCloudDatabase
        let database = myContainer.privateCloudDatabase
        
        //let recordID = CKRecord.ID(recordName: (person?.id)!)
        let zone = CKRecordZone(zoneName: "prototype")
        let zoneID = zone.zoneID
        let recordID = CKRecord.ID(recordName: (person?.id)!, zoneID: zoneID)
        //self.personRecord?["version"] = NSNumber(value:self.version)
        //let record = CKRecord(recordType: "Poeple", recordID: recordID)
        
        database.fetch(withRecordID: recordID) { record, error in
            print("record: \(record) -=== error: \(error)")
            if let record = record, error == nil {
                
                //update your record here
                record["first"] = self.first.text! as NSString
                record["last"] = self.last.text! as NSString
                database.save(record) { _, error in
                    //completion?(error)
                    print("didnt update because......\(error)")
                }
            }else{
                print("couldnt fetch because: \(error)")
            }
            self.dismiss(animated: true, completion: nil)
        }
        
        
        
//
//        //let recordID = CKRecord.ID(recordName: (person?.id)!)
//        let zone = CKRecordZone(zoneName: "prototype")
//        let zoneID = zone.zoneID
//        let recordID = CKRecord.ID(recordName: (person?.id)!, zoneID: zoneID)
//        //self.personRecord?["version"] = NSNumber(value:self.version)
//        let record = CKRecord(recordType: "Poeple", recordID: recordID)
//
//        record["first"] = first.text! as NSString
//        record["last"] = last.text! as NSString
//        let sync: SYNC = SYNC()
//        if sync.saveToCloud(record: record){
//            sync.recordSycned(id: recordID.recordName)
//            self.dismiss(animated: true, completion: nil)
//        }
    }
    
    func fetchRecordByItemName(itemName: String) {
    
        let predicate = NSPredicate(format: "itemName = %@", itemName)
        
        let query = CKQuery(recordType: "Poeple", predicate: predicate)
        
        
        
        // Fetch the record for the itemName passed as a parameter to the function
        let container = CKContainer(identifier: "iCloud.cloudCommonWorld")
        let db = container.privateCloudDatabase
        let zone = CKRecordZone(zoneName: "prototype")
        let zoneID = zone.zoneID
        db.perform(query, inZoneWith: zoneID, completionHandler: {results, error in
            
            if (error != nil) {
                
                print(error)
                
            } else {
                
                if results!.count == 0 {
                    
                    // On the main thread, update the textView
                    
                    OperationQueue.main.addOperation {
                        
                        print("Sorry, that item doesn't exists in the database.")
                        
                    }
                    
                } else {
                    
                    // Put the first record in the recordToUpdate variable
                    
                    let recordToUpdate = results![0]
                    
                    self.updateTheRecord(record: recordToUpdate)
                    
                    // On the main thread, add the recordToUpdate fields in the view's controls
                    
                    OperationQueue.main.addOperation {
                        
                        //self.itemName.text = self.recordToUpdate.objectForKey("itemName") as! String
                        
                        //let photo = self.recordToUpdate.objectForKey("itemImage") as! CKAsset
                        
                        //self.imageView.image = UIImage(contentsOfFile: photo.fileURL.path!)
                        
                    }
                }
            }
        })
    }
    
    func updateTheRecord(record: CKRecord) {
        
        
          //  let item = DatabaseHeleper()
            
        //    let photoUrl = item.saveImageInDocumentsDir(self.imageView.image!)
            
        //    let asset = CKAsset(fileURL: photoUrl)
            
        record.setObject(first.text! as __CKRecordObjCValue, forKey: "first")
        record.setObject(last.text! as __CKRecordObjCValue, forKey: "last")
        
          //  record.setObject(asset, forKey: "itemImage")
        let container = CKContainer(identifier: "iCloud.cloudCommonWorld")
        let db = container.privateCloudDatabase
        let zone = CKRecordZone(zoneName: "prototype")
        let zoneID = zone.zoneID
        db.save(record, completionHandler: {returnedRecord, error in
                
                if error != nil {
                    
                    OperationQueue.main.addOperation {
                        
                        print("Update error: \(error!.localizedDescription)")
                        
                    }
                    
                } else {
                    
                    OperationQueue.main.addOperation {
                        
                        print("Update successful.")
                        
                    }
                    
                }
                
            })
        
        }
    
    

    
    
    
    @IBAction func cancel(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func new(_ sender: Any) {

        sync.first = first.text
        sync.last = last.text
        
        if person != nil {
            print("updating")
          //  let updateSync : SYNC = SYNC()
            update()

           // fetchRecordByItemName(itemName: (person?.id)!)
        }else{
            print("creating new")
            if sync.saveRecord(andToCloud: true) {
                self.dismiss(animated: true, completion: nil)
            }
        }
        
        
    }
    
    
    
}
