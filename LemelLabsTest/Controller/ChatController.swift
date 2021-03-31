//
//  Created by Vladislav Yakubets on 25.03.21.
//

import UIKit
import CoreData
import MultipeerConnectivity

private let reuseIdentifier = "Cell"

class ChatController: UICollectionViewController, UITextFieldDelegate, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    var containerViewBottomConstraint: NSLayoutConstraint?
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image = info[.originalImage] as! UIImage
        guard let data = image.pngData() else { return }
        
        do {
            try session.send(data: data, toPeer: session.toPeer, type: .Image)
        } catch {
            print(error.localizedDescription)
        }
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    var session: NetworkSession!
    var user: UserMO!
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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(MessageCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(tap)
        
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
        
        let sendButton = UIButton(type: .system)
        sendButton.setTitle("Send", for: .normal)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
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
        separator.backgroundColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        separator.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(separator)
        
        separator.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        separator.bottomAnchor.constraint(equalTo: containerView.topAnchor, constant: -1).isActive = true
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
            try session.send(data: data, toPeer: session.toPeer, type: .Text)
            let message = MessageMO(chat: chat, user: user, date: Date(), data: data)
            CoreDataManager.shared.saveContext()
            
            print("Отправлено сообщение с текстом: \"\(String(data: message.data!, encoding: .utf8)!).\" \nПользователю \(message.user!.userName!). \n ObjectID: \(message.objectID)")
            print(message.objectID.uriRepresentation().lastPathComponent)
            
            inputTextField.text = nil
            guard let messages = CoreDataManager.shared.fetchMessages(fromChat: chat) else { return }
            self.messages = messages
        } catch {
            print(error.localizedDescription)
        }
    }
    
    @objc func imagePickerButtonPressed() {
        let imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        present(imagePicker, animated: true, completion: nil)
    }
}

//MARK: -NetworkSessionDelegate
extension ChatController: NetworkSessionDelegate {
    func networkSession(_ stop: NetworkSession) {
        CoreDataManager.shared.saveContext()
        print("Connection with \(stop.toPeer!) is lost")
        DispatchQueue.main.async {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    func networkSession(_ session: NetworkSession, received data: Data, type: ContentType) {
        switch type {
            case .Text:
                let message = MessageMO(chat: chat, user: secondUser, date: Date(), data: data)
                CoreDataManager.shared.saveContext()
                
                print("Получено сообщение с текстом: \"\(String(data: message.data!, encoding: .utf8)!).\" \n От пользователя \(message.user!.userName!). \n ObjectID: \(message.objectID)")
                print(message.objectID.uriRepresentation().lastPathComponent)
                
                guard let messages = CoreDataManager.shared.fetchMessages(fromChat: chat) else { return }
                self.messages = messages
            case .Image:
                guard let image = UIImage(data: data) else { return }
                print(image.description)
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
