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
    
        configureUI()
        
        user = CoreDataManager.shared.fetchUser(peerID: peerID)
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
                chatVC.user = self.user
                nearbyDevicesVC.dismiss(animated: true, completion: nil)
                self.navigationController?.pushViewController(chatVC, animated: true)
            }
        }
        present(nearbyDevicesVC, animated: true, completion: nil)
    }
    
    @objc func handleOpenChats() {
        
    }
    
    func configureUI() {
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

extension ViewController: NetworkSessionDelegate {
    func networkSession(_ session: NetworkSession, received data: Data, type: ContentType, command: CommandType, messageID: String) {
        
    }
    
    func networkSession(_ stop: NetworkSession) {
        
    }
    
    func networkSession(_ session: NetworkSession, received data: Data, type: ContentType, command: CommandType) {
        
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
            chatVC.user = self.user
            self.navigationController?.pushViewController(chatVC, animated: true)
        }
        
    }
}

