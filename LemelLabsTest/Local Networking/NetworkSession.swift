//
//  Created by Vladislav Yakubets on 29.03.21.
//

import Foundation
import MultipeerConnectivity

struct ServiceType {
    static let serviceType = "hws-kb"
}

enum ContentType: String {
    case text
    case image
}

enum CommandType: String {
    case create
    case update
    case delete
}

protocol NetworkSessionDelegate: class {
    func networkSession(_ session: NetworkSession, joined: MCPeerID)
    func networkSession(_ session: NetworkSession, inviteFrom peer: MCPeerID, complition: @escaping ((Bool)->()))
    func networkSession(_ session: NetworkSession, received: NetworkMessage)
    func networkSession(_ stop: NetworkSession)
}

class NetworkSession: NSObject {
    let myself: MCPeerID
    let isServer: Bool
    let host: MCPeerID
    let session: MCSession
    var companionPeerID: MCPeerID!
    
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
    
    func sendNetworkMessage(message: NetworkMessage) {
        let data = message.encode()
        do {
            try session.send(data, toPeers: [companionPeerID!], with: .unreliable)
        }
        catch {
            fatalError(error.localizedDescription)
        }
    }
    
    func stopSession() {
        session.disconnect()
    }
}

extension NetworkSession: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        let secondPeer = peerID
        switch state {
            case .connected:
                print("\(peerID.displayName) is connected.")
                companionPeerID = peerID
                delegate?.networkSession(self, joined: secondPeer)
            case .connecting:
                print("\(peerID.displayName) is connecting")
            case .notConnected:
                delegate?.networkSession(self)
                print("\(peerID.displayName) is not connected.")
            @unknown default:
                fatalError("")
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        let networkMessage = data.decodeJSONToNetworkModel()
        print("???????????????? ??????????????????, ?????? ??????????????????: \(networkMessage.type)")
        delegate?.networkSession(self, received: networkMessage)
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        //
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        //
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        //
    }
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
