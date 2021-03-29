//
//  MessageCell.swift
//  LemelLabsTest
//
//  Created by Vladislav Yakubets on 26.03.21.
//

import UIKit

class MessageCell: UICollectionViewCell {
    let textField: UITextField = {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(textField)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureUI() {
        textField.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        textField.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        textField.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
        textField.heightAnchor.constraint(equalTo: self.heightAnchor).isActive = true
    }
}
