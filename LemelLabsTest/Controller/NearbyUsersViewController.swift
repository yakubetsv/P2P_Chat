//
//  NearbyUsersController.swift
//  LemelLabsTest
//
//  Created by Vladislav Yakubets on 28.03.21.
//

import UIKit
import MultipeerConnectivity

class NearbyUsersViewController: UIViewController {
    var peerID: MCPeerID!
    var browser: ChatBrowser!
    var session: NetworkSession!
    var nearbyDevices: [MCPeerID] = [MCPeerID]()
    
    var complition: ((NetworkSession) -> ())?
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.translatesAutoresizingMaskIntoConstraints = false
        return table
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.addSubview(tableView)
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "nearbyDeviceCell")
        
        browser = ChatBrowser(mySelf: peerID)
        browser.delegate = self
        browser.start()
        
        configureUI()
    }
    
    func configureUI() {
        tableView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor).isActive = true
        tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        tableView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor).isActive = true
        tableView.heightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.heightAnchor).isActive = true
    }
}

//MARK: -
extension NearbyUsersViewController: ChatBrowserDelegate {
    func sawPeers(_ browser: ChatBrowser, sawChats: [MCPeerID]) {
        nearbyDevices = sawChats
        tableView.reloadData()
    }
}


//MARK: -TableView DataSource Methods
extension NearbyUsersViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nearbyDevices.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "nearbyDeviceCell") else { return UITableViewCell() }
        cell.textLabel?.text = nearbyDevices[indexPath.row].displayName
        return cell
    }
}

//MARK: -TableView Delegate Methods
extension NearbyUsersViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        session = browser.join(chat: nearbyDevices[indexPath.row])
        session.delegate = self
    }
}

//MARK: -NetworkSession Delegate Methods
extension NearbyUsersViewController: NetworkSessionDelegate {
    func networkSession(_ session: NetworkSession, inviteFrom peer: MCPeerID, complition: @escaping ((Bool) -> ())) {
        //
    }
    
    func networkSession(_ session: NetworkSession, received: NetworkMessage) {
        //
    }
    
    func networkSession(_ stop: NetworkSession) {
        //
    }
    
    
    func networkSession(_ session: NetworkSession, joined: MCPeerID) {
        complition?(session)
    }
}
