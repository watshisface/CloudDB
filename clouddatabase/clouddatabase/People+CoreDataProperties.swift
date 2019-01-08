//
//  People+CoreDataProperties.swift
//  clouddatabase
//
//  Created by Marvin Manzi on 12/16/18.
//  Copyright © 2018 Marvin Manzi. All rights reserved.
//
//

import Foundation
import CoreData


extension People {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<People> {
        return NSFetchRequest<People>(entityName: "People")
    }

    @NSManaged public var firstname: String?
    @NSManaged public var lastname: String?
    @NSManaged public var id: String?
    @NSManaged public var synced: Bool
    @NSManaged public var removed: Bool

}
