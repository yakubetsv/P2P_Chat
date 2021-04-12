//
//  Created by Vladislav Yakubets on 25.03.21.
//

import UIKit
import CoreData
import MultipeerConnectivity



class ChatController: UICollectionViewController, NSFetchedResultsControllerDelegate {
    private let textCellReuseIdentifier = "TextCell"
    private let imageCellReuseIdentifier = "ImageCell"
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView.reloadData()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        collectionView.reloadData()
    }
    
    var context: NSManagedObjectContext?
    var dataController: DataController?
    
    var fetchResultController: NSFetchedResultsController<MessageMO>!
    var containerViewBottomConstraint: NSLayoutConstraint?
    var session: NetworkSession!
    var user: UserMO!
    var companionUser: UserMO? {
        didSet {
            navigationItem.title = companionUser?.userName
        }
    }
    
    var chat: ChatMO? {
        didSet {
            collectionView.reloadData()
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
        collectionView.register(TextCell.self, forCellWithReuseIdentifier: textCellReuseIdentifier)
        collectionView.register(ImageCollectionViewCell.self, forCellWithReuseIdentifier: imageCellReuseIdentifier)
        collectionView.backgroundColor = .white
        
        configureUI()
        context = getContext()
        dataController = getDataController()
        chat = fetchChatForUsers(firstUser: user, secondUser: companionUser!)
        
        initializeFetchResultController()
        
        session.delegate = self
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(tap)
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPressHandler(gesture:)))
        longPress.minimumPressDuration = 0.5
        collectionView.addGestureRecognizer(longPress)
        
        
    }
    
    private func getDataController() -> DataController? {
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else { return nil }
        return delegate.dataController
    }
    
    private func getContext() -> NSManagedObjectContext? {
    
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
            return nil
        }
        let context = delegate.dataController.managedObjectContext
        return context
    }
    
    private func initializeFetchResultController() {
        guard let context = context else {
            return
        }
        guard let chat = chat else {
            return
        }
        
        let fetchRequest = NSFetchRequest<MessageMO>(entityName: "Message")
        let predicate = NSPredicate(format: "chat == %@", chat)
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "dateStamp", ascending: true)]
        fetchResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        fetchResultController.delegate = self
        
        do {
            try fetchResultController.performFetch()
            collectionView.reloadData()
        } catch {
            fatalError("Failed to fetch entities: \(error)")
        }
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
        
        guard let context = context else {
            return
        }
        
        let data = Data(text.utf8)
        let message = MessageMO(context: context)
        message.data = data
        message.chat = chat
        message.isMe = true
        message.user = user
        message.dateStamp = Date()
        
        let messageID = message.objectID.uriRepresentation().lastPathComponent
        
        let networkMessage = SampleProtocol(command: CommandType.Create.rawValue, type: ContentType.Text.rawValue, id: messageID, content: data)
    
        session.sendNetworkMessage(message: networkMessage)
        
        dataController?.saveContext()
        
        print("Отправлено сообщение с текстом: \"\(String(data: message.data!, encoding: .utf8)!)\"\nПользователю \(message.user!.userName!)\nObjectID: \(message.objectID)")
        print(message.objectID.uriRepresentation().lastPathComponent)
        
        inputTextField.text = nil
        
    }
    
    @objc func editButtonPressed() {
//        guard let text = inputTextField.text else { return }
//        let data = Data(text.utf8)
//        guard let messageID = changingMessage?.objectID.uriRepresentation().lastPathComponent else { return }
//
//        do {
//            try session.sendEdit(data: data, toPeer: session.companionPeerID, type: .Text, messageID: messageID)
//
//            changingMessage?.data = data
//
//            print("Сообщение изменено: \"\(String(data: (changingMessage?.data)!, encoding: .utf8)!)\"\nПользователю \(changingMessage!.user!.userName!)\nObjectID: \(changingMessage!.objectID)")
//
//
//            changingMessage = nil
//
//            sendButton.removeTarget(self, action: #selector(editButtonPressed), for: .allEvents)
//            sendButton.setTitle("Send", for: .normal)
//            sendButton.addTarget(self, action: #selector(sendButtonPressed), for: .touchUpInside)
//            inputTextField.text = nil
//
//            dataController?.saveContext()
//        } catch {
//
//        }
    }
    
    @objc func imagePickerButtonPressed() {
        
    }
    
    @objc func longPressHandler(gesture: UILongPressGestureRecognizer) {
        let p = gesture.location(in: self.collectionView)
        guard let indexPath = collectionView.indexPathForItem(at: p) else { return }
        guard let cell = collectionView.cellForItem(at: indexPath) as? TextCell else { return }
        
        if !cell.message.isMe {
            return
        }
        
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
                changingMessage = fetchResultController.object(at: indexPath)
                
                let text = String(data: changingMessage!.data!, encoding: .utf8)
                inputTextField.text = text
                
                sendButton.removeTarget(self, action: #selector(sendButtonPressed), for: .allEvents)
                sendButton.setTitle("Edit", for: .normal)
                sendButton.addTarget(self, action: #selector(editButtonPressed), for: .touchUpInside)
            default:
                break
                
                
        }
    }
    
    func fetchChatForUsers(firstUser: UserMO, secondUser: UserMO) -> ChatMO? {
        guard let context = context else {
            return nil
        }
        
        let fetchReques = NSFetchRequest<ChatMO>(entityName: "Chat")

        do {
            let chats = try context.fetch(fetchReques)

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

    func createChatForUsers(firstUser: UserMO, secondUser: UserMO) -> ChatMO? {
        guard let context = context else {
            return nil
        }
        let entityDesc = NSEntityDescription.entity(forEntityName: "Chat", in: context)
        let chatModel = ChatMO(entity: entityDesc!, insertInto: context)
        
        firstUser.addToChats(chatModel)
        secondUser.addToChats(chatModel)

        chatModel.addToUsers([firstUser, secondUser])

        try? context.save()
        print("Chat for \(firstUser.userName!) and \(secondUser.userName!) was created!")

        return chatModel
    }
}

//MARK: -NetworkSessionDelegate
extension ChatController: NetworkSessionDelegate {
    func networkSession(_ session: NetworkSession, received: SampleProtocol) {
        let text = String(data: received.content, encoding: .utf8)
        print(text!)
        
        
        switch received.command {
            case CommandType.Create.rawValue:
                let message = createMessage(received: received)
                print("Получено сообщение: \(String(data: message.data!, encoding: .utf8)!)")
            case CommandType.Update.rawValue:
                break
            case CommandType.Delete.rawValue:
                break
            default:
                break
        }
    }
    
    func networkSession(_ stop: NetworkSession) {
        print("Connection with \(stop.companionPeerID!) is lost")
        DispatchQueue.main.async {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    func networkSession(_ session: NetworkSession, inviteFrom peer: MCPeerID, complition: @escaping ((Bool) -> ())) {
        //
    }
    
    func networkSession(_ session: NetworkSession, joined: MCPeerID) {
        //
    }
    
    private func createMessage(received: SampleProtocol) -> MessageMO {
        switch received.type {
            case ContentType.Text.rawValue:
                return createTextMessage(received: received)
            case ContentType.Image.rawValue:
                return createImageMessage(received: received)
            default:
                fatalError("Can't create message")
        }
    }
    
    private func createTextMessage(received: SampleProtocol) -> MessageMO {
        guard let context = context else {
            fatalError("Can't create context!")
        }
        
        let message = MessageMO(context: context)
        message.chat = chat
        message.dateStamp = Date()
        message.isMe = false
        message.data = received.content
        message.isText = true
        
        dataController?.saveContext()
        
        return message
    }
    
    private func createImageMessage(received: SampleProtocol) -> MessageMO {
        guard let context = context else {
            fatalError("Can't create context!")
        }
        
        let message = MessageMO(context: context)
        message.chat = chat
        message.dateStamp = Date()
        message.isMe = false
        message.data = received.content
        message.isText = false
        
        dataController?.saveContext()
        
        return message
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
        guard let message = self.fetchResultController?.object(at: indexPath) else {
            fatalError("Attempt to configure cell without a managed object")
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: textCellReuseIdentifier, for: indexPath) as! TextCell
        
        cell.message = message
        cell.configureUI()
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let sections = fetchResultController.sections else {
                fatalError("No sections in fetchedResultsController")
            }
            let sectionInfo = sections[section]
            return sectionInfo.numberOfObjects
    }
}

//MARK: -UICollectionViewDelegateFlowLayout
extension ChatController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height: CGFloat = 80
        
        guard let data = fetchResultController.object(at: indexPath).data, let text = String(data: data, encoding: .utf8) else { return CGSize(width: view.frame.width, height: height) }
        
        height = estimatedFrameForText(text: text).height + 18
        
        return CGSize(width: view.frame.width, height: height)
    }
    
    private func estimatedFrameForText(text: String) -> CGRect {
        let size = CGSize(width: 200, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        
        return NSString(string: text).boundingRect(with: size, options: options, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)], context: nil)
    }
}
