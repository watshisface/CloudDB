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
    @IBOutlet weak var syncBtn: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var people : [People] = []
    var peopleFromCloud : [(String, String, String)] = []
    
    var syncTimer = Timer()
    var tableTimer = Timer()
    
    let sync : SYNC = SYNC()
    
    var delegate: CloudKitUpdateDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.refreshsync),
                                               name: NSNotification.Name(rawValue: "peopleupdated"),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.reloadTable),
                                               name: NSNotification.Name(rawValue: "reloadcore"),
                                               object: nil)
        
        tableView.tableFooterView = UIView()
        
        
        
        
        
        sync.handleNotification()
        
        showingProcessing(title: "Syncing...")
        
        let connected : Reachability = Reachability()
        if connected.isConnectedToNetwork() {
            sync.pushToCloud()
        }
    }
    

    
    override func viewDidAppear(_ animated: Bool) {
        
        fetchpeople()
    }
    
    @objc func reloadTable(){
        self.fetchpeople()
    }
    
    @objc func refreshsync(){
        DispatchQueue.main.async {
            self.showingProcessing(title: "Syncing")
        }
    }
    
    
    
    func showingProcessing(title: String) {
        self.syncBtn.isHidden = false
        self.activityIndicator.isHidden = false
        self.syncBtn.setTitle(title, for: UIControl.State.normal)
    }
    
    func hideProcessing(){
        self.syncBtn.isHidden = true
        self.activityIndicator.isHidden = true
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rowsco
        return people.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var status = ""
        print(people)
        let person = people[indexPath.row]
        
        if person.synced {
            status = "Synced"
        }else{
            status = "not synced"
        }
        cell.textLabel?.text = person.firstname! + " " + person.lastname! + "-- \(status)"
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let view = self.storyboard?.instantiateViewController(withIdentifier: "NewVC") as! NewVC
        view.person = people[indexPath.row]
        present(view, animated: true, completion: nil)
    }
    
    
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        return true
    }
    
    
    
    
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        //let (a, b, c) = peopleFromCloud[indexPath.row]
        let person = people[indexPath.row]
        
        let delete = UITableViewRowAction(style: UITableViewRowAction.Style.normal, title: "Delete") { (action: UITableViewRowAction, indexPath: IndexPath) in
            self.sync.deleteFromCloud(recordName: person.id!)
        }
        
        delete.backgroundColor = UIColor.red
        
        return [delete]
    }
    
    
    
    
    @objc func fetchpeople()
    {
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
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.hideProcessing()
                }
            }
        } catch {
            // handle error
        }
        
        
        
    }
    
    @IBAction func syncBtn(_ sender: Any) {
        
        
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

