//
//  ChatBrowser.swift
//  LemelLabsTest
//
//  Created by Vladislav Yakubets on 28.03.21.
//

import Foundation
import MultipeerConnectivity

protocol ChatBrowserDelegate: class {
    func sawPeers(_ browser: ChatBrowser, sawChats: [MCPeerID])
}

class ChatBrowser: NSObject {
    private let mySelf: MCPeerID
    private let serviceBrowser: MCNearbyServiceBrowser
    
    weak var delegate: ChatBrowserDelegate?
    
    fileprivate var chats: Set<MCPeerID> = []
    
    init(mySelf: MCPeerID) {
        self.mySelf = mySelf
        serviceBrowser = MCNearbyServiceBrowser(peer: mySelf, serviceType: ServiceType.serviceType)
        
        super.init()
        
        serviceBrowser.delegate = self
    }
    
    func start() {
        print("Start browsing peers...")
        serviceBrowser.startBrowsingForPeers()
    }
    
    func stop() {
        print("Stop browsing peers.")
        serviceBrowser.stopBrowsingForPeers()
    }
    
    func join(chat: MCPeerID) -> NetworkSession? {
        guard chats.contains(chat) else { return nil }
        let session = NetworkSession(myself: mySelf, isServer: false, host: chat)
        serviceBrowser.invitePeer(chat, to: session.session, withContext: nil, timeout: 30)
        return session
    }
}

extension ChatBrowser: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("Found \(peerID.displayName)")
        guard peerID != mySelf else { return }
        
        DispatchQueue.main.async {
            self.chats.insert(peerID)
            self.delegate?.sawPeers(self, sawChats: Array(self.chats))
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        print("Lost \(peerID.displayName)")
        
        DispatchQueue.main.async {
            self.chats = self.chats.filter { $0 != peerID }
            self.delegate?.sawPeers(self, sawChats: Array(self.chats))
        }
    }
}
