//
//  Created by Vladislav Yakubets on 25.03.21.
//

import UIKit
import CoreData
import MultipeerConnectivity

class ChatLogUICollectionViewController: UICollectionViewController {
    private let textCellReuseIdentifier = "TextCell"
    private let imageCellReuseIdentifier = "ImageCell"
    
    var context: NSManagedObjectContext?
    var dataController: DataController?
    var fetchResultController: NSFetchedResultsController<MOMessage>!
    var session: NetworkSession!
    var user: MOUser!
    var companionUser: MOUser? {
        didSet {
            navigationItem.title = companionUser?.userName
        }
    }
    var chat: MOChat? {
        didSet {
            collectionView.reloadData()
        }
    }
    var changingMessage: MOMessage?
    var isEditingImage = false
    var containerViewBottomConstraint: NSLayoutConstraint?
    var containerViewHeightConstraing: NSLayoutConstraint?
    
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
        collectionView.register(TextMesageUICollectionViewCell.self, forCellWithReuseIdentifier: textCellReuseIdentifier)
        collectionView.register(ImageMessageUICollectionViewCell.self, forCellWithReuseIdentifier: imageCellReuseIdentifier)
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
        longPress.minimumPressDuration = 0.25
        collectionView.addGestureRecognizer(longPress)
    }
    
    deinit {
        session.stopSession()
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
        
        let fetchRequest = NSFetchRequest<MOMessage>(entityName: "Message")
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

        containerView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor).isActive = true
        containerViewBottomConstraint = containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        containerViewBottomConstraint?.isActive = true
        containerView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor).isActive = true
        
        let window = UIApplication.shared.keyWindow
        let bottom = window?.safeAreaInsets.bottom
        containerViewHeightConstraing = containerView.heightAnchor.constraint(equalToConstant: Constants.containerViewHeight + bottom!)
        containerViewHeightConstraing?.isActive = true
        
        sendButton.setTitle("Send", for: .normal)
        sendButton.addTarget(self, action: #selector(sendButtonPressed), for: .touchUpInside)
        
        containerView.addSubview(sendButton)
        
        sendButton.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        sendButton.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        sendButton.widthAnchor.constraint(equalToConstant: 60).isActive = true
        sendButton.heightAnchor.constraint(equalToConstant: Constants.containerViewHeight).isActive = true
        
        let imagePickerButton = UIButton(type: .infoDark)
        imagePickerButton.translatesAutoresizingMaskIntoConstraints = false
        imagePickerButton.addTarget(self, action: #selector(imagePickerButtonPressed), for: .touchUpInside)
        
        containerView.addSubview(imagePickerButton)
        
        imagePickerButton.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 8).isActive = true
        imagePickerButton.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        imagePickerButton.heightAnchor.constraint(equalToConstant: Constants.containerViewHeight).isActive = true
        imagePickerButton.widthAnchor.constraint(equalToConstant: Constants.containerViewHeight).isActive = true
        
        containerView.addSubview(inputTextField)
        
        inputTextField.leftAnchor.constraint(equalTo: imagePickerButton.rightAnchor, constant: 8).isActive = true
        inputTextField.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        inputTextField.rightAnchor.constraint(equalTo: sendButton.leftAnchor).isActive = true
        inputTextField.heightAnchor.constraint(equalToConstant: Constants.containerViewHeight).isActive = true
        
        let separator = UIView()
        separator.backgroundColor = #colorLiteral(red: 0.9159229011, green: 0.9159229011, blue: 0.9159229011, alpha: 1)
        separator.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(separator)
        
        separator.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        separator.bottomAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        separator.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        collectionView.alwaysBounceVertical = true
        collectionView.contentInset = UIEdgeInsets(top: Constants.indent, left: 0, bottom: Constants.containerViewHeight + Constants.indent, right: 0)
        
        setupKeyBoardObservers()
    }
    
    func setupKeyBoardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillShow), name: ChatLogUICollectionViewController.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillHide), name: ChatLogUICollectionViewController.keyboardWillHideNotification, object: nil)
    }
    
    @objc func handleKeyboardWillShow(notification: Notification) {
        let info: NSDictionary = notification.userInfo! as NSDictionary
        let keyboardFrame = (info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size
        let keyboardDuration = (info[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double)
        
        containerViewBottomConstraint?.constant = -(keyboardFrame!.height)
        let window = UIApplication.shared.keyWindow
        let bottom = window?.safeAreaInsets.bottom
        containerViewHeightConstraing?.constant = containerViewHeightConstraing!.constant - bottom!
        
        UIView.animate(withDuration: keyboardDuration) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc func handleKeyboardWillHide(notification: Notification) {
        let info: NSDictionary = notification.userInfo! as NSDictionary
        let keyboardDuration = (info[UIResponder.keyboardAnimationDurationUserInfoKey] as! Double)
        
        containerViewBottomConstraint?.constant = 0
        
        let window = UIApplication.shared.keyWindow
        let bottom = window?.safeAreaInsets.bottom
        containerViewHeightConstraing?.constant = Constants.containerViewHeight + bottom!
        
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
        let message = MOMessage(context: context)
        message.data = data
        message.chat = chat
        message.isMe = true
        message.user = user
        message.dateStamp = Date()
        message.isText = true
        message.messageID = UUID()
        
        let networkMessage = SampleProtocol(command: CommandType.create.rawValue, type: ContentType.text.rawValue, id: message.messageID!, content: data)
    
        session.sendNetworkMessage(message: networkMessage)
        
        dataController?.saveContext()
        
        print("Отправлено сообщение с текстом: \"\(String(data: message.data!, encoding: .utf8)!)\"\nПользователю \(message.user!.userName!)\nObjectID: \(message.objectID)")
        print(message.objectID.uriRepresentation().lastPathComponent)
        
        inputTextField.text = nil
        
    }
    
    @objc func editButtonPressed() {
        guard let text = inputTextField.text else {
            return
        }
        let data = Data(text.utf8)
        changingMessage?.data = data
        guard let messageID = changingMessage?.messageID else {
            return
        }
        let networkMessage = SampleProtocol(command: CommandType.update.rawValue, type: ContentType.text.rawValue, id: messageID, content: data)
        session.sendNetworkMessage(message: networkMessage)

        print("Сообщение изменено: \"\(String(data: (changingMessage?.data)!, encoding: .utf8)!)\"\nПользователю \(changingMessage!.user!.userName!)\nObjectID: \(changingMessage!.objectID)")


        changingMessage = nil

        sendButton.removeTarget(self, action: #selector(editButtonPressed), for: .allEvents)
        sendButton.setTitle(NSLocalizedString("Send", comment: "Send button"), for: .normal)
        sendButton.addTarget(self, action: #selector(sendButtonPressed), for: .touchUpInside)
        inputTextField.text = nil

        dataController?.saveContext()
    
    }
    
    @objc func imagePickerButtonPressed() {
        let imagePickerViewController = UIImagePickerController()
        imagePickerViewController.delegate = self
        imagePickerViewController.allowsEditing = true
        imagePickerViewController.modalPresentationStyle = .overFullScreen
        present(imagePickerViewController, animated: true, completion: nil)
    }
    
    private func deleteMessage(message: MOMessage) {
        guard let context = context else {
            return
        }
        guard let id = message.messageID else {
            return
        }
        let deleteMessage = SampleProtocol(command: CommandType.delete.rawValue, type: ContentType.text.rawValue, id: id, content: Data())
        session.sendNetworkMessage(message: deleteMessage)
        context.delete(message)
        dataController?.saveContext()
    }
    
    @objc func longPressHandler(gesture: UILongPressGestureRecognizer) {
        let p = gesture.location(in: self.collectionView)
        guard let indexPath = collectionView.indexPathForItem(at: p) else {
            return
        }
        
        if let cell = collectionView.cellForItem(at: indexPath) as? TextMesageUICollectionViewCell {
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
                    
                    let commandPopUpViewController = CommandPopUpUITableViewController()
                    commandPopUpViewController.modalPresentationStyle = .popover
                    commandPopUpViewController.preferredContentSize = CGSize(width: 200, height: 87)
                    
                    if let popoverController = commandPopUpViewController.popoverPresentationController {
                        popoverController.sourceView = cell.bubbleView
                        popoverController.sourceRect = cell.bubbleView.bounds
                        popoverController.delegate = self
                    }
                    
                    present(commandPopUpViewController, animated: true, completion: nil)
                    
                    commandPopUpViewController.complition = { [self] (command: CommandType) in
                        if command == CommandType.update {
                            self.changingMessage = self.fetchResultController.object(at: indexPath)

                            let text = String(data: self.changingMessage!.data!, encoding: .utf8)
                            self.inputTextField.text = text
                            
                            DispatchQueue.main.async {
                                self.sendButton.removeTarget(self, action: #selector(self.sendButtonPressed), for: .allEvents)
                                self.sendButton.setTitle(NSLocalizedString("Edit", comment: "Edit button"), for: .normal)
                                self.sendButton.addTarget(self, action: #selector(self.editButtonPressed), for: .touchUpInside)
                            }
                        } else if command == CommandType.delete {
                            let deletingMessage = self.fetchResultController.object(at: indexPath)
                            deleteMessage(message: deletingMessage)
                        }
                    }
                default:
                    break
            }
        } else if let cell = collectionView.cellForItem(at: indexPath) as? ImageMessageUICollectionViewCell {
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
                    let commandPopUpViewController = CommandPopUpUITableViewController()
                    commandPopUpViewController.modalPresentationStyle = .popover
                    commandPopUpViewController.preferredContentSize = CGSize(width: 200, height: 87)
                    
                    if let popoverController = commandPopUpViewController.popoverPresentationController {
                        popoverController.sourceView = cell.imageView
                        popoverController.sourceRect = cell.imageView.bounds
                        popoverController.delegate = self
                    }
                    
                    present(commandPopUpViewController, animated: true, completion: nil)
                    
                    commandPopUpViewController.complition = { [self] (command: CommandType) in
                        if command == CommandType.update {
                            changingMessage = fetchResultController.object(at: indexPath)
                            isEditingImage = true
                            let imagePickerViewController = UIImagePickerController()
                            imagePickerViewController.allowsEditing = true
                            imagePickerViewController.delegate = self
                            
                            DispatchQueue.main.async {
                                present(imagePickerViewController, animated: true, completion: nil)
                            }
                        } else if command == CommandType.delete {
                            let deletingMessage = self.fetchResultController.object(at: indexPath)
                            deleteMessage(message: deletingMessage)
                        }
                    }
                default:
                    break
            }
        }
    }
    
    func fetchChatForUsers(firstUser: MOUser, secondUser: MOUser) -> MOChat? {
        guard let context = context else {
            return nil
        }
        
        let fetchReques = NSFetchRequest<MOChat>(entityName: "Chat")

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

    func createChatForUsers(firstUser: MOUser, secondUser: MOUser) -> MOChat? {
        guard let context = context else {
            return nil
        }
        let entityDesc = NSEntityDescription.entity(forEntityName: "Chat", in: context)
        let chatModel = MOChat(entity: entityDesc!, insertInto: context)
        
        firstUser.addToChats(chatModel)
        secondUser.addToChats(chatModel)

        chatModel.addToUsers([firstUser, secondUser])

        try? context.save()
        print("Chat for \(firstUser.userName!) and \(secondUser.userName!) was created!")

        return chatModel
    }
}

//MARK: -NetworkSessionDelegate
extension ChatLogUICollectionViewController: NetworkSessionDelegate {
    func networkSession(_ session: NetworkSession, received: SampleProtocol) {
        switch received.command {
            case CommandType.create.rawValue:
                let _ = createMessage(received: received)
            case CommandType.update.rawValue:
                updateMessage(received: received)
            case CommandType.delete.rawValue:
                deleteMessage(received: received)
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
    
    private func createMessage(received: SampleProtocol) -> MOMessage {
        switch received.type {
            case ContentType.text.rawValue:
                return createTextMessage(received: received)
            case ContentType.image.rawValue:
                return createImageMessage(received: received)
            default:
                fatalError("Can't create message")
        }
    }
    
    private func updateMessage(received: SampleProtocol) {
        fetchResultController.fetchedObjects?.forEach({ (message) in
            if message.messageID == received.id {
                message.data = received.content
            }
        })
        
        dataController?.saveContext()
    }
    
    private func createTextMessage(received: SampleProtocol) -> MOMessage {
        guard let context = context else {
            fatalError("Can't create context!")
        }
        
        let message = MOMessage(context: context)
        message.chat = chat
        message.dateStamp = Date()
        message.isMe = false
        message.data = received.content
        message.isText = true
        message.messageID = received.id
        
        dataController?.saveContext()
        
        return message
    }
    
    private func createImageMessage(received: SampleProtocol) -> MOMessage {
        guard let context = context else {
            fatalError("Can't create context!")
        }
        
        let message = MOMessage(context: context)
        message.chat = chat
        message.dateStamp = Date()
        message.isMe = false
        message.data = received.content
        message.isText = false
        message.messageID = received.id
        
        dataController?.saveContext()
        
        return message
    }
    
    private func deleteMessage(received: SampleProtocol) {
        guard let context = context else {
            return
        }
        let id = received.id
        
        fetchResultController.fetchedObjects?.forEach({ (message: MOMessage) in
            if message.messageID == id {
                context.delete(message)
                dataController?.saveContext()
            }
        })
    }
}

//MARK: -CollectionViewDataSource
extension ChatLogUICollectionViewController {
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let message = self.fetchResultController?.object(at: indexPath) else {
            fatalError("Attempt to configure cell without a managed object")
        }
        
        if message.isText {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: textCellReuseIdentifier, for: indexPath) as! TextMesageUICollectionViewCell
            cell.message = message
            cell.configureUI()
            
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: imageCellReuseIdentifier, for: indexPath) as! ImageMessageUICollectionViewCell
            cell.message = message
            cell.configureUI()
            
            return cell
        }
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
extension ChatLogUICollectionViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height: CGFloat = 200
       
        let message = fetchResultController.object(at: indexPath)
        
        if message.isText {
            guard let data = fetchResultController.object(at: indexPath).data,
                  let text = String(data: data, encoding: .utf8) else {
                return CGSize(width: view.frame.width, height: height)
            }
            
            height = estimatedFrameForText(text: text).height + 18
            
            return CGSize(width: view.frame.width, height: height)
        } else {
            guard let data = message.data,
                  let image = UIImage(data: data) else {
                return CGSize(width: view.frame.width, height: height)
            }
            
            height = CGFloat(image.size.height / image.size.width * 200)
            
            return CGSize(width: view.frame.width, height: height)
        }
    }
    
    private func estimatedFrameForText(text: String) -> CGRect {
        let size = CGSize(width: 200, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        
        return NSString(string: text).boundingRect(with: size, options: options, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)], context: nil)
    }
}

//MARK: -Image Picker Delegate
extension ChatLogUICollectionViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        var message: MOMessage!
        let tempImage: UIImage = info[UIImagePickerController.InfoKey.editedImage] as! UIImage
        guard let context = context,
              let imageData = tempImage.jpegData(compressionQuality: 0.25) else {
            return
        }
        
        if !isEditingImage {
            message = MOMessage(context: context)
            message.data = imageData
            message.chat = chat
            message.isMe = true
            message.user = user
            message.dateStamp = Date()
            message.isText = false
            let messageID = UUID()
            message.messageID = messageID
            let networkMessage = SampleProtocol(command: CommandType.create.rawValue, type: ContentType.image.rawValue, id: message.messageID!, content: imageData)
        
            session.sendNetworkMessage(message: networkMessage)
        } else {
            message = changingMessage
            message.data = imageData
            let networkMessage = SampleProtocol(command: CommandType.update.rawValue, type: ContentType.image.rawValue, id: message.messageID!, content: imageData)
        
            session.sendNetworkMessage(message: networkMessage)
        }
        
        dataController?.saveContext()
        isEditingImage = false
        changingMessage = nil
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        isEditingImage = false
        changingMessage = nil
        dismiss(animated: true, completion: nil)
    }
}

//MARK: -FetchResultController Delegate Methods
extension ChatLogUICollectionViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView.reloadData()
        guard let fetchedObjects = controller.fetchedObjects, let last = fetchedObjects.last, let indexPath = controller.indexPath(forObject: last as! MOMessage) else {
            return
        }
        collectionView.scrollToItem(at: indexPath, at: .bottom, animated: true)
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        collectionView.reloadData()
    }
}

//MARK: -PopoverPresentationController Delegate Methods
extension ChatLogUICollectionViewController: UINavigationControllerDelegate, UIPopoverPresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}
