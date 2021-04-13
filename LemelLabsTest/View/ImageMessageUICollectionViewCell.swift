//
//  ImageCollectionViewCell.swift
//  LemelLabsTest
//
//  Created by Vladislav Yakubets on 12.04.21.
//

import UIKit

class ImageMessageUICollectionViewCell: UICollectionViewCell {
    public weak var message: MOMessage!
    private var bubbleViewWidth: NSLayoutConstraint?
    
    let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 18
        imageView.clipsToBounds = true
        return imageView
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
        bubbleView.addSubview(imageView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func configureUI() {
        guard let message = message,
              let data = message.data,
              let image = UIImage(data: data) else {
            return
        }
        
        self.constraints.forEach { self.removeConstraint($0) }
        bubbleView.constraints.forEach { bubbleView.removeConstraint($0) }
        
        bubbleView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        bubbleView.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
        bubbleView.widthAnchor.constraint(equalToConstant: 200).isActive = true
        
        if message.isMe {
            bubbleView.backgroundColor = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
            bubbleView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -Constants.indent).isActive = true
        } else {
            bubbleView.backgroundColor = #colorLiteral(red: 0.9159229011, green: 0.9159229011, blue: 0.9159229011, alpha: 1)
            bubbleView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: Constants.indent).isActive = true
        }
        
        imageView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor).isActive = true
        imageView.topAnchor.constraint(equalTo: bubbleView.topAnchor).isActive = true
        imageView.widthAnchor.constraint(equalTo: bubbleView.widthAnchor).isActive = true
        imageView.heightAnchor.constraint(equalTo: bubbleView.heightAnchor).isActive = true
        
        imageView.image = image
        imageView.contentMode = .scaleToFill
    }
}
