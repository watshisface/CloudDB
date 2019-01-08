//
//  SYNCPerson.swift
//  clouddatabase
//
//  Created by Marvin Manzi on 1/4/19.
//  Copyright © 2019 Marvin Manzi. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import CloudKit
import SystemConfiguration



class SYNCPerson {
    
    var first : String!
    var last: String!
    
    
    public var zoneID: CKRecordZone.ID?
    
    public init() {
        
        let zone = CKRecordZone(zoneName: "prototype")
        zoneID = zone.zoneID
        
    }
    
    private var personRecord: CKRecord?
    private let recordName = "Poeple"
    private let version = 1
    private(set) var modified: Date?
    var internetConnection: Reachability = Reachability()
    
    let sync: SYNC = SYNC()
    
    func saveRecord(andToCloud: Bool) -> Bool {
        if saveToCore() {
            if internetConnection.isConnectedToNetwork() {
                if andToCloud {
                    if saveToCloud() {
                        return true
                    }
                }else{
                    return true
                }
            }else{
                return true
            }
        }
        return false
    }
    
    func saveToCore() -> Bool {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let managedObjectContext = appDelegate?.persistentContainer.viewContext
        managedObjectContext?.mergePolicy = NSMergePolicy(merge: .mergeByPropertyObjectTrumpMergePolicyType)
        guard let _context = managedObjectContext else { return false }
        
        let object = NSEntityDescription.insertNewObject(forEntityName: "People", into: managedObjectContext!) as! People
        
        object.firstname = first
        object.lastname = last
        object.id = UUID().uuidString
        if internetConnection.isConnectedToNetwork() {
            object.synced = true
        }else{
            object.synced = false
        }
        
        object.removed = false
        
        print(object)
        do {
            try _context.save()
            //TODO: put check for internet connection
            return true
        } catch {
            print("not Saved")
        }
        return false
    }
    
    
    
    func saveToCloud() -> Bool {
        let recordID = CKRecord.ID(recordName: UUID().uuidString, zoneID: zoneID!)
        self.personRecord?["version"] = NSNumber(value:self.version)
        let record = CKRecord(recordType: "Poeple", recordID: recordID)
        
        record["first"] = first as NSString
        record["last"] = last as NSString
        let sync: SYNC = SYNC()
        if sync.saveToCloud(record: record){
            sync.recordSycned(id: recordID.recordName)
            return true
        }
        return false
    }
    
    
    
    
}



public class Reachability {
    public func isConnectedToNetwork() -> Bool {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else {
            return false
        }
        
        var flags: SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return false
        }
        if flags.isEmpty {
            return false
        }
        
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        
        return (isReachable && !needsConnection)
    }
}
