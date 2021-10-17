//
//  ThumbnailPhotoCell.swift
//  ZLPhotoBrowser
//
//  Created by long on 2020/8/12.
//
//  Copyright (c) 2020 Long Zhang <495181165@qq.com>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import UIKit
import Photos

class ThumbnailPhotoCell: UICollectionViewCell {
    
    var imageView: UIImageView!
    
    var btnSelect: UIButton!
    
    var bottomShadowView: UIImageView!
    
    var videoTag: UIImageView!
    
    var livePhotoTag: UIImageView!
    
    var editImageTag: UIImageView!
    
//    var descLabel: UILabel!
    
    var coverView: UIView!
    
    var indexLabel: UILabel!
    
    var enableSelect: Bool = true
    
    var progressView: ProgressView!
    
    var selectedBlock: ( (Bool) -> Void )?
    
    var model: PhotoModel! {
        didSet {
            self.configureCell()
        }
    }
    

    var index: Int = 0 {
        didSet {
            self.indexLabel.text = String(index)
        }
    }
    
    var imageIdentifier: String = ""
    
    var smallImageRequestID: PHImageRequestID = PHInvalidImageRequestID
    
    var bigImageReqeustID: PHImageRequestID = PHInvalidImageRequestID
    
    let maxSelectCount = 3
    
    deinit {
        debugPrint("ThumbnailPhotoCell deinit")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupUI() {
        self.imageView = UIImageView()
        self.imageView.contentMode = .scaleAspectFill
        self.imageView.clipsToBounds = true
        self.contentView.addSubview(self.imageView)
        
        self.coverView = UIView()
        self.coverView.isUserInteractionEnabled = false
        self.coverView.isHidden = true
        self.contentView.addSubview(self.coverView)
        
        self.btnSelect = UIButton(type: .custom)
        
        let unselectImage = UIImage(named: "img_unselected")
        let selectImage = UIImage(named: "img_selected")
        self.btnSelect.setBackgroundImage(unselectImage, for: .normal)
        self.btnSelect.setBackgroundImage(selectImage, for: .selected)
        self.btnSelect.addTarget(self, action: #selector(btnSelectClick), for: .touchUpInside)
        self.btnSelect.enlargeValidTouchArea(insets: UIEdgeInsets(top: 5, left: 20, bottom: 20, right: 5))
        self.contentView.addSubview(self.btnSelect)
        
        self.indexLabel = UILabel()
        self.indexLabel.layer.cornerRadius = 23.0 / 2
        self.indexLabel.layer.masksToBounds = true
        self.indexLabel.textColor = .white
        self.indexLabel.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        self.indexLabel.adjustsFontSizeToFitWidth = true
        self.indexLabel.minimumScaleFactor = 0.5
        self.indexLabel.textAlignment = .center
        self.btnSelect.addSubview(self.indexLabel)

        self.progressView = ProgressView()
        self.progressView.isHidden = true
        self.contentView.addSubview(self.progressView)

    }
    
    override func layoutSubviews() {
        self.imageView.frame = self.bounds
        self.coverView.frame = self.bounds
        self.btnSelect.frame = CGRect(x: self.bounds.width - 30, y: 8, width: 23, height: 23)
        self.indexLabel.frame = self.btnSelect.bounds
//        self.bottomShadowView.frame = CGRect(x: 0, y: self.bounds.height - 25, width: self.bounds.width, height: 25)
//        self.videoTag.frame = CGRect(x: 5, y: 1, width: 20, height: 15)
//        self.livePhotoTag.frame = CGRect(x: 5, y: -1, width: 20, height: 20)
//        self.editImageTag.frame = CGRect(x: 5, y: -1, width: 20, height: 20)
//        self.descLabel.frame = CGRect(x: 30, y: 1, width: self.bounds.width - 35, height: 17)
        self.progressView.frame = CGRect(x: (self.bounds.width - 20)/2, y: (self.bounds.height - 20)/2, width: 20, height: 20)
        
        super.layoutSubviews()
    }
    

    
    @objc func btnSelectClick() {
        if !self.enableSelect {
            return
        }
        
        self.btnSelect.layer.removeAllAnimations()
        if !self.btnSelect.isSelected {
            self.btnSelect.layer.add(getSpringAnimation(), forKey: nil)
        }
        
        self.selectedBlock?(self.btnSelect.isSelected)
        
        if self.btnSelect.isSelected {
            self.fetchBigImage()
        } else {
            self.progressView.isHidden = true
            self.cancelFetchBigImage()
        }
    }
    
    func getSpringAnimation() -> CAKeyframeAnimation {
        let animate = CAKeyframeAnimation(keyPath: "transform")
        animate.duration = 0.4
        animate.isRemovedOnCompletion = true
        animate.fillMode = .forwards
        
        animate.values = [CATransform3DMakeScale(0.7, 0.7, 1),
                          CATransform3DMakeScale(1.2, 1.2, 1),
                          CATransform3DMakeScale(0.8, 0.8, 1),
                          CATransform3DMakeScale(1, 1, 1)]
        return animate
    }
    
    func configureCell() {
//        if ZLPhotoConfiguration.default().cellCornerRadio > 0 {
//            self.layer.cornerRadius = ZLPhotoConfiguration.default().cellCornerRadio
//            self.layer.masksToBounds = true
//        }
       
        if let _ = self.model.editImage {
            self.bottomShadowView.isHidden = false
//            self.videoTag.isHidden = true
//            self.livePhotoTag.isHidden = true
//            self.editImageTag.isHidden = false
//            self.descLabel.text = ""
        }
        
        let showSelBtn: Bool
        if maxSelectCount > 1 {
            showSelBtn = true
        } else {
            showSelBtn = false
        }
        
        self.btnSelect.isHidden = !showSelBtn
        self.btnSelect.isUserInteractionEnabled = showSelBtn
        self.btnSelect.isSelected = self.model.isSelected
        self.indexLabel.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.8)
        
        if self.model.isSelected {
            self.fetchBigImage()
        } else {
            self.cancelFetchBigImage()
        }
        
        if let ei = self.model.editImage {
            self.imageView.image = ei
        } else {
            self.fetchSmallImage()
        }
    }
    
    func fetchSmallImage() {
        let size: CGSize
        let maxSideLength = self.bounds.width * 1.2
        if self.model.whRatio > 1 {
            let w = maxSideLength * self.model.whRatio
            size = CGSize(width: w, height: maxSideLength)
        } else {
            let h = maxSideLength / self.model.whRatio
            size = CGSize(width: maxSideLength, height: h)
        }
        
        if self.smallImageRequestID > PHInvalidImageRequestID {
            PHImageManager.default().cancelImageRequest(self.smallImageRequestID)
        }
        
        self.imageIdentifier = self.model.ident
        self.imageView.image = nil
        self.smallImageRequestID = PhotoManager.fetchImage(for: self.model.asset, size: size, completion: { [weak self] (image, isDegraded) in
            if self?.imageIdentifier == self?.model.ident {
                self?.imageView.image = image
            }
            if !isDegraded {
                self?.smallImageRequestID = PHInvalidImageRequestID
            }
        })
    }
    
    func fetchBigImage() {
        self.cancelFetchBigImage()
        
        self.bigImageReqeustID = PhotoManager.fetchOriginalImageData(for: self.model.asset, progress: { [weak self] (progress, error, _, _) in
            if self?.model.isSelected == true {
                self?.progressView.isHidden = false
                self?.progressView.progress = max(0.1, progress)
                self?.imageView.alpha = 0.5
                if progress >= 1 {
                    self?.resetProgressViewStatus()
                }
            } else {
                self?.cancelFetchBigImage()
            }
        }, completion: { [weak self] (_, _, _) in
            self?.resetProgressViewStatus()
        })
    }
    
    func cancelFetchBigImage() {
        if self.bigImageReqeustID > PHInvalidImageRequestID {
            PHImageManager.default().cancelImageRequest(self.bigImageReqeustID)
        }
        self.resetProgressViewStatus()
    }
    
    func resetProgressViewStatus() {
        self.progressView.isHidden = true
        self.imageView.alpha = 1
    }
    
    func showBorderColor(_ isShowBorder: Bool) {
        if isShowBorder {
            self.layer.borderWidth = 3
            self.layer.borderColor = UIColor.systemBlue.cgColor
        } else {
            self.layer.borderWidth = 0
            self.layer.borderColor = UIColor.white.cgColor
        }
    }
    
}
