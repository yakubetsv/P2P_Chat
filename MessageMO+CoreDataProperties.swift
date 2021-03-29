//
//  MessageMO+CoreDataProperties.swift
//  LemelLabsTest
//
//  Created by Vladislav Yakubets on 29.03.21.
//
//

import Foundation
import CoreData


extension MessageMO {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MessageMO> {
        return NSFetchRequest<MessageMO>(entityName: "Message")
    }

    @NSManaged public var dateStamp: Date?
    @NSManaged public var messageID: Int16
    @NSManaged public var data: Data?
    @NSManaged public var type: Int16
    @NSManaged public var chat: ChatMO?
    @NSManaged public var user: UserMO?

}
