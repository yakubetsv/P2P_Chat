//
//  MessageCell.swift
//  LemelLabsTest
//
//  Created by Vladislav Yakubets on 26.03.21.
//

import UIKit

class MessageCell: UICollectionViewCell {
    
    public weak var message: MessageMO!
    
    private let textField: UITextView = {
        let field = UITextView()
        field.font = UIFont.systemFont(ofSize: 16)
        field.translatesAutoresizingMaskIntoConstraints = false
        field.textColor = .white
        field.backgroundColor = .none
        field.isUserInteractionEnabled = false
        return field
    }()
    
    private let bubbleView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 18
        view.clipsToBounds = true
        return view
    }()
    
    private var bubbleViewWidthAnchor: NSLayoutConstraint?
    private var bubbleViewLeftAnchor: NSLayoutConstraint?
    private var bubbleViewRightAnchor: NSLayoutConstraint?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(bubbleView)
        addSubview(textField)
        configureUI()
    }

    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureUI() {
        bubbleViewRightAnchor = bubbleView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -8)
        bubbleViewRightAnchor?.isActive = true
        
        bubbleViewLeftAnchor = bubbleView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 8)
        bubbleViewRightAnchor?.isActive = false
        
        bubbleView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        bubbleViewWidthAnchor = bubbleView.widthAnchor.constraint(equalToConstant: 200)
        bubbleViewWidthAnchor?.isActive = true
        bubbleView.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
        
        textField.leftAnchor.constraint(equalTo: bubbleView.leftAnchor).isActive = true
        textField.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        textField.widthAnchor.constraint(equalTo: bubbleView.widthAnchor).isActive = true
        textField.heightAnchor.constraint(equalTo: bubbleView.heightAnchor).isActive = true
        
        
    }
    
    private func configureCell() {
        
        guard let message = message else {
            return
        }
        
        guard let data = message.data else {
            return
        }
        
        guard let text = String(data: data, encoding: .utf8) else {
            return
        }
        
        if message.isMe {
            bubbleView.backgroundColor = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
            textField.textColor = .white
            textField.text = text
            if bubbleViewLeftAnchor?.isActive == true { bubbleViewLeftAnchor?.isActive = false}
            bubbleViewRightAnchor?.isActive = true
        } else {
            bubbleView.backgroundColor = #colorLiteral(red: 0.9159229011, green: 0.9159229011, blue: 0.9159229011, alpha: 1)
            textField.textColor = .black
            textField.text = text
            if bubbleViewRightAnchor?.isActive == true { bubbleViewRightAnchor?.isActive = false}
            bubbleViewLeftAnchor?.isActive = true
        }
        
        let width = estimatedFrameForText(text: text).width + 11
        bubbleViewWidthAnchor?.constant = width
    }
    
    private func estimatedFrameForText(text: String) -> CGRect {
        let size = CGSize(width: 200, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        
        return NSString(string: text).boundingRect(with: size, options: options, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)], context: nil)
    }
}
