//
//  Created by Vladislav Yakubets on 25.03.21.
//

import UIKit
import CoreData
import MultipeerConnectivity

private let reuseIdentifier = "Cell"

class ChatController: UICollectionViewController, NSFetchedResultsControllerDelegate {
    
    weak var context: NSManagedObjectContext?
    var containerViewBottomConstraint: NSLayoutConstraint?
    var session: NetworkSession!
    var user: UserMO!
    var frc: NSFetchedResultsController<MessageMO>!
    var secondUser: UserMO! {
        didSet {
            navigationItem.title = secondUser.userName
        }
    }
    
    var chat: ChatMO!
    var messages: [MessageMO]? {
        didSet {
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }
    var changingMessage: MessageMO?
    
    let inputTextField: UITextField = {
        let inputTextFiled = UITextField()
        inputTextFiled.placeholder = "Enter message..."
        inputTextFiled.translatesAutoresizingMaskIntoConstraints = false
        return inputTextFiled
    }()
    
    let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(MessageCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        collectionView.backgroundColor = .white
        
        context = getContext()
        
        let fetchRequest = NSFetchRequest<MessageMO>(entityName: "Message")
        let predicate = NSPredicate(format: "chat == %@", chat)
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "dateStamp", ascending: true)]
        frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        frc.delegate = self
        
        do {
            try frc.performFetch()
        } catch {
            fatalError("Failed to fetch entities: \(error)")
        }
        
        
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(tap)
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPressHandler(gesture:)))
        longPress.minimumPressDuration = 0.5
        collectionView.addGestureRecognizer(longPress)
        
        session.delegate = self
        
        secondUser = CoreDataManager.shared.fetchUser(peerID: session.toPeer)
        chat = CoreDataManager.shared.fetchChatForUsers(firstUser: user, secondUser: secondUser)
        messages = CoreDataManager.shared.fetchMessages(fromChat: chat)
        
        messages?.forEach({ (message) in
            guard let data = message.data, let text = String(data: data, encoding: .utf8), let user = message.user else { return }
            print("Сообщение: \(text), от пользователя \(user.userName!)")
        })
        
        configureUI()
    }
    
    private func getContext() -> NSManagedObjectContext? {
    
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
            return nil
        }
        let context = delegate.dataController.managedObjectContext
        return context
    }
    
    func configureUI() {
        view.backgroundColor = .white
        
        view.addSubview(containerView)

        collectionView.alwaysBounceVertical = true
        collectionView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: containerView.frame.height + 1 + 10 + 30, right: 0)
        
        containerView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor).isActive = true
        containerViewBottomConstraint = containerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        containerViewBottomConstraint?.isActive = true
        containerView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor).isActive = true
        containerView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        sendButton.setTitle("Send", for: .normal)
        sendButton.addTarget(self, action: #selector(sendButtonPressed), for: .touchUpInside)
        
        containerView.addSubview(sendButton)
        
        sendButton.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        sendButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        sendButton.widthAnchor.constraint(equalToConstant: 60).isActive = true
        sendButton.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        let imagePickerButton = UIButton(type: .infoDark)
        imagePickerButton.translatesAutoresizingMaskIntoConstraints = false
        imagePickerButton.addTarget(self, action: #selector(imagePickerButtonPressed), for: .touchUpInside)
        
        containerView.addSubview(imagePickerButton)
        
        imagePickerButton.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 8).isActive = true
        imagePickerButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        imagePickerButton.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        imagePickerButton.widthAnchor.constraint(equalToConstant: 40).isActive = true
        
        
        containerView.addSubview(inputTextField)
        
        inputTextField.leftAnchor.constraint(equalTo: imagePickerButton.rightAnchor, constant: 8).isActive = true
        inputTextField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        inputTextField.rightAnchor.constraint(equalTo: sendButton.leftAnchor).isActive = true
        inputTextField.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        let separator = UIView()
        separator.backgroundColor = #colorLiteral(red: 0.9159229011, green: 0.9159229011, blue: 0.9159229011, alpha: 1)
        separator.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(separator)
        
        separator.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        separator.bottomAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        separator.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        setupKeyBoardObservers()
    }
    
    func setupKeyBoardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillShow), name: ChatController.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillHide), name: ChatController.keyboardWillHideNotification, object: nil)
    }
    
    @objc func handleKeyboardWillShow(notification: Notification) {
        let info: NSDictionary = notification.userInfo! as NSDictionary
        let keyboardFrame = (info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size
        let keyboardDuration = (info[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double)
        
        containerViewBottomConstraint?.constant = -(keyboardFrame!.height - view.safeAreaInsets.bottom)
        
        UIView.animate(withDuration: keyboardDuration) {
            self.view.layoutIfNeeded()
        }

    }
    
    @objc func handleKeyboardWillHide(notification: Notification) {
        let info: NSDictionary = notification.userInfo! as NSDictionary
        let keyboardDuration = (info[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double)
        
        containerViewBottomConstraint?.constant = 0
        
        UIView.animate(withDuration: keyboardDuration) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc func hideKeyboard() {
        view.endEditing(true)
    }
    
    @objc func sendButtonPressed() {
        guard let text = inputTextField.text else { return }
        let data = Data(text.utf8)
        
        do {
            try session.send(data: data, toPeer: session.toPeer, type: .Text, command: .Create)
            
            let message = MessageMO(context: context)
            message.chat = chat
            message.dateStamp = Date()
            message.data = data
            message.user = user
//            let message = MessageMO(chat: chat, user: user, date: Date(), data: data)
//            CoreDataManager.shared.saveContext()
            
//            print("Отправлено сообщение с текстом: \"\(String(data: message.data!, encoding: .utf8)!)\"\nПользователю \(message.user!.userName!)\nObjectID: \(message.objectID)")
//            print(message.objectID.uriRepresentation().lastPathComponent)
            
            inputTextField.text = nil
        } catch {
            print(error.localizedDescription)
        }
    }
    
    @objc func editButtonPressed() {
        guard let text = inputTextField.text else { return }
        let data = Data(text.utf8)
        guard let messageID = changingMessage?.objectID.uriRepresentation().lastPathComponent else { return }
        
        
        do {
            try session.sendEdit(data: data, toPeer: session.toPeer, type: .Text, messageID: messageID)
            
            changingMessage?.data = data
            
            print("Сообщение изменено: \"\(String(data: (changingMessage?.data)!, encoding: .utf8)!)\"\nПользователю \(changingMessage!.user!.userName!)\nObjectID: \(changingMessage!.objectID)")
            
            guard let messages = CoreDataManager.shared.fetchMessages(fromChat: chat) else { return }
            self.messages = messages
            
            changingMessage = nil
            
            sendButton.removeTarget(self, action: #selector(editButtonPressed), for: .allEvents)
            sendButton.setTitle("Send", for: .normal)
            sendButton.addTarget(self, action: #selector(sendButtonPressed), for: .touchUpInside)
            inputTextField.text = nil
        } catch {
            
        }
    }
    
    @objc func imagePickerButtonPressed() {
        
    }
    
    @objc func longPressHandler(gesture: UILongPressGestureRecognizer) {
        let p = gesture.location(in: self.collectionView)
        guard let indexPath = collectionView.indexPathForItem(at: p) else { return }
        guard let cell = collectionView.cellForItem(at: indexPath) else { return }
        
        switch gesture.state {
            case UIGestureRecognizer.State.began:
                collectionView.bringSubviewToFront(cell)
                UIView.animate(withDuration: 0.25) {
                    
                    cell.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
                    
                }
            case UIGestureRecognizer.State.ended:
                UIView.animate(withDuration: 0.25) {
                    cell.transform = .identity
                    }
                
                guard let messages = messages, let data = messages[indexPath.item].data else { return }
                
                changingMessage = messages[indexPath.item]
                let text = String(data: data, encoding: .utf8)
                inputTextField.text = text
                
                sendButton.removeTarget(self, action: #selector(sendButtonPressed), for: .allEvents)
                sendButton.setTitle("Edit", for: .normal)
                sendButton.addTarget(self, action: #selector(editButtonPressed), for: .touchUpInside)
            default:
                break
                
                
        }
    }
}

//MARK: -NetworkSessionDelegate
extension ChatController: NetworkSessionDelegate {
    func networkSession(_ session: NetworkSession, received data: Data, type: ContentType, command: CommandType, messageID: String) {
        switch type {
            case .Text:
                
                switch command {
                    case .Update:
                        let text = String(data: data, encoding: .utf8)
                        print("Получено изменение сообщения с id: \(messageID)\nТекст сообщения: \(text!)")
                        
                        for message in messages! {
                            if message.objectID.uriRepresentation().lastPathComponent == messageID {
                                message.data = data
                                
                            }
                        }
                        
                    default:
                        break
                }
            case .Image:
                break
        }
    }
    
    func networkSession(_ stop: NetworkSession) {
        
        print("Connection with \(stop.toPeer!) is lost")
        DispatchQueue.main.async {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    func networkSession(_ session: NetworkSession, received data: Data, type: ContentType, command: CommandType) {
        
        switch type {
            case .Text:
                switch command {
                    case .Create:
                        
                        let message = MessageMO(context: context)
                        message.user = secondUser
                        message.data = data
                        message.dateStamp = Date()
                        
        
                        print("Получено сообщение с текстом: \"\(String(data: message.data!, encoding: .utf8)!)\"\nОт пользователя \(message.user!.userName!).\nObjectID: \(message.objectID)")
                        print(message.objectID.uriRepresentation().lastPathComponent)
        
                    default:
                        break
                }
                break
            default:
                break
        }
    }
    
    func networkSession(_ session: NetworkSession, inviteFrom peer: MCPeerID, complition: @escaping ((Bool) -> ())) {
        
    }
    
    func networkSession(_ session: NetworkSession, received data: Data, fromPeerID: MCPeerID) {
        
    }
    
    func networkSession(_ session: NetworkSession, joined: MCPeerID) {
        
    }
}

//MARK: -ViewControllerLifeCycle
extension ChatController {
    override func viewDidDisappear(_ animated: Bool) {
        session.stopSession()
    }
}

//MARK: -CollectionViewDataSource
extension ChatController {
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! MessageCell
        
        guard let messages = messages, let data = messages[indexPath.item].data, let text = String(data: data, encoding: .utf8), let user = messages[indexPath.item].user else { return cell }
        
        if user != self.user {
            cell.bubbleView.backgroundColor = #colorLiteral(red: 0.9159229011, green: 0.9159229011, blue: 0.9159229011, alpha: 1)
            cell.textField.textColor = .black
            cell.textField.text = text
            if cell.bubbleViewRightAnchor?.isActive == true { cell.bubbleViewRightAnchor?.isActive = false}
            cell.bubbleViewLeftAnchor?.isActive = true
        } else {
            cell.bubbleView.backgroundColor = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
            cell.textField.textColor = .white
            cell.textField.text = text
            if cell.bubbleViewLeftAnchor?.isActive == true { cell.bubbleViewLeftAnchor?.isActive = false}
            cell.bubbleViewRightAnchor?.isActive = true
        }
        
        let width = estimatedFrameForText(text: text).width + 11
        cell.bubbleViewWidthAnchor?.constant = width
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages?.count ?? 0
    }
    
    
}

//MARK: -UICollectionViewDelegateFlowLayout
extension ChatController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height: CGFloat = 80
        
        guard let data = messages?[indexPath.item].data, let text = String(data: data, encoding: .utf8) else { return CGSize(width: view.frame.width, height: height) }
        
        height = estimatedFrameForText(text: text).height + 18
        
        return CGSize(width: view.frame.width, height: height)
    }
    
    func estimatedFrameForText(text: String) -> CGRect {
        let size = CGSize(width: 200, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        
        return NSString(string: text).boundingRect(with: size, options: options, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)], context: nil)
    }
}
