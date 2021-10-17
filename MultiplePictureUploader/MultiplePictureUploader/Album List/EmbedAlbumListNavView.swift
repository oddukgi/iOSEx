//
//  EmbedAlbumListNavView.swift
//  MultiplePictureUploader
//
//  Created by Sunmi on 2021/10/12.
//

import UIKit

private var edgeKey = "edgeKey"

// MARK: embed album list nav view
class EmbedAlbumListNavView: UIView {
    
    static let titleViewH: CGFloat = 32
    
    static let arrowH: CGFloat = 20
    
    var title: String {
        didSet {
            self.albumTitleLabel.text = title
            self.refreshTitleViewFrame()
        }
    }
    

    var titleBgControl: UIControl!
    
    var albumTitleLabel: UILabel!
    
    var arrow: UIImageView!
    
    var cancelBtn: UIButton!
    
    var doneBtn: UIButton!
    
    var selectAlbumBlock: ( () -> Void )?
    
    var cancelBlock: ( () -> Void )?
    
    var doneBlock: ( () -> Void )?
  
    var arrSelectedModels: [PhotoModel] = [] {
        didSet {
            self.refreshDoneButton()

        }
    }
    
    private var insets = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)

    
    init(title: String) {
        self.title = title

        super.init(frame: .zero)
        self.setupUI()
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if #available(iOS 11.0, *) {
            insets = self.safeAreaInsets
        }

        self.refreshTitleViewFrame()
        self.refreshDoneButton()
    }
    
    func refreshTitleViewFrame() {

        let font = UIFont.systemFont(ofSize: 17)
        let albumTitleW = min(self.bounds.width / 2, self.title.boundingRect(font: font, limitSize: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 44)).width)
        let titleBgControlW = albumTitleW + EmbedAlbumListNavView.arrowH + 20
        
//        UIView.animate(withDuration: 0.25) {
        titleBgControl.frame = CGRect(x: (self.frame.width-titleBgControlW)/2, y: insets.top+(44-EmbedAlbumListNavView.titleViewH)/2,
                                           width: titleBgControlW, height: EmbedAlbumListNavView.titleViewH)
        
        albumTitleLabel.frame = CGRect(x: 10, y: 0, width: albumTitleW + 10, height: EmbedAlbumListNavView.titleViewH)
//
//        self.albumTitleLabel.frame = CGRect(x: 10, y: 0, width: albumTitleW, height: EmbedAlbumListNavView.titleViewH)
        arrow.frame = CGRect(x: self.albumTitleLabel.frame.maxX+5, y: (EmbedAlbumListNavView.titleViewH - EmbedAlbumListNavView.arrowH)/2.0, width: EmbedAlbumListNavView.arrowH, height: EmbedAlbumListNavView.arrowH)

    }
    
    func refreshDoneButton() {
        
        doneBtn.backgroundColor = .white
        if arrSelectedModels.count > 0 {
            
            let selCount = arrSelectedModels.count
            self.doneBtn.isEnabled = true
            let doneTitle = "\(selCount) " + localLanguageTextValue(.done)
            let strCount = String(selCount)
            updateNumberInButton(doneTitle: doneTitle, selCount: strCount)
            doneBtn.isEnabled = true
            
        } else {
            
            setDoneButtonStyle(fontClr: .black)
            doneBtn.isEnabled = false
        }
        self.refreshDoneBtnFrame()
    }

    
    func updateNumberInButton(doneTitle: String, selCount: String){
        let attributedString = NSMutableAttributedString(string: doneTitle)

        let boldFont = UIFont.systemFont(ofSize: 15.5, weight: .bold)

        let titleAttributes: [NSAttributedString.Key : Any] = [
            NSAttributedString.Key.foregroundColor: UIColor.systemBlue,
            NSAttributedString.Key.font : boldFont
        ]

        attributedString.addAttributes(titleAttributes, range:  NSRange(location: 0, length: selCount.count))
        doneBtn.setAttributedTitle(attributedString, for: UIControl.State.normal)
    }
    
    func refreshDoneBtnFrame() {
        let selCount = arrSelectedModels.count
        var doneTitle = localLanguageTextValue(.done)
        if selCount > 0 {
            doneTitle += "\(selCount) " + localLanguageTextValue(.done)
        }
        
        let doneFont = UIFont.systemFont(ofSize: 15.5)
        let doneBtnW = doneTitle.boundingRect(font: doneFont, limitSize: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 30)).width + 20
        
        var x = bounds.width - doneBtnW
        let y = insets.top+(44-EmbedAlbumListNavView.titleViewH)/2
        
        if doneTitle.contains(String(selCount)) {
            x = x + 8
        }
        
        self.doneBtn.frame = CGRect(x: x, y: y, width: doneBtnW, height: 34)
        self.cancelBtn.frame = CGRect(x: insets.left+18, y: y + 2, width: 15, height: 15)
    }
    
    
    func setupUI() {
        self.backgroundColor = .white

        titleBgControl = UIControl()
        titleBgControl.backgroundColor = .clear
        titleBgControl.addTarget(self, action: #selector(titleBgControlClick), for: .touchUpInside)
        self.addSubview(titleBgControl)
        
        albumTitleLabel = UILabel()
        albumTitleLabel.textColor = .black
        albumTitleLabel.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        albumTitleLabel.text = self.title
        albumTitleLabel.textAlignment = .center
        titleBgControl.addSubview(self.albumTitleLabel)
        
        let downArrowImg = UIImage(named: "caretDown")
        arrow = UIImageView(image: downArrowImg)
        arrow.clipsToBounds = true
        arrow.contentMode = .scaleAspectFill
        titleBgControl.addSubview(self.arrow)
        
        cancelBtn = UIButton(type: .custom)
        let cancelImg = UIImage(named: "close")
  
        cancelBtn.clipsToBounds = true
        cancelBtn.contentMode = .scaleAspectFill
        cancelBtn.setImage(cancelImg, for: .normal)
        cancelBtn.addTarget(self, action: #selector(cancelBtnClick), for: .touchUpInside)
        cancelBtn.adjustsImageWhenHighlighted = false
        cancelBtn.enlargeValidTouchArea(insets: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
        self.addSubview(self.cancelBtn)
        
        doneBtn = UIButton(type: .custom)
        doneBtn.titleLabel?.textColor = .black
        doneBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15.5)
        doneBtn.addTarget(self, action: #selector(doneBtnClick), for: .touchUpInside)
        self.addSubview(self.doneBtn)
    }
    
    func setDoneButtonStyle(fontClr: UIColor) {
        
        let font = UIFont.systemFont(ofSize: 15.5)
        let doneTitle = localLanguageTextValue(.done)
        
        let titleAttributes: [NSAttributedString.Key : Any] = [
            NSAttributedString.Key.foregroundColor: fontClr,
            NSAttributedString.Key.font : font
        ]


        let attributedString = NSMutableAttributedString(string: doneTitle, attributes: titleAttributes)
        doneBtn.setAttributedTitle(attributedString, for: UIControl.State.normal)
        doneBtn.isEnabled = false

    }

    
    @objc func titleBgControlClick() {
        self.selectAlbumBlock?()
        if self.arrow.transform == .identity {
            UIView.animate(withDuration: 0.25) {
                self.arrow.transform = CGAffineTransform(rotationAngle: .pi)
            }
        } else {
            UIView.animate(withDuration: 0.25) {
                self.arrow.transform = .identity
            }
        }
    }
    
    @objc func cancelBtnClick() {
        self.cancelBlock?()
    }
    
    
    @objc func doneBtnClick() {
        self.doneBlock?()
    }
    
    func reset() {
        UIView.animate(withDuration: 0.25) {
            self.arrow.transform = .identity
        }
    }

    
}

extension UIControl {
    
    private var insets: UIEdgeInsets? {
    
        get {
            if let temp = objc_getAssociatedObject(self, &edgeKey) as? UIEdgeInsets  {
                return temp
            }
            return nil
        }
        set {
            objc_setAssociatedObject(self, &edgeKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    
    
    open override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard !self.isHidden && self.alpha != 0 else {
            return false
        }
        
        let rect = self.enlargeRect()
        
        if rect.equalTo(self.bounds) {
            return super.point(inside: point, with: event)
        }
        return rect.contains(point) ? true : false
    }
    
    private func enlargeRect() -> CGRect {
        guard let edge = self.insets else {
            return self.bounds
        }
        
        let rect = CGRect(x: self.bounds.minX - edge.left, y: self.bounds.minY - edge.top, width: self.bounds.width + edge.left + edge.right, height: self.bounds.height + edge.top + edge.bottom)
        
        return rect
    }
    
    
    func enlargeValidTouchArea(insets: UIEdgeInsets) {
        self.insets = insets
    }
    
    
    func enlargeValidTouchArea(inset: CGFloat) {
        guard inset != 0 else {
            return
        }
        self.insets = UIEdgeInsets(top: inset, left: inset, bottom: inset, right: inset)
    }
}
