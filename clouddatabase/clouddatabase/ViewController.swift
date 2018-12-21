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
    
    var syncTimer = Timer()
    var tableTimer = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        //fetch()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        
        if sysLastUpdated() == "" {
            fetchAll()
        }else{
            fetch()
        }
        
        
        //fetch()
        scheduledFetchWithTimeInterval()
        
        print("last updated -- \(sysLastUpdated())")
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //fetch()
        
        fetchpeople()
    }
    
    func scheduledFetchWithTimeInterval(){
        // Scheduling timer to Call the function "updateCounting" with the interval of 1 seconds
        syncTimer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(self.fetch), userInfo: nil, repeats: true)
       // tableTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(self.fetchpeople), userInfo: nil, repeats: true)
    }

    
    @objc func fetch(){
      //  print("fetching updates")
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "Poeple", predicate: predicate)
        let myContainer = CKContainer(identifier: "iCloud.cloudCommonWorld")
        let lastUpdate = stringToDate(dateStr: sysLastUpdated())
        myContainer.privateCloudDatabase.perform(query, inZoneWith: nil) { records, error in
            for record in records! {
                
                let modified = record.value(forKey: "modificationDate") as! Date
                print("\(record.value(forKey: "first")) -- \(modified) -- \(modified > lastUpdate)")
                if modified > lastUpdate {
                    let firstname = record.value(forKey: "first") as! String
                    let lastname = record.value(forKey: "last") as! String
                    if self.addPerson(first: firstname, last: lastname) {
                        
                    }
                }
                
            }
            self.lastUpdated(date: self.dateToString(date: NSDate()))
        }
        DispatchQueue.main.async {
            self.fetchpeople()
        }
    }
    
    func fetchAll(){
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "Poeple", predicate: predicate)
        let myContainer = CKContainer(identifier: "iCloud.cloudCommonWorld")
        myContainer.privateCloudDatabase.perform(query, inZoneWith: nil) { records, error in
            print(records?.count)
            for record in records! {
                let firstname = record.value(forKey: "first") as! String
                let lastname = record.value(forKey: "last") as! String
                if self.addPerson(first: firstname, last: lastname) {
                    
                }
            }
        }
        lastUpdated(date: dateToString(date: NSDate()))
        DispatchQueue.main.async {
            self.fetchpeople()
        }
    }
    
    
    func addPerson(first: String, last: String) -> Bool {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let managedObjectContext = appDelegate?.persistentContainer.viewContext
        managedObjectContext?.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)
        guard let _context = managedObjectContext else { return false }
        
        let object = NSEntityDescription.insertNewObject(forEntityName: "People", into: managedObjectContext!) as! People
        
        
        object.firstname = first
        object.lastname = last
        object.id = UUID().uuidString
        object.synced = true
        do {
            try _context.save()
            return true
        } catch {
            print("not Saved")
            
        }
        
        return false
        
    }
    
    func create(first: String, last: String){
        
        let artworkRecordID = CKRecord.ID(recordName: UUID().uuidString)
        let artworkRecord = CKRecord(recordType: "Poeple", recordID: artworkRecordID)
        
        artworkRecord["first"] = first as NSString
        artworkRecord["last"] = last as NSString
        
        save(artworkRecord: artworkRecord)
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
           // print("saved!!")
            self.dismiss(animated: true, completion: nil)
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
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let view = self.storyboard?.instantiateViewController(withIdentifier: "NewVC") as! NewVC
        view.person = people[indexPath.row]
        present(view, animated: true, completion: nil)
    }
    
    
    
    
    @objc func fetchpeople()
    {
        //deleteAllData(entity: "People")
        people.removeAll()
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
    
    
    func stringToDate(dateStr: String) -> Date {
        
        // Set date format
        let dateFmt = DateFormatter()
        dateFmt.timeZone = NSTimeZone.default
        dateFmt.dateFormat =  "yyyy-MM-dd HH:mm:ss"
        
        // Get NSDate for the given string
        let date = dateFmt.date(from: dateStr)!
        
        return date
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
    
    func lastUpdated(date: String){
        let defaults = UserDefaults.standard
        defaults.set(date, forKey: "lastupdate")
        defaults.synchronize()
    }
    
    func sysLastUpdated() -> String{
        let defaults = UserDefaults.standard
        defaults.synchronize()
        
        if defaults.string(forKey: "lastupdate") != nil{
            return defaults.string(forKey: "lastupdate")!
        }else{
            return ""
        }
        
    }
    
    func deleteAllData(entity: String)
    {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let managedObjectContext = appDelegate?.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        fetchRequest.returnsObjectsAsFaults = false
        
        do
        {
            let results = try managedObjectContext?.fetch(fetchRequest)
            for managedObject in results!
            {
                let managedObjectData:NSManagedObject = managedObject as! NSManagedObject
                managedObjectContext!.delete(managedObjectData)
            }
        } catch let error as NSError {
            print("Detele all data in \(entity) error : \(error) \(error.userInfo)")
        }
    }
    
}

