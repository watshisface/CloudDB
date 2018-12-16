//
//  ViewController.swift
//  clouddatabase
//
//  Created by Marvin Manzi on 12/10/18.
//  Copyright © 2018 Marvin Manzi. All rights reserved.
//

import UIKit
import CloudKit
import CoreData

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    var people : [People] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        //fetch()
        
        tableView.dataSource = self
        tableView.delegate = self
        
       // fetch()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //fetch()
        people.removeAll()
        fetchpeople()
    }
    

    
    func fetch(){
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "Poeple", predicate: predicate)
        let myContainer = CKContainer(identifier: "iCloud.cloudCommonWorld")
        myContainer.publicCloudDatabase.perform(query, inZoneWith: nil) { records, error in
            print(records?.count)

            //self.people.removeAll()
            for record in records! {
                let firstname = record.value(forKey: "first") as! String
                let lastname = record.value(forKey: "last") as! String
                let modified = record.value(forKey: "modificationDate") as! Date
                print("\(firstname) -- \(lastname) -- \(modified) -- \(Date())")
            }
            print(self.people)
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }

        }
    }
    
    
    
    
     func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rowsco
        return people.count
    }
    
    
     func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let person = people[indexPath.row]
        var syncStatus = ""
        if person.synced {
            syncStatus = "Synced"
        }else{
            syncStatus = "Not Synced"
        }
        cell.textLabel?.text = "\(person.firstname!) - \(syncStatus)"
        
        return cell
    }
    
    
     func fetchpeople()
    {
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
                    people.append(contact)
                }
                tableView.reloadData()
                
            }
        } catch {
            // handle error
        }
    }

    @IBAction func syncBtn(_ sender: Any) {
        
        for person in people {
            if updatePerson(person: person) {
                print("updated : \(person.firstname)")
            }
        }
        
    }
    
    
    func sync(person: People) -> Bool{
        
        let artworkRecordID = CKRecord.ID(recordName: person.id!)
        let artworkRecord = CKRecord(recordType: "Poeple", recordID: artworkRecordID)
        
        artworkRecord["first"] = person.firstname! as NSString
        artworkRecord["last"] = person.lastname! as NSString
        
       
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
           
        }
        
        return true
    }
    
    
    func updatePerson(person: People) -> Bool{
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let managedObjectContext = appDelegate?.persistentContainer.viewContext
        managedObjectContext?.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)
        
        guard let _context = managedObjectContext else { return false }
        
        let object = managedObjectContext?.object(with: person.objectID) as! People
        

        
        if object.synced {
            
        }else{
            if sync(person: person) {
                object.synced = true
            }
        }

        
        do {
            try _context.save()
            print("person updated and sync")

            return true
        } catch {

            
            return true
        }
    }
    
}

