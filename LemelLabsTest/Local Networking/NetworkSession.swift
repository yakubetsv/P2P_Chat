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

enum CommandType: String {
    case Create
    case Update
    case Delete
}

protocol NetworkSessionDelegate: class {
//    func networkSession(_ session: NetworkSession, received data: Data, fromPeerID: MCPeerID)
    func networkSession(_ session: NetworkSession, joined: MCPeerID)
    func networkSession(_ session: NetworkSession, inviteFrom peer: MCPeerID, complition: @escaping ((Bool)->()))
    func networkSession(_ session: NetworkSession, received: SampleProtocol)
//    func networkSession(_ session: NetworkSession, received data: Data, type: ContentType, command: CommandType)
//    func networkSession(_ session: NetworkSession, received data: Data, type: ContentType, command: CommandType, messageID: String)
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
    
    deinit {
        print("Network Session is dead")
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
    
    func sendNetworkMessage(message: SampleProtocol) {
        let data = message.encode()
        do {
            try session.send(data, toPeers: [companionPeerID!], with: .unreliable)
        }
        catch {
            fatalError(error.localizedDescription)
        }
    }
    
    func send(data: Data, toPeer: MCPeerID, type: ContentType, command: CommandType) throws {
        
        
    }
    
//    func sendEdit(data: Data, toPeer: MCPeerID, type: ContentType, messageID: String) throws {
//        let fileName = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
//        try data.write(to: fileName)
//
//        switch type {
//            case .Text:
//                let url = type.rawValue.appendingFormat("/%@", CommandType.Update.rawValue).appendingFormat("/%@", messageID)
//                session.sendResource(at: fileName, withName: url, toPeer: toPeer) { (error) in
//                    if error != nil {
//                        return
//                    }
//
//                    do {
//                        try FileManager.default.removeItem(at: fileName)
//                    } catch {
//                        print("Removing failed")
//                    }
//                }
//            case .Image:
//                break
//        }
//    }
    
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
        delegate?.networkSession(self, received: networkMessage)
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
//        if let error = error {
//            print(error.localizedDescription)
//            return
//        }
//
//        guard let url = localURL else { return }
//
//        do {
//            let data = try Data(contentsOf: url)
//
//            let args = resourceName.split(separator: "/")
//
//            print(args)
//
//            switch args[0] {
//                case ContentType.Text.rawValue:
//                    switch args[1] {
//                        case CommandType.Create.rawValue:
//                            delegate?.networkSession(self, received: data, type: .Text, command: .Create)
//                        case CommandType.Update.rawValue:
//                            let messageID = args[2]
//                            delegate?.networkSession(self, received: data, type: .Text, command: .Update, messageID: String(messageID))
//                        case CommandType.Delete.rawValue:
//                            let _ = args[2]
//                            break
//                        default:
//                            break
//                    }
//
//                default:
//                    break
//            }
//        } catch {
//            print(error.localizedDescription)
//        }
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
