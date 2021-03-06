//
//  ViewController.swift
//  LemelLabsTest
//
//  Created by Vladislav Yakubets on 23.03.21.
//

import UIKit
import MultipeerConnectivity
import CoreData

class RootViewController: UIViewController {
    var user: MOUser?
    
    let dataController: DataController = {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        return delegate.dataController
    }()
    
    var peerID: MCPeerID!
    var isAdvertising = false
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
        peerID = MCPeerID(displayName: UIDevice.current.identifierForVendor!.uuidString)

        view.backgroundColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        configureUI()
        
        user = fetchUser(peerID: peerID)

    }
    
    func fetchUser(peerID: MCPeerID) -> MOUser? {
        let fetchRequst = NSFetchRequest<MOUser>(entityName: "User")
        fetchRequst.predicate = NSPredicate.init(format: "userName == %@", peerID.displayName)
        
        do {
            let users = try dataController.managedObjectContext.fetch(fetchRequst)

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
        return NSEntityDescription.entity(forEntityName: name, in: dataController.managedObjectContext)!
    }

    func createUser(peerID: MCPeerID) -> MOUser? {

        let entityDesc = entityForName(entityName: "User")
        let entityModel = MOUser(entity: entityDesc, insertInto: dataController.managedObjectContext)

        entityModel.userName = peerID.displayName

        print("New user is been created: \(String(describing: entityModel.userName))")

        try? dataController.managedObjectContext.save()

        return entityModel
    }
    
    @objc func startHost() {
        session = NetworkSession(myself: peerID, isServer: true, host: peerID)
        session.delegate = self
        session.startAdvertising()
    }
    
    @objc func joinHost() {
        let nearbyDevicesVC = NearbyUsersViewController()
        nearbyDevicesVC.modalPresentationStyle = .currentContext
        nearbyDevicesVC.peerID = peerID
        nearbyDevicesVC.complition = { (session: NetworkSession) in
            DispatchQueue.main.async {
                let chatVC = ChatLogCollectionViewController(collectionViewLayout: UICollectionViewFlowLayout())
                chatVC.session = session
                chatVC.user = self.user
                chatVC.companionUser = self.fetchUser(peerID: session.companionPeerID)
                self.navigationController?.popViewController(animated: true)
                self.navigationController?.pushViewController(chatVC, animated: true)
            }
        }
        navigationController?.pushViewController(nearbyDevicesVC, animated: true)
    }
    
    private func configureUI() {
        view.addSubview(hostSessionButton)
        hostSessionButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        hostSessionButton.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        hostSessionButton.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -24).isActive = true
        hostSessionButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        view.addSubview(joinSessionButton)
        joinSessionButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        joinSessionButton.topAnchor.constraint(equalTo: hostSessionButton.bottomAnchor).isActive = true
        joinSessionButton.widthAnchor.constraint(equalTo: hostSessionButton.widthAnchor).isActive = true
        joinSessionButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
    
    
}

extension RootViewController: NetworkSessionDelegate {
    func networkSession(_ session: NetworkSession, received: NetworkMessage) {
        //
    }
    
    func networkSession(_ stop: NetworkSession) {
        //
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
    
    func networkSession(_ session: NetworkSession, joined: MCPeerID) {
        session.stopAdvertising()
        
        
        DispatchQueue.main.async {
            let chatVC = ChatLogCollectionViewController(collectionViewLayout: UICollectionViewFlowLayout())
            chatVC.session = session
            chatVC.user = self.user
            chatVC.companionUser = self.fetchUser(peerID: session.companionPeerID)
            self.navigationController?.pushViewController(chatVC, animated: true)
        }
        
    }
}

