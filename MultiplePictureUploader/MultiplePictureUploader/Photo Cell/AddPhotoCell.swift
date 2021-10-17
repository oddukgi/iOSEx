//
//  AddPhotoCell.swift
//  MultiplePictureUploader
//
//  Created by Sunmi on 2021/10/15.
//

import UIKit

class AddPhotoCell: UICollectionViewCell {
    
    var imageView: UIImageView!
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }
    
    deinit {
        debugPrint("AddPhotoCell deinit")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.imageView.frame = CGRect(x: 0, y: 0, width: self.bounds.width / 3, height: self.bounds.width / 3)
        self.imageView.center = CGPoint(x: self.bounds.midX, y: self.bounds.midY)
        
    }
    
    func setupUI() {
        self.layer.masksToBounds = true
        
        let addImg = UIImage(named: "ic_add")
        self.imageView = UIImageView(image: addImg)
        self.imageView.contentMode = .scaleAspectFit
        self.imageView.clipsToBounds = true
        self.contentView.addSubview(self.imageView)
        
        let grey612 = UIColor(red: 158.0 / 255.0, green: 158.0 / 255.0, blue: 165.0 / 255.0, alpha: 0.12)
        self.backgroundColor = grey612
    }
}
