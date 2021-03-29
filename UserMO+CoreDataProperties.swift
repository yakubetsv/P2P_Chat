//
//  UserMO+CoreDataProperties.swift
//  LemelLabsTest
//
//  Created by Vladislav Yakubets on 29.03.21.
//
//

import Foundation
import CoreData


extension UserMO {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserMO> {
        return NSFetchRequest<UserMO>(entityName: "User")
    }

    @NSManaged public var userID: Int32
    @NSManaged public var userName: String?
    @NSManaged public var messages: NSSet?
    @NSManaged public var chats: NSSet?

}

// MARK: Generated accessors for messages
extension UserMO {

    @objc(addMessagesObject:)
    @NSManaged public func addToMessages(_ value: MessageMO)

    @objc(removeMessagesObject:)
    @NSManaged public func removeFromMessages(_ value: MessageMO)

    @objc(addMessages:)
    @NSManaged public func addToMessages(_ values: NSSet)

    @objc(removeMessages:)
    @NSManaged public func removeFromMessages(_ values: NSSet)

}

// MARK: Generated accessors for chats
extension UserMO {

    @objc(addChatsObject:)
    @NSManaged public func addToChats(_ value: ChatMO)

    @objc(removeChatsObject:)
    @NSManaged public func removeFromChats(_ value: ChatMO)

    @objc(addChats:)
    @NSManaged public func addToChats(_ values: NSSet)

    @objc(removeChats:)
    @NSManaged public func removeFromChats(_ values: NSSet)

}
