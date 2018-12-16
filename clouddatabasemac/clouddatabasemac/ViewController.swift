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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tableView.dataSource = self
        tableView.delegate = self
        fetch()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    
    func fetch(){
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "Poeple", predicate: predicate)
        let myContainer = CKContainer(identifier: "iCloud.cloudCommonWorld")
        //myContainer.publicCloudDatabase.perform(query, inZoneWith: nil) { records, error in
        myContainer.privateCloudDatabase.perform(query, inZoneWith: nil) { records, error in
            print(records?.count)
            
            self.contacts.removeAll()
            for record in records! {
                let firstname = record.value(forKey: "first") as! String
                let lastname = record.value(forKey: "last") as! String
                self.contacts.append(firstname + " " + lastname)
            }
            print(self.contacts)
            DispatchQueue.main.async {
                self.tableView.reloadData()
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

}

