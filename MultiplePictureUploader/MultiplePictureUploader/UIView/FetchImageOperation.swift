//
//  FetchImageOperation.swift
//  MultiplePictureUploader
//
//  Created by Sunmi on 2021/10/12.
//

import UIKit
import Photos

class FetchImageOperation: Operation {
    
    let model: PhotoModel
    
    let isOriginal: Bool
    
    let progress: ( (CGFloat, Error?, UnsafeMutablePointer<ObjCBool>, [AnyHashable : Any]?) -> Void )?
    
    let completion: ( (UIImage?, PHAsset?) -> Void )
    
    var pri_isExecuting = false {
        willSet {
            self.willChangeValue(forKey: "isExecuting")
        }
        didSet {
            self.didChangeValue(forKey: "isExecuting")
        }
    }
    
    override var isExecuting: Bool {
        return self.pri_isExecuting
    }
    
    var pri_isFinished = false {
        willSet {
            self.willChangeValue(forKey: "isFinished")
        }
        didSet {
            self.didChangeValue(forKey: "isFinished")
        }
    }
    
    override var isFinished: Bool {
        return self.pri_isFinished
    }
    
    var pri_isCancelled = false {
        willSet {
            self.willChangeValue(forKey: "isCancelled")
        }
        didSet {
            self.didChangeValue(forKey: "isCancelled")
        }
    }
    
    var requestImageID: PHImageRequestID = PHInvalidImageRequestID
    
    override var isCancelled: Bool {
        return self.pri_isCancelled
    }
    
    init(model: PhotoModel, isOriginal: Bool,
         progress: ( (CGFloat, Error?, UnsafeMutablePointer<ObjCBool>, [AnyHashable : Any]?) -> Void )? = nil,
         completion: @escaping ( (UIImage?, PHAsset?) -> Void )) {
        self.model = model
        self.isOriginal = isOriginal
        self.progress = progress
        self.completion = completion
        super.init()
    }
    
    override func start() {
        if self.isCancelled {
            self.fetchFinish()
            return
        }
        debugPrint("---- start fetch")
        self.pri_isExecuting = true
        
        // 存在编辑的图片
//        if let ei = self.model.editImage {
//            if ZLPhotoConfiguration.default().saveNewImageAfterEdit {
//                ZLPhotoManager.saveImageToAlbum(image: ei) { [weak self] (suc, asset) in
//                    self?.completion(ei, asset)
//                    self?.fetchFinish()
//                }
//            } else {
//                DispatchQueue.main.async {
//                    self.completion(ei, nil)
//                    self.fetchFinish()
//                }
//            }
//            return
//        }
        
 
        self.requestImageID = PhotoManager.fetchImage(for: self.model.asset,
                                                      size: self.model.previewSize, progress: self.progress) { [weak self] (image, isDegraded) in
            if !isDegraded {
                self?.completion(self?.scaleImage(image?.fixOrientation()), nil)
                self?.fetchFinish()
            }
        }
        
    }
    
    func scaleImage(_ image: UIImage?) -> UIImage? {
        guard let i = image else {
            return nil
        }
        guard let data = i.jpegData(compressionQuality: 1) else {
            return i
        }
        let mUnit: CGFloat = 1024 * 1024
        
        if data.count < Int(0.2 * mUnit) {
            return i
        }
        let scale: CGFloat = (data.count > Int(mUnit) ? 0.5 : 0.7)
        
        guard let d = i.jpegData(compressionQuality: scale) else {
            return i
        }
        return UIImage(data: d)
    }
    
    func fetchFinish() {
        self.pri_isExecuting = false
        self.pri_isFinished = true
    }
    
    override func cancel() {
        super.cancel()
        debugPrint("---- cancel \(self.isExecuting) \(self.requestImageID)")
        PHImageManager.default().cancelImageRequest(self.requestImageID)
        self.pri_isCancelled = true
        if self.isExecuting {
            self.fetchFinish()
        }
    }
}
