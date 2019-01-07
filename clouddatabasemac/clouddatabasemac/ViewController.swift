//
//  ViewController.swift
//  clouddatabasemac
//
//  Created by Marvin Manzi on 12/10/18.
//  Copyright © 2018 Marvin Manzi. All rights reserved.
//

import Cocoa
import CloudKit

class ViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {

    var contacts: [String] = []
    @IBOutlet weak var tableView: NSTableView!
    var syncTimer = Timer()
    
    
    @IBOutlet weak var firstName: NSTextField!
    
    @IBOutlet weak var lastName: NSTextField!
    
    @IBOutlet weak var savingLbl: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tableView.dataSource = self
        tableView.delegate = self
        fetch()
        startTimer()
        
        savingLbl.isHidden = true
        
    
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
  
    
    
    @objc func fetch(){
        savingLbl.isHidden = false
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "Poeple", predicate: predicate)
        let myContainer = CKContainer(identifier: "iCloud.cloudCommonWorld")
        let zone = CKRecordZone(zoneName: "prototype")
        let zoneID = zone.zoneID
        //myContainer.publicCloudDatabase.perform(query, inZoneWith: nil) { records, error in
        myContainer.privateCloudDatabase.perform(query, inZoneWith: zoneID) { records, error in
            print(records?.count)
            
            self.contacts.removeAll()
            for record in records! {
                let firstname = record.value(forKey: "first") as! String
                let lastname = record.value(forKey: "last") as! String
                self.contacts.append(firstname + " " + lastname)
            }
            //print(self.contacts)
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.savingLbl.isHidden = true
            }
        }
    }
    
    @IBAction func refresh(_ sender: Any) {
        print("clicked!!")
        fetch()
    }
    func numberOfRows(in tableView: NSTableView) -> Int {
        return contacts.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return contacts[row]
    }
    
    
    func create(){
        
        savingLbl.isHidden = false
        self.contacts.append(self.firstName.stringValue + " " + self.lastName.stringValue)
        tableView.reloadData()
        resetTimer()
        
        let zone = CKRecordZone(zoneName: "prototype")
        let zoneID = zone.zoneID
        let recordID = CKRecord.ID(recordName: UUID().uuidString, zoneID: zoneID)
        //let artworkRecordID = CKRecord.ID(recordName: UUID().uuidString)
        let record = CKRecord(recordType: "Poeple", recordID: recordID)
        
        record["first"] = firstName.stringValue as NSString
        record["last"] = lastName.stringValue as NSString
        
        save(artworkRecord: record)
        
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
            self.firstName.stringValue = ""
            self.lastName.stringValue = ""
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.savingLbl.isHidden = true
                self.savingLbl.isHidden = true
                self.resetTimer()
            }
        }
    }

    @IBAction func saveBtn_click(_ sender: Any) {
        
        create()
    }
    
    func startTimer(){
        syncTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(self.fetch), userInfo: nil, repeats: true)
    }
    
    func resetTimer(){
        syncTimer.invalidate()
        startTimer()
    }
    
    
    
}

