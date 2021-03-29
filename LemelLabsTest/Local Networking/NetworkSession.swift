//
//  NetworkSession.swift
//  LemelLabsTest
//
//  Created by Vladislav Yakubets on 29.03.21.
//

import Foundation
import MultipeerConnectivity

struct ServiceType {
    static let serviceType = "hws-kb"
}

enum ContentType: String {
    case Text
    case Image
}

protocol NetworkSessionDelegate: class {
    func networkSession(_ session: NetworkSession, received data: Data, fromPeerID: MCPeerID)
    func networkSession(_ session: NetworkSession, joined: MCPeerID)
    func networkSession(_ session: NetworkSession, inviteFrom peer: MCPeerID, complition: @escaping ((Bool)->()))
    func networkSession(_ session: NetworkSession, received data: Data, type: ContentType)
}

class NetworkSession: NSObject {
    let myself: MCPeerID
    let isServer: Bool
    let host: MCPeerID
    let session: MCSession
    var toPeer: MCPeerID!
    
    weak var delegate: NetworkSessionDelegate?
    
    private var serviceAdvertiser: MCNearbyServiceAdvertiser!
    private var serviceBrowser: MCNearbyServiceBrowser!
    
    init(myself: MCPeerID, isServer: Bool, host: MCPeerID) {
        self.myself = myself
        self.isServer = isServer
        self.host = host
        self.session = MCSession(peer: self.myself, securityIdentity: nil, encryptionPreference: .required)
        
        super.init()
        
        self.session.delegate = self
    }
    
    func startAdvertising() {
        guard serviceAdvertiser == nil else { return }
        
        let advertiser = MCNearbyServiceAdvertiser(peer: self.myself, discoveryInfo: nil, serviceType: ServiceType.serviceType)
        advertiser.delegate = self
        advertiser.startAdvertisingPeer()
        print("Start advertising...")
        serviceAdvertiser = advertiser
    }
    
    func stopAdvertising() {
        serviceAdvertiser?.stopAdvertisingPeer()
        serviceAdvertiser = nil
        
        print("Stop advertising...")
    }
    
//    func send(data: Data, toPeer: MCPeerID) throws {
//        try session.send(data, toPeers: [toPeer], with: .reliable)
//    }
    
    func send(data: Data, toPeer: MCPeerID, type: ContentType) throws {
        let fileName = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try data.write(to: fileName)
        
        switch type {
            case .Text:
                session.sendResource(at: fileName, withName: ContentType.Text.rawValue, toPeer: toPeer) { (error) in
                    if error != nil {
                        return
                    }
                    
                    do {
                        try FileManager.default.removeItem(at: fileName)
                    } catch {
                        print("Removing failed")
                    }
                }
            case .Image:
                session.sendResource(at: fileName, withName: ContentType.Image.rawValue, toPeer: toPeer) { (error) in
                    if error != nil {
                        return
                    }
                    
                    do {
                        try FileManager.default.removeItem(at: fileName)
                    } catch {
                        print("Removing failed")
                    }
                }
        }
        
        
    }
    
    func sendImage() {
        
    }
    
    func stopSession() {
        session.disconnect()
    }
    
//    func receive(data: Data, fromPeer: MCPeerID) {
//        delegate?.networkSession(self, received: data, fromPeerID: fromPeer)
//    }
}

extension NetworkSession: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        let secondPeer = peerID
        switch state {
            case .connected:
                print("\(peerID.displayName) is connected.")
                toPeer = peerID
                delegate?.networkSession(self, joined: secondPeer)
            case .connecting:
                print("\(peerID.displayName) is connecting")
            case .notConnected:
                print("\(peerID.displayName) is not connected.")
            @unknown default:
                fatalError("")
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
//        receive(data: data, fromPeer: peerID)
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        if let error = error {
            print(error.localizedDescription)
            return
        }
        
        guard let url = localURL else { return }
        
        do {
            let data = try Data(contentsOf: url)
            
            if resourceName == ContentType.Text.rawValue {
                delegate?.networkSession(self, received: data, type: .Text)
            } else {
                delegate?.networkSession(self, received: data, type: .Image)
            }
        } catch {
            print(error.localizedDescription)
        }
        
        
    }
}

extension NetworkSession: MCAdvertiserAssistantDelegate {
    
}

//MARK: -MCNearbyServiceAdvertiser
extension NetworkSession: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("Invite from \(peerID.displayName)")
        
        delegate?.networkSession(self, inviteFrom: peerID, complition: { (answer) in
            answer ? invitationHandler(true, self.session) : invitationHandler(false, self.session)
        })
    }
}
