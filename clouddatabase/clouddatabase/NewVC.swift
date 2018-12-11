//
//  NewVC.swift
//  clouddatabase
//
//  Created by Marvin Manzi on 12/11/18.
//  Copyright © 2018 Marvin Manzi. All rights reserved.
//

import UIKit
import CloudKit


class NewVC: UIViewController {

    @IBOutlet weak var first: UITextField!
    @IBOutlet weak var last: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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
        
        let artworkRecordID = CKRecord.ID(recordName: "\(Date())")
        let artworkRecord = CKRecord(recordType: "Poeple", recordID: artworkRecordID)
        
        artworkRecord["first"] = first.text! as NSString
        artworkRecord["last"] = last.text! as NSString
        
        save(artworkRecord: artworkRecord)
        
    }
    

    func save(artworkRecord: CKRecord){
        //let myContainer = CKContainer.default()
        let myContainer = CKContainer(identifier: "iCloud.cloudCommonWorld")
        let publicDatabase = myContainer.publicCloudDatabase
        
        publicDatabase.save(artworkRecord) {
            (record, error) in
            if let error = error {
                // Insert error handling
                print(error)
                return
            }
            // Insert successfully saved record code
            print("saved!!")
            self.dismiss(animated: true, completion: nil)
        }
    }
    @IBAction func cancel(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func new(_ sender: Any) {
        create()
    }
    
}
