//
//  MessageCell.swift
//  LemelLabsTest
//
//  Created by Vladislav Yakubets on 26.03.21.
//

import UIKit

class MessageCell: UICollectionViewCell {
    let textField: UITextView = {
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
    
    var bubbleViewWidthAnchor: NSLayoutConstraint?
    var bubbleViewLeftAnchor: NSLayoutConstraint?
    var bubbleViewRightAnchor: NSLayoutConstraint?
    
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
}
