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
    var cloudPerson : CloudKitPerson = CloudKitPerson()
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        if recordName != nil {
            first.text = firstname
            last.text =  lastname
        }
        
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    func create(){
        
        let artworkRecordID = CKRecord.ID(recordName: UUID().uuidString)
        let artworkRecord = CKRecord(recordType: "Poeple", recordID: artworkRecordID)
        
        artworkRecord["first"] = first.text! as NSString
        artworkRecord["last"] = last.text! as NSString
        
        save(artworkRecord: artworkRecord)
        
        
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
    

    func save(artworkRecord: CKRecord){
        //let myContainer = CKContainer.default()
        let myContainer = CKContainer(identifier: "iCloud.cloudCommonWorld")
        //let publicDatabase = myContainer.publicCloudDatabase
        let publicDatabase = myContainer.privateCloudDatabase
        
        publicDatabase.save(artworkRecord) {
            (record, error) in
            if let error = error {
                // Insert error handling
                print(error)
                return
            }
            // Insert successfully saved record code
            print("saved!!")
//            self.lastUpdated(date: self.dateToString(date: NSDate()))
//            if self.person != nil {
//                self.updatePerson(first: self.first.text!, last: self.last.text!)
//            }else{
//                self.addPerson(first: self.first.text!, last: self.last.text!)
//            }
//
            self.dismiss(animated: true, completion: nil)
            
        }
    }
    
    
    @IBAction func cancel(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func new(_ sender: Any) {
        if recordName != nil {
            update()
        }else{
            create()
        }
        
//        cloudPerson.save(first: first.text!, last: last.text!, modified: Date()) { (error) in
//            if error != nil {
//                print(error!)
//            }
//        }
        
        
    }
    
    
     func addPerson(first: String, last: String)  {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let managedObjectContext = appDelegate?.persistentContainer.viewContext
        managedObjectContext?.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)
        guard let _context = managedObjectContext else { return }
        
        let object = NSEntityDescription.insertNewObject(forEntityName: "People", into: managedObjectContext!) as! People
        
        
        object.firstname = first
        object.lastname = last
        object.id = UUID().uuidString
        object.synced = true
        print(object)
        do {
            try _context.save()
            
            self.dismiss(animated: true, completion: nil)
        } catch {
            print("not Saved")
            
        }
        
        
    }
    
     func updatePerson(first: String, last: String) {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let managedObjectContext = appDelegate?.persistentContainer.viewContext
        managedObjectContext?.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)
        guard let _context = managedObjectContext else { return }
        
        let object = managedObjectContext?.object(with: person!.objectID) as! People
        
        object.firstname = first
        object.lastname = last
        
        do {
            try _context.save()
            
            self.dismiss(animated: true, completion: nil)
        } catch {
            print("not Saved")
            
        }
        
    }
    
    func lastUpdated(date: String){
        let defaults = UserDefaults.standard
        defaults.set(date, forKey: "lastupdate")
        defaults.synchronize()
    }
    
    func dateToString(date: NSDate)-> String{
        let formatter = DateFormatter()
        // initially set the format based on your datepicker date
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        let myString = formatter.string(from: date as Date)
        // convert your string to date
        let yourDate = formatter.date(from: myString)
        //then again set the date format whhich type of output you need
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        // again convert your date to string
        let myStringafd = formatter.string(from: yourDate!)
        
        return myStringafd
    }
    
    
    
}
