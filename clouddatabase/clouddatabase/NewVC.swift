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
        
        let recordID = CKRecord.ID(recordName: (person?.id)!)
        
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
            print("updating")
            let updateSync : SYNC = SYNC()
            update()
        }else{
            print("creating new")
            if sync.saveRecord(andToCloud: true) {
                self.dismiss(animated: true, completion: nil)
            }
        }
        
        
    }
    
    
    
}
