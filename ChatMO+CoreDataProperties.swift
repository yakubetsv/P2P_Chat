//
//  ChatMO+CoreDataProperties.swift
//  LemelLabsTest
//
//  Created by Vladislav Yakubets on 29.03.21.
//
//

import Foundation
import CoreData


extension ChatMO {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ChatMO> {
        return NSFetchRequest<ChatMO>(entityName: "Chat")
    }

    @NSManaged public var chatID: Int32
    @NSManaged public var messages: NSSet?
    @NSManaged public var users: NSSet?

}

// MARK: Generated accessors for messages
extension ChatMO {

    @objc(addMessagesObject:)
    @NSManaged public func addToMessages(_ value: MessageMO)

    @objc(removeMessagesObject:)
    @NSManaged public func removeFromMessages(_ value: MessageMO)

    @objc(addMessages:)
    @NSManaged public func addToMessages(_ values: NSSet)

    @objc(removeMessages:)
    @NSManaged public func removeFromMessages(_ values: NSSet)

}

// MARK: Generated accessors for users
extension ChatMO {

    @objc(addUsersObject:)
    @NSManaged public func addToUsers(_ value: UserMO)

    @objc(removeUsersObject:)
    @NSManaged public func removeFromUsers(_ value: UserMO)

    @objc(addUsers:)
    @NSManaged public func addToUsers(_ values: NSSet)

    @objc(removeUsers:)
    @NSManaged public func removeFromUsers(_ values: NSSet)

}
