//
//  AlbumListModel.swift
//  MultiplePictureUploader
//
//  Created by Sunmi on 2021/10/11.
//

import UIKit
import Photos

public class AlbumListModel: NSObject {
    
    public let title: String
    
    public var count: Int {
        return result.count
    }
    
    public var result: PHFetchResult<PHAsset>
    
    public let collection: PHAssetCollection
    
    public let option: PHFetchOptions
    
    public let isCameraRoll: Bool
    
    public var headImageAsset: PHAsset? {
        return result.lastObject
    }
    
    public var models: [PhotoModel] = []
    
    private var selectedModels: [PhotoModel] = []
    private var selectedCount: Int = 0
    
    init(title: String, result: PHFetchResult<PHAsset>, collection: PHAssetCollection,
         option: PHFetchOptions, isCameraRoll: Bool) {
        self.title = title
        self.result = result
        self.collection = collection
        self.option = option
        self.isCameraRoll = isCameraRoll
    }
    
    public func refetchPhotos() {
        let models = PhotoManager.fetchPhoto(in: self.result,
                                             ascending: false,
                                             allowSelectImage: true,
                                             allowSelectVideo:  false)
        self.models.removeAll()
        self.models.append(contentsOf: models)
    }
    
    func refreshResult() {
        self.result = PHAsset.fetchAssets(in: self.collection, options: self.option)
    }
    
}


func ==(lhs: AlbumListModel, rhs: AlbumListModel) -> Bool {
    return lhs.title == rhs.title && lhs.count == rhs.count
        && lhs.headImageAsset?.localIdentifier == rhs.headImageAsset?.localIdentifier
}
