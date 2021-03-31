//
//  CoreDataManager.swift
//  LemelLabsTest
//
//  Created by Vladislav Yakubets on 30.03.21.
//

import Foundation
import CoreData
import MultipeerConnectivity

class CoreDataManager {
    static let shared = CoreDataManager()
    
    private init() {}
    
    
    
    func fetchUser(peerID: MCPeerID) -> UserMO? {
        let fetchRequst = NSFetchRequest<UserMO>(entityName: "User")
        fetchRequst.predicate = NSPredicate.init(format: "userName == %@", peerID.displayName)
        
        do {
            let users = try CoreDataManager.shared.persistentContainer.viewContext.fetch(fetchRequst)
            
            if users.isEmpty {
                guard let newUser = createUser(peerID: peerID) else { return nil}
                return newUser
            }
            
            print("User: \(peerID.displayName) alreadry created.")
            return users[0]
        } catch {
            fatalError("\(error)")
        }
    }
    
    func entityForName(entityName name: String) -> NSEntityDescription {
        return NSEntityDescription.entity(forEntityName: name, in: self.persistentContainer.viewContext)!
    }
    
    func createUser(peerID: MCPeerID) -> UserMO? {
        
        let entityDesc = entityForName(entityName: "User")
        let entityModel = UserMO(entity: entityDesc, insertInto: CoreDataManager.shared.persistentContainer.viewContext)
        
        entityModel.userName = peerID.displayName
        
        print("New user is been created: \(String(describing: entityModel.userName))")
        
        CoreDataManager.shared.saveContext()
        
        return entityModel
    }
    
    func fetchChatForUsers(firstUser: UserMO, secondUser: UserMO) -> ChatMO {
        let fetchReques = NSFetchRequest<ChatMO>(entityName: "Chat")
        
        do {
            let chats = try CoreDataManager.shared.persistentContainer.viewContext.fetch(fetchReques)
            
            for chat in chats {
                if chat.users!.contains(firstUser) && chat.users!.contains(secondUser) {
                    print("Chat for users \(firstUser.userName!) and \(secondUser.userName!) already created!")
                    return chat
                }
            }
            return createChatForUsers(firstUser: firstUser, secondUser: secondUser)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    func createChatForUsers(firstUser: UserMO, secondUser: UserMO) -> ChatMO {
        let entityDesc = NSEntityDescription.entity(forEntityName: "Chat", in: CoreDataManager.shared.persistentContainer.viewContext)
        let chatModel = ChatMO(entity: entityDesc!, insertInto: CoreDataManager.shared.persistentContainer.viewContext)
        
        firstUser.addToChats(chatModel)
        secondUser.addToChats(chatModel)
        
        chatModel.addToUsers([firstUser, secondUser])
        
        CoreDataManager.shared.saveContext()
        print("Chat for \(firstUser.userName!) and \(secondUser.userName!) was created!")
        
        return chatModel
    }
    
    
    func fetchMessages(fromChat chat: ChatMO) -> [MessageMO]? {
        guard let setOfMessage = chat.messages as? Set<MessageMO> else { return nil }
        
        return Array(setOfMessage).sorted { (message1: MessageMO, message2: MessageMO) -> Bool in
            return message1.dateStamp! < message2.dateStamp!
        }
    }
}
