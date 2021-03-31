//
//  MessageMO+CoreDataClass.swift
//  LemelLabsTest
//
//  Created by Vladislav Yakubets on 30.03.21.
//
//

import Foundation
import CoreData

@objc(MessageMO)
public class MessageMO: NSManagedObject {
    convenience init(chat: ChatMO, user: UserMO, date: Date, data: Data) {
        let desc = CoreDataManager.shared.entityForName(entityName: "Message")
        let context = CoreDataManager.shared.persistentContainer.viewContext
        
        self.init(entity: desc, insertInto: context)
        
        self.chat = chat
        self.user = user
        self.dateStamp = date
        self.data = data
    }
}
