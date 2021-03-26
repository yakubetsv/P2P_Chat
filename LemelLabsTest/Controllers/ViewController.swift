//
//  ViewController.swift
//  LemelLabsTest
//
//  Created by Vladislav Yakubets on 23.03.21.
//

import UIKit
import MultipeerConnectivity
import CoreData

class ViewController: UIViewController, MCNearbyServiceAdvertiserDelegate {
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var peerID: MCPeerID!
    var mcSession: MCSession!
    var isAdvertising = false
    var mcAdvertisingAssistent: MCAdvertiserAssistant!
    var mcNearbyServiceAdvertiser: MCNearbyServiceAdvertiser!
    var user: UserMO!
    var userForChat: UserMO!
    
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
    
    let openChatsButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Opent chats", for: .normal)
        button.addTarget(self, action: #selector(handleOpenChats), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        peerID = MCPeerID(displayName: UIDevice.current.name)
        
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .none)
        mcSession.delegate = self
        
        view.backgroundColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        
        configureHostButtonConstraints()
        configureJoinButtonConstraints()
        configureOpentChatsButton()
        
        user = fetchUser(peerID: peerID)
        print("Current User: \(user.userName!)")
    }
    
    
    @objc func startHost() {
        mcNearbyServiceAdvertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: "hws-kb")
        mcNearbyServiceAdvertiser.delegate = self
        
        if isAdvertising {
            mcNearbyServiceAdvertiser.stopAdvertisingPeer()
            isAdvertising = false
            print("Adretising is stopped.")
            hostSessionButton.setTitle("Host", for: .normal)
        } else {
            mcNearbyServiceAdvertiser.startAdvertisingPeer()
            isAdvertising = true
            print("Start advertising...")
            hostSessionButton.setTitle("Stop Host", for: .normal)
        }
    }
    
    @objc func joinHost() {
        let browserVC = MCBrowserViewController(serviceType: "hws-kb", session: mcSession)
        browserVC.delegate = self
        navigationController?.pushViewController(browserVC, animated: true)
    }
    
    @objc func handleOpenChats() {
        let usersVC = UsersController(style: .grouped)
        usersVC.user = user
        navigationController?.pushViewController(usersVC, animated: true)
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
    
    func configureOpentChatsButton() {
        view.addSubview(openChatsButton)
        openChatsButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        openChatsButton.topAnchor.constraint(equalTo: joinSessionButton.bottomAnchor).isActive = true
        openChatsButton.widthAnchor.constraint(equalTo: joinSessionButton.widthAnchor).isActive = true
        openChatsButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        
        print("Invite from \(peerID.displayName)")
        
        if let context = context {
            print(String(data: context, encoding: .utf8) ?? "nil")
        }
        
        let title = "Accept \(peerID.displayName) chat."
        let message = "Would you like to accept: \(peerID.displayName)"
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { (_) in
            invitationHandler(false, self.mcSession)
        }))
        
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { [unowned self] (_) in
            invitationHandler(true, self.mcSession)
        }))
        
        present(alert, animated: true, completion: nil)
    }
}

//MARK: - MCSessionDelegate methods
extension ViewController: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
            case .connected:
                print("\(peerID.displayName) connected to session!")
                
                DispatchQueue.main.async { [unowned self] in
                    self.userForChat = self.fetchUser(peerID: peerID)
                    
                    let chatVC = ChatController(collectionViewLayout: UICollectionViewFlowLayout())
                    chatVC.mcSession = self.mcSession
                    let _ = self.fetchChatForUsers(firstUser: self.user, secondUser: self.userForChat)
                    self.navigationController?.pushViewController(chatVC, animated: true)
                }
            case .connecting:
                print("\(peerID.displayName) is connecting!")
            case .notConnected:
                print("\(peerID.displayName) is not connected!")
            default:
                fatalError("Connection state error")
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }
    
    
}

//MARK: - MCBrowserViewControllerDelegate
extension ViewController: MCBrowserViewControllerDelegate {
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true, completion: nil)
    }
}

//MARK: -CoreDataMethods
extension ViewController {
    
    func fetchUser(peerID: MCPeerID) -> UserMO {
        let fetchRequst = NSFetchRequest<UserMO>(entityName: "User")
        fetchRequst.predicate = NSPredicate.init(format: "userName == %@", peerID.displayName)
        
        do {
            let users = try appDelegate.persistentContainer.viewContext.fetch(fetchRequst)
            
            if users.isEmpty {
                return createUser(peerID: peerID)
            }
            
            print("User: \(peerID.displayName) alreadry created.")
            return users[0]
        } catch {
            fatalError("\(error)")
        }
    }
    
    func createUser(peerID: MCPeerID) -> UserMO {
        
        let entityDesc = NSEntityDescription.entity(forEntityName: "User", in: appDelegate.persistentContainer.viewContext)
        let entityModel = UserMO(entity: entityDesc!, insertInto: appDelegate.persistentContainer.viewContext)
        
        entityModel.userName = peerID.displayName
        
        print("New user is been created: \(String(describing: entityModel.userName))")
        
        appDelegate.saveContext()
        
        return entityModel
    }
    
    func fetchChatForUsers(firstUser: UserMO, secondUser: UserMO) -> ChatMO {
        let fetchReques = NSFetchRequest<ChatMO>(entityName: "Chat")
        
        do {
            let chats = try appDelegate.persistentContainer.viewContext.fetch(fetchReques)
            
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
        let entityDesc = NSEntityDescription.entity(forEntityName: "Chat", in: appDelegate.persistentContainer.viewContext)
        let chatModel = ChatMO(entity: entityDesc!, insertInto: appDelegate.persistentContainer.viewContext)
        
        firstUser.addToChats(chatModel)
        secondUser.addToChats(chatModel)
        
        chatModel.addToUsers([firstUser, secondUser])
        
        appDelegate.saveContext()
        print("Chat for \(firstUser.userName!) and \(secondUser.userName!) was created!")
        
        return chatModel
    }
}

