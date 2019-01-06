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
    
    var person: People?
    var firstname: String?
    var lastname: String?
    var recordName: String?
    
    var sync: SYNCPerson = SYNCPerson()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        if person != nil {
            first.text = person?.firstname
            last.text =  person?.lastname
        }
        
        
    }

    func update(){
        //let myContainer = CKContainer.default()
        let myContainer = CKContainer(identifier: "iCloud.cloudCommonWorld")
        //let publicDatabase = myContainer.publicCloudDatabase
        let database = myContainer.privateCloudDatabase
        
        let recordID = CKRecord.ID(recordName: recordName!)
        
        database.fetch(withRecordID: recordID) { record, error in
            
            if let record = record, error == nil {
                
                //update your record here
                record["first"] = self.first.text! as NSString
                record["last"] = self.last.text! as NSString
                database.save(record) { _, error in
                    //completion?(error)
                }
            }
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    
    
    @IBAction func cancel(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func new(_ sender: Any) {

        sync.first = first.text
        sync.last = last.text
        
        if person != nil {
            let updateSync : SYNC = SYNC()
            updateSync.updateCore(recordName: (person?.id)!, first: (person?.firstname)!, last: (person?.lastname)!)
        }else{
            if sync.saveRecord(andToCloud: true) {
                self.dismiss(animated: true, completion: nil)
            }
        }
        
        
    }
    
    
    
}
