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
    var peopleFromCloud : [(String, String, String)] = []
    
    var syncTimer = Timer()
    var tableTimer = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        tableView.delegate = self
        
        //Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(self.scheduledFetchWithTimeInterval), userInfo: nil, repeats: true)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.fetchAll),
                                               name: NSNotification.Name(rawValue: "peopleupdated"),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.fetchAll),
                                               name: NSNotification.Name(rawValue: "newperson"),
                                               object: nil)
        

        tableView.tableFooterView = UIView()
        
       // scheduledFetchWithTimeInterval()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {

        fetchAll()
    }
    
    @objc func contactDeleted(notification: NSNotification){
        
        if let (a, b, c) = notification.userInfo?["person"] as? (String, String, String) {
            peopleFromCloud.append((a, b, c))
            
            //self.sortContacts()
            tableView.reloadData()
        }
        
    }
    
    @objc func scheduledFetchWithTimeInterval(){
        // Scheduling timer to Call the function "updateCounting" with the interval of 1 seconds
        syncTimer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(self.fetchAll), userInfo: nil, repeats: true)
       // tableTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(self.fetchpeople), userInfo: nil, repeats: true)
        //tableView.reloadData()
    }

    
//    @objc func fetch(){
//      //  print("fetching updates")
//        let predicate = NSPredicate(value: true)
//        let query = CKQuery(recordType: "Poeple", predicate: predicate)
//        let myContainer = CKContainer(identifier: "iCloud.cloudCommonWorld")
//        let lastUpdate = stringToDate(dateStr: sysLastUpdated())
//        myContainer.privateCloudDatabase.perform(query, inZoneWith: nil) { records, error in
//            for record in records! {
//
//                let modified = record.value(forKey: "modificationDate") as! Date
//                print("\(record.value(forKey: "first")) -- \(modified) -- \(modified > lastUpdate)")
//                if modified > lastUpdate {
//                    let firstname = record.value(forKey: "first") as! String
//                    let lastname = record.value(forKey: "last") as! String
//                    if self.addPerson(first: firstname, last: lastname) {
//
//                    }
//                }
//
//            }
//            self.lastUpdated(date: self.dateToString(date: NSDate()))
//        }
//        DispatchQueue.main.async {
//            self.fetchpeople()
//        }
//    }
    
//    func fetchAll(){
//        let predicate = NSPredicate(value: true)
//        let query = CKQuery(recordType: "Poeple", predicate: predicate)
//        let myContainer = CKContainer(identifier: "iCloud.cloudCommonWorld")
//        myContainer.privateCloudDatabase.perform(query, inZoneWith: nil) { records, error in
//            print(records?.count)
//            for record in records! {
//                let firstname = record.value(forKey: "first") as! String
//                let lastname = record.value(forKey: "last") as! String
//                if self.addPerson(first: firstname, last: lastname) {
//
//                }
//            }
//        }
//        lastUpdated(date: dateToString(date: NSDate()))
//        DispatchQueue.main.async {
//            self.fetchpeople()
//        }
//    }
    
    @objc func fetchAll(){
       // print("Fetching from cloud!!")
        peopleFromCloud.removeAll()
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "Poeple", predicate: predicate)
        let myContainer = CKContainer(identifier: "iCloud.cloudCommonWorld")
        myContainer.privateCloudDatabase.perform(query, inZoneWith: nil) { records, error in
          //  print(records?.count)
            for record in records! {
                let firstname = record.value(forKey: "first") as! String
                let lastname = record.value(forKey: "last") as! String
                self.peopleFromCloud.append((firstname, lastname, record.recordID.recordName))
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
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
    
    
    
     func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rowsco
        return peopleFromCloud.count
    }
    
    
     func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        let (a, b, _) = peopleFromCloud[indexPath.row]
        cell.textLabel?.text = a + " " + b
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let view = self.storyboard?.instantiateViewController(withIdentifier: "NewVC") as! NewVC
        //view.person = people[indexPath.row]
        let (a, b, c) = peopleFromCloud[indexPath.row]
        view.firstname = a
        view.lastname = b
        view.recordName = c
        present(view, animated: true, completion: nil)
    }
    
    
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        return true
    }
    
    
    
    
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let (a, b, c) = peopleFromCloud[indexPath.row]
        
        let delete = UITableViewRowAction(style: UITableViewRowAction.Style.normal, title: "Delete") { (action: UITableViewRowAction, indexPath: IndexPath) in
            
           self.deletingCKRecord(recordName: c)
            self.peopleFromCloud.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
        }
        
        delete.backgroundColor = UIColor.red
        
        return [delete]
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
        
//        for person in people {
//            if updatePerson(person: person) {
//               // print("updated : \(person.firstname)")
//            }
//        }
        
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
    
    func deletingCKRecord(recordName: String){
        
        let recordID = CKRecord.ID(recordName: recordName)
        
        
        let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: [recordID])
        operation.savePolicy = .allKeys
        operation.modifyRecordsCompletionBlock = { added, deleted, error in
            if error != nil {
                print(error) // print error if any
            } else {
                // no errors, all set!
            }
        }
        
        let myContainer = CKContainer(identifier: "iCloud.cloudCommonWorld")
        //let publicDatabase = myContainer.publicCloudDatabase
        let database = myContainer.privateCloudDatabase
        database.add(operation)
    }
    
    
    
    
    
}

extension CKError {
    public func isRecordNotFound() -> Bool {
        return isZoneNotFound() || isUnknownItem()
    }
    public func isZoneNotFound() -> Bool {
        return isSpecificErrorCode(code: .zoneNotFound)
    }
    public func isUnknownItem() -> Bool {
        return isSpecificErrorCode(code: .unknownItem)
    }
    public func isConflict() -> Bool {
        return isSpecificErrorCode(code: .serverRecordChanged)
    }
    public func isSpecificErrorCode(code: CKError.Code) -> Bool {
        var match = false
        if self.code == code {
            match = true
        }
        else if self.code == .partialFailure {
            // This is a multiple-issue error. Check the underlying array
            // of errors to see if it contains a match for the error in question.
            guard let errors = partialErrorsByItemID else {
                return false
            }
            for (_, error) in errors {
                if let cke = error as? CKError {
                    if cke.code == code {
                        match = true
                        break
                    }
                }
            }
        }
        return match
    }
    // ServerRecordChanged errors contain the CKRecord information
    // for the change that failed, allowing the client to decide
    // upon the best course of action in performing a merge.
    public func getMergeRecords() -> (CKRecord?, CKRecord?) {
        if code == .serverRecordChanged {
            // This is the direct case of a simple serverRecordChanged Error.
            return (clientRecord, serverRecord)
        }
        guard code == .partialFailure else {
            return (nil, nil)
        }
        guard let errors = partialErrorsByItemID else {
            return (nil, nil)
        }
        for (_, error) in errors {
            if let cke = error as? CKError {
                if cke.code == .serverRecordChanged {
                    // This is the case of a serverRecordChanged Error
                    // contained within a multi-error PartialFailure Error.
                    return cke.getMergeRecords()
                }
            }
        }
        return (nil, nil)
    }
}

