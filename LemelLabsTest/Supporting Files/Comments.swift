    
//    func configureOpentChatsButton() {
//        view.addSubview(openChatsButton)
//        openChatsButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
//        openChatsButton.topAnchor.constraint(equalTo: joinSessionButton.bottomAnchor).isActive = true
//        openChatsButton.widthAnchor.constraint(equalTo: joinSessionButton.widthAnchor).isActive = true
//        openChatsButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
//    }
    
//    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
//
//        print("Invite from \(peerID.displayName)")
//
//        if let context = context {
//            print(String(data: context, encoding: .utf8) ?? "nil")
//        }
//
//        let title = "Accept \(peerID.displayName) chat."
//        let message = "Would you like to accept: \(peerID.displayName)"
//
//        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { (_) in
//            invitationHandler(false, self.mcSession)
//        }))
//
//        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { [unowned self] (_) in
//            invitationHandler(true, self.mcSession)
//        }))
//
//        present(alert, animated: true, completion: nil)
//    }


////MARK: - MCSessionDelegate methods
//extension ViewController: MCSessionDelegate {
//    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
//        switch state {
//            case .connected:
//                print("\(peerID.displayName) connected to session!")
//
//                DispatchQueue.main.async { [unowned self] in
//                    self.secondUser = self.fetchUser(peerID: peerID)
//
//                    let chatVC = ChatController(collectionViewLayout: UICollectionViewLayout())
//                    chatVC.mcSession = self.mcSession
//                    chatVC.deliveredPeerID = peerID
//                    chatVC.user = user
//                    chatVC.secondUser = self.secondUser
//                    let chat = self.fetchChatForUsers(firstUser: self.user, secondUser: self.secondUser)
//                    chatVC.chat = chat
//                    self.navigationController?.pushViewController(chatVC, animated: true)
//                }
//            case .connecting:
//                print("\(peerID.displayName) is connecting!")
//            case .notConnected:
//                print("\(peerID.displayName) is not connected!")
//            default:
//                fatalError("Connection state error")
//        }
//    }
//
//    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
//
//    }
//
//    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
//
//    }
//
//    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
//
//    }
//
//    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
//
//    }
//}

//        let browserVC = NearbyUsersController()
//        browserVC.mcSession = mcSession
//        browserVC.mcPeerID = peerID
//        browserVC.view.frame = self.view.frame
//        present(browserVC, animated: true, completion: nil)
    
    
    
//        mcNearbyServiceAdvertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: "hws-kb")
//        mcNearbyServiceAdvertiser.delegate = self
//
//        if isAdvertising {
//            mcNearbyServiceAdvertiser.stopAdvertisingPeer()
//            isAdvertising = false
//            print("Advertising is stopped.")
//            hostSessionButton.setTitle("Host", for: .normal)
//        } else {
//            mcNearbyServiceAdvertiser.startAdvertisingPeer()
//            isAdvertising = true
//            print("Start advertising...")
//            hostSessionButton.setTitle("Stop Host", for: .normal)
//        }
    
    //    let openChatsButton: UIButton = {
    //        let button = UIButton(type: .system)
    //        button.translatesAutoresizingMaskIntoConstraints = false
    //        button.setTitle("Opent chats", for: .normal)
    //        button.addTarget(self, action: #selector(handleOpenChats), for: .touchUpInside)
    //        return button
    //    }()
    
    
//        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .optional)
//        mcSession.delegate = self
    
//    guard let messageText = inputTextField.text else { return }
    //        let data = Data(messageText.utf8)
    //
    //        do {
    //            try mcSession.send(data, toPeers: [deliveredPeerID], with: .reliable)
    //
    //            let messageEntityDesc = NSEntityDescription.entity(forEntityName: "Message", in: appDelegate.persistentContainer.viewContext)
    //            let newMessage = MessageMO(entity: messageEntityDesc!, insertInto: appDelegate.persistentContainer.viewContext)
    //            newMessage.text = messageText
    //            newMessage.user = user
    //            newMessage.chat = chat
    //            newMessage.dateStamp = Date()
    //
    //            chat.messages?.adding(newMessage)
    //
    //            appDelegate.saveContext()
    //
    //            messages.append(newMessage)
    //        } catch {
    //            fatalError(error.localizedDescription)
    //        }
    //
    //        inputTextField.text = ""
