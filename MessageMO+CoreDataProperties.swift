//
//  MessageMO+CoreDataProperties.swift
//  LemelLabsTest
//
//  Created by Vladislav Yakubets on 26.03.21.
//
//

import Foundation
import CoreData


extension MessageMO {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MessageMO> {
        return NSFetchRequest<MessageMO>(entityName: "Message")
    }

    @NSManaged public var dateStamp: Date?
    @NSManaged public var messageID: Int32
    @NSManaged public var text: String?
    @NSManaged public var chat: ChatMO?
    @NSManaged public var user: UserMO?

}

extension MessageMO : Identifiable {

}
