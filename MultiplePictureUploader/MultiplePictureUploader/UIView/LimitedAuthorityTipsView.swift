//
//  LimitedAuthorityTipsView.swift
//  MultiplePictureUploader
//
//  Created by Sunmi on 2021/10/14.
//

import UIKit

class LimitedAuthorityTipsView: UIView {
    
    static let height: CGFloat = 70
    
    var icon: UIImageView!
    
    var tipsLabel: UILabel!
    
    var arrow: UIImageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let warnignImg = UIImage(named: "warning")
        self.icon = UIImageView(image: warnignImg)
        self.addSubview(self.icon)
        
        self.tipsLabel = UILabel()
        self.tipsLabel.font = UIFont.systemFont(ofSize: 14)
        self.tipsLabel.text = localLanguageTextValue(.unableToAccessAllPhotos)
    
        let grayColor = UIColor(red: 92.0 / 255.0, green: 92.0 / 255.0, blue: 98.0 / 255.0, alpha: 1.0)
        self.tipsLabel.textColor = grayColor
        self.tipsLabel.numberOfLines = 2
        self.tipsLabel.lineBreakMode = .byTruncatingTail
        self.tipsLabel.adjustsFontSizeToFitWidth = true
        self.tipsLabel.minimumScaleFactor = 0.5
        self.addSubview(self.tipsLabel)
        
        let arrowImg = UIImage(named: "right_arrow")
        self.arrow = UIImageView(image: arrowImg)
        self.addSubview(self.arrow)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapAction))
        self.addGestureRecognizer(tap)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.icon.frame = CGRect(x: 18, y: (LimitedAuthorityTipsView.height - 25) / 2, width: 25, height: 25)
        self.tipsLabel.frame = CGRect(x: 55, y: (LimitedAuthorityTipsView.height - 40) / 2, width: self.frame.width-55-30, height: 40)
        self.arrow.frame = CGRect(x: self.frame.width-25, y: (LimitedAuthorityTipsView.height - 12) / 2, width: 12, height: 12)
    }
    
    @objc func tapAction() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
}
