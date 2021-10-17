//
//  PhotoModel.swift
//  MultiplePictureUploader
//
//  Created by Sunmi on 2021/10/11.
//

import UIKit
import Photos


public class PhotoModel: NSObject {
    
    public var ident: String   // identify
    public var image: UIImage?
    public let asset: PHAsset
   
    public var editImage: UIImage?
    public var isSelected: Bool = false

    
    public init(asset: PHAsset) {
        self.ident = asset.localIdentifier
        self.asset = asset
    }
    
    public var whRatio: CGFloat {
        return CGFloat(self.asset.pixelWidth) / CGFloat(self.asset.pixelHeight)
    }
    
    public var previewSize: CGSize {
        let scale: CGFloat = 2 //UIScreen.main.scale
        if self.whRatio > 1 {
            let h = min(UIScreen.main.bounds.height, 600) * scale
            let w = h * self.whRatio
            return CGSize(width: w, height: h)
        } else {
            let w = min(UIScreen.main.bounds.width, 600) * scale
            let h = w / self.whRatio
            return CGSize(width: w, height: h)
        }
    }
}


public func == (lhs: PhotoModel, rhs: PhotoModel) -> Bool {
   return lhs.ident == rhs.ident
}



