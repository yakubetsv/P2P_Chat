//
//  ViewController.swift
//  LemelLabsTest
//
//  Created by Vladislav Yakubets on 23.03.21.
//

import UIKit
import MultipeerConnectivity
import CoreData

class ViewController: UIViewController {
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var peerID: MCPeerID!
    var isAdvertising = false
    var user: UserMO!
    var session: NetworkSession!
    var browser: ChatBrowser!
    
    let hostSessionButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Host", for: .normal)
        button.addTarget(self, action: #selector(startHost), for: .touchUpInside)
        return button
    }()

    let joinSessionButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Join host", for: .normal)
        button.addTarget(self, action: #selector(joinHost), for: .touchUpInside)
        return button
    }()
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        peerID = MCPeerID(displayName: UIDevice.current.name)
        
        view.backgroundColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        
        configureHostButtonConstraints()
        configureJoinButtonConstraints()
        
        user = fetchUser(peerID: peerID)
        print("Current User: \(user.userName!)")
    }
    
    
    @objc func startHost() {
        session = NetworkSession(myself: peerID, isServer: true, host: peerID)
        session.delegate = self
        session.startAdvertising()
    }
    
    @objc func joinHost() {
        let nearbyDevicesVC = NearbyUsersController()
        nearbyDevicesVC.peerID = peerID
        nearbyDevicesVC.complition = { (session: NetworkSession) in
            DispatchQueue.main.async {
                let chatVC = ChatController(collectionViewLayout: UICollectionViewFlowLayout())
                chatVC.session = session
                nearbyDevicesVC.dismiss(animated: true, completion: nil)
                self.navigationController?.pushViewController(chatVC, animated: true)
            }
        }
        present(nearbyDevicesVC, animated: true, completion: nil)
    }
    
    @objc func handleOpenChats() {
        
    }
    
    func configureHostButtonConstraints() {
        view.addSubview(hostSessionButton)
        hostSessionButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        hostSessionButton.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        hostSessionButton.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -24).isActive = true
        hostSessionButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
    
    func configureJoinButtonConstraints() {
        view.addSubview(joinSessionButton)
        joinSessionButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        joinSessionButton.topAnchor.constraint(equalTo: hostSessionButton.bottomAnchor).isActive = true
        joinSessionButton.widthAnchor.constraint(equalTo: hostSessionButton.widthAnchor).isActive = true
        joinSessionButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
}

extension ViewController: NetworkSessionDelegate {
    func networkSession(_ session: NetworkSession, received data: Data, type: ContentType) {
        
    }
    
    func networkSession(_ session: NetworkSession, inviteFrom peer: MCPeerID, complition: @escaping ((Bool) -> ())) {
        
        DispatchQueue.main.async {
            let title = "Invite from \(peer.displayName)"
            let message = "Accept invite from \(peer.displayName)"
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (_) in
                complition(true)
            }))
            alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { (_) in
                complition(false)
            }))
            
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func networkSession(_ session: NetworkSession, received data: Data, fromPeerID: MCPeerID) {
        
    }
    
    func networkSession(_ session: NetworkSession, joined: MCPeerID) {
        session.stopAdvertising()
        
        
        DispatchQueue.main.async {
            let chatVC = ChatController(collectionViewLayout: UICollectionViewFlowLayout())
            chatVC.session = session
            self.navigationController?.pushViewController(chatVC, animated: true)
        }
        
    }
}


//MARK: -CoreDataMethods
extension ViewController {
    
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
    
    func createUser(peerID: MCPeerID) -> UserMO? {
        
        guard let entityDesc = NSEntityDescription.entity(forEntityName: "User", in: CoreDataManager.shared.persistentContainer.viewContext) else { return nil }
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
}

