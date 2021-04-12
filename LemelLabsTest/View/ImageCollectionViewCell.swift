//
//  ImageCollectionViewCell.swift
//  LemelLabsTest
//
//  Created by Vladislav Yakubets on 12.04.21.
//

import UIKit

class ImageCollectionViewCell: UICollectionViewCell {
    public weak var message: MessageMO!
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 18
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = true
        imageView.addGestureRecognizer(UIGestureRecognizer(target: self, action: #selector(handleZoomTap)))
        return imageView
    }()
    
    private let bubbleView: UIView = {
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

    private var bubbleViewWidth: NSLayoutConstraint?
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func configureUI() {
        guard let message = message else {
            return
        }
        
        guard let data = message.data else {
            return
        }
        
        guard let image = UIImage(data: data) else {
            return
        }
        
        self.constraints.forEach { self.removeConstraint($0) }
        bubbleView.constraints.forEach { bubbleView.removeConstraint($0) }
        
        bubbleView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        bubbleView.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
        bubbleView.widthAnchor.constraint(equalToConstant: 200).isActive = true
        
        
        if message.isMe {
            bubbleView.backgroundColor = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
            bubbleView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -8).isActive = true
        } else {
            bubbleView.backgroundColor = #colorLiteral(red: 0.9159229011, green: 0.9159229011, blue: 0.9159229011, alpha: 1)
            bubbleView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 8).isActive = true
        }
        
        imageView.leftAnchor.constraint(equalTo: bubbleView.leftAnchor).isActive = true
        imageView.topAnchor.constraint(equalTo: bubbleView.topAnchor).isActive = true
        imageView.widthAnchor.constraint(equalTo: bubbleView.widthAnchor).isActive = true
        imageView.heightAnchor.constraint(equalTo: bubbleView.heightAnchor).isActive = true
        
        imageView.image = image
        imageView.contentMode = .scaleToFill
        
    }
    
    @objc private func handleZoomTap() {
        print("Zoom is tapped")
    }
}
