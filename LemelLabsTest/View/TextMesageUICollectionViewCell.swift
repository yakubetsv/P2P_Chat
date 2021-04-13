//
//  MessageCell.swift
//  LemelLabsTest
//
//  Created by Vladislav Yakubets on 26.03.21.
//

import UIKit

class TextMesageUICollectionViewCell: UICollectionViewCell {
    public weak var message: MOMessage!
    private var bubbleViewWidth: NSLayoutConstraint?
    
    private let textField: UITextView = {
        let field = UITextView()
        field.font = UIFont.systemFont(ofSize: 16)
        field.translatesAutoresizingMaskIntoConstraints = false
        field.textColor = .white
        field.backgroundColor = .none
        field.isUserInteractionEnabled = false
        return field
    }()
    
    let bubbleView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 18
        view.clipsToBounds = true
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(bubbleView)
        addSubview(textField)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func configureUI() {
        guard let message = message,
              let data = message.data,
              let text = String(data: data, encoding: .utf8) else {
            return
        }
        
        self.constraints.forEach { self.removeConstraint($0) }
        bubbleView.constraints.forEach { bubbleView.removeConstraint($0) }
        
        bubbleView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        let width = estimatedFrameForText(text: text).width + Constants.deltaSize
        
        bubbleViewWidth = bubbleView.widthAnchor.constraint(equalToConstant: width)
        bubbleViewWidth?.isActive = true
        
        bubbleView.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
        textField.text = text
        
        if message.isMe {
            textField.textColor = .white
            bubbleView.backgroundColor = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
            bubbleView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -Constants.indent).isActive = true
        } else {
            textField.textColor = .black
            bubbleView.backgroundColor = #colorLiteral(red: 0.9159229011, green: 0.9159229011, blue: 0.9159229011, alpha: 1)
            bubbleView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: Constants.indent).isActive = true
        }
        
        textField.leftAnchor.constraint(equalTo: bubbleView.leftAnchor).isActive = true
        textField.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        textField.widthAnchor.constraint(equalTo: bubbleView.widthAnchor).isActive = true
        textField.heightAnchor.constraint(equalTo: bubbleView.heightAnchor).isActive = true
    }
    
    
    private func estimatedFrameForText(text: String) -> CGRect {
        let size = CGSize(width: 200, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        
        return NSString(string: text).boundingRect(with: size, options: options, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)], context: nil)
    }
}
