//
//  CloudKitPerson.swift
//  clouddatabase
//
//  Created by Marvin Manzi on 12/28/18.
//  Copyright © 2018 Marvin Manzi. All rights reserved.
//

import CloudKit

enum CloudKitNoteError : Error {
    case noteNotFound
    case newerVersionAvailable
    case unexpected
}

public protocol CloudKitPersonDelegate {
    func cloudKitNoteChanged(note: CloudKitPerson)
}

public class CloudKitPerson : CloudKitPersonDatabaseDelegate {
    
    public var delegate: CloudKitPersonDelegate?
    private(set) var first: String?
    private(set) var last: String?
    private(set) var modified: Date?
    
    private let recordName = "note"
    private let version = 1
    private var personRecord: CKRecord?
    
    public init() {
        CloudKitPersonDatabase.shared.delegate = self
    }
    
    // CloudKitNoteDatabaseDelegate call:
    public func cloudKitNoteRecordChanged(record: CKRecord) {
        if record.recordID == self.personRecord?.recordID {
            let (text, first, modified, error) = self.syncToRecord(record: record)
            guard error == nil else {
                return
            }
            
            self.personRecord = record
            self.first = text
            self.last = text
            self.modified = modified
            self.delegate?.cloudKitNoteChanged(note: self)
        }
    }
    
    // Map from CKRecord to our native data fields
    private func syncToRecord(record: CKRecord) -> (String?, String?, Date?, Error?) {
        let version = record["version"] as? NSNumber
        guard version != nil else {
            return (nil, nil, nil, CloudKitNoteError.unexpected)
        }
        guard version!.intValue <= self.version else {
            // Simple example of a version check, in case the user has
            // has updated the client on another device but not this one.
            // A possible response might be to prompt the user to see
            // if the update is available on this device as well.
            return (nil, nil, nil, CloudKitNoteError.newerVersionAvailable)
        }
        let textAsset = record["text"] as? CKAsset
        guard textAsset != nil else {
            return (nil, nil, nil, CloudKitNoteError.noteNotFound)
        }
        
        // CKAsset data is stored as a local temporary file. Read it
        // into a String here.
        let modified = record["modified"] as? Date
        do {
            let text = try String(contentsOf: textAsset!.fileURL)
            return (text, text, modified, nil)
        }
        catch {
            return (nil, nil, nil, error)
        }
    }
    
    
//    // Load a Note from iCloud
//    public func load(completion: @escaping (String?, Date?, Error?) -> Void) {
//        let personDB = CloudKitPersonDatabase.shared
//        personDB.loadRecord(name: recordName) { (record, error) in
//            guard error == nil else {
//                guard let ckerror = error as? CKError else {
//                    completion(nil, nil, error)
//                    return
//                }
//                if ckerror.isRecordNotFound() {
//                    // This typically means we just haven’t saved it yet,
//                    // for example the first time the user runs the app.
//                    completion(nil, nil, CloudKitNoteError.noteNotFound)
//                    return
//                }
//                completion(nil, nil, error)
//                return
//            }
//            guard let record = record else {
//                completion(nil, nil, CloudKitNoteError.unexpected)
//                return
//            }
//
//            let (first, last, modified, error) = self.syncToRecord(record: record)
//            self.personRecord = record
//            self.first = first
//            self.last = last
//            self.modified = modified
//            completion(first, last, modified, error)
//        }
//    }
    
    
    
    // Save a Note to iCloud. If necessary, handle the case of a conflicting change.
    public func save(first: String, last: String, modified: Date, completion: @escaping (Error?) -> Void) {
        guard let record = self.personRecord else {
            // We don’t already have a record. See if there’s one up on iCloud
            let personDB = CloudKitPersonDatabase.shared
            personDB.loadRecord(name: recordName) { record, error in
                if let error = error {
                    guard let ckerror = error as? CKError else {
                        completion(error)
                        return
                    }
                    guard ckerror.isRecordNotFound() else {
                        completion(error)
                        return
                    }
                    // No record up on iCloud, so we’ll start with a
                    // brand new record.
                    let recordID = CKRecord.ID(recordName: self.recordName, zoneID: personDB.zoneID!)
                    self.personRecord = CKRecord(recordType: "note", recordID: recordID)
                    self.personRecord?["version"] = NSNumber(value:self.version)
                }
                else {
                    guard record != nil else {
                        completion(CloudKitNoteError.unexpected)
                        return
                    }
                    self.personRecord = record
                }
                // Repeat the save attempt now that we’ve either fetched
                // the record from iCloud or created a new one.
                self.save(first: first, last: last, modified: modified, completion: completion)
            }
            return
        }
        
        // Save the note text as a temp file to use as the CKAsset data.
        let tempDirectory = NSTemporaryDirectory()
        let tempFileName = NSUUID().uuidString
        let tempFileURL = NSURL.fileURL(withPathComponents: [tempDirectory, tempFileName])
        do {
            try first.write(to: tempFileURL!, atomically: true, encoding: .utf8)
        }
        catch {
            completion(error)
            return
        }
        let textAsset = CKAsset(fileURL: tempFileURL!)
        record["text"] = textAsset
        record["modified"] = modified as NSDate
        saveRecord(record: record) { updated, error in
            defer {
                try? FileManager.default.removeItem(at: tempFileURL!)
            }
            guard error == nil else {
                completion(error)
                return
            }
            guard !updated else {
                // During the save we found another version on the server side and
                // the merging logic determined we should update our local data to match
                // what was in the iCloud database.
                let (first, last, modified, syncError) = self.syncToRecord(record: self.personRecord!)
                guard syncError == nil else {
                    completion(syncError)
                    return
                }
                
                self.first = first
                self.last = last
                self.modified = modified
                
                // Let the UI know the Note has been updated.
                self.delegate?.cloudKitNoteChanged(note: self)
                completion(nil)
                return
            }
            
            self.first = first
            self.modified = modified
            completion(nil)
        }
    }
    
    // This internal saveRecord method will repeatedly be called if needed in the case
    // of a merge. In those cases, we don’t have to repeat the CKRecord setup.
    private func saveRecord(record: CKRecord, completion: @escaping (Bool, Error?) -> Void) {
        let noteDB = CloudKitPersonDatabase.shared
        noteDB.saveRecord(record: record) { error in
            guard error == nil else {
                guard let ckerror = error as? CKError else {
                    completion(false, error)
                    return
                }
                
                let (clientRec, serverRec) = ckerror.getMergeRecords()
                guard let clientRecord = clientRec, let serverRecord = serverRec else {
                    completion(false, error)
                    return
                }
                
                // This is the merge case. Check the modified dates and choose
                // the most-recently modified one as the winner. This is just a very
                // basic example of conflict handling, more sophisticated data models
                // will likely require more nuance here.
                let clientModified = clientRecord["modified"] as? Date
                let serverModified = serverRecord["modified"] as? Date
                if (clientModified?.compare(serverModified!) == .orderedDescending) {
                    // We’ve decided ours is the winner, so do the update again
                    // using the current iCloud ServerRecord as the base CKRecord.
                    serverRecord["text"] = clientRecord["text"]
                    serverRecord["modified"] = clientModified! as NSDate
                    self.saveRecord(record: serverRecord) { modified, error in
                        self.personRecord = serverRecord
                        completion(true, error)
                    }
                }
                else {
                    // We’ve decided the iCloud version is the winner.
                    // No need to overwrite it there but we’ll update our
                    // local information to match to stay in sync.
                    self.personRecord = serverRecord
                    completion(true, nil)
                }
                return
            }
            completion(false, nil)
        }
    }
    
    

}
