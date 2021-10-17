//
//  MultiplePhotosViewController.swift
//  MultiplePictureUploader
//
//  Created by Sunmi on 2021/10/14.
//

import UIKit
import Photos

@objc public enum NoAuthorityType: Int {
    case library
    case camera
    case microphone
}

class MultiplePhotosViewController: UIViewController {

    @IBOutlet weak var photoNumberView: UIView!
    @IBOutlet weak var photoNumberLabel: UILabel!
    @IBOutlet weak var frameStackView: UIStackView!
    @IBOutlet weak var photoUploadButton: UIButton!
    @IBOutlet weak var labelHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var dashFrameView: DashFrameView!

    @IBOutlet weak var placeholderImageView: UIImageView!
    var photoBrowserView: PhotoBrowserView!
    /// preview
    var arrDataSources = [PhotoModel]()
    /// selection
    private var arrSelectedModels = [PhotoModel]()
    private var fetchImageQueue: OperationQueue = OperationQueue()
    
    
    /// Success callback
    /// block params
    ///  - params1: images for asset.
    ///  - params2: selected assets
    ///  - params3: is full image
    var selectImageBlock: ( ([UIImage], [PHAsset], Bool) -> Void )?
    
    /// Callback for photos that failed to parse
    /// block params
    ///  - params1: failed assets.
    ///  - params2: index for asset
    private var selectImageRequestErrorBlock: ( ([PHAsset], [Int]) -> Void )?
    private var cancelBlock: ( () -> Void )?
    var noAuthorityCallback: ( (NoAuthorityType) -> Void )?
    private var labelHeight: CGFloat = 0.0
    private var placeholderH: CGFloat = 0.0

    var selectedImages: [UIImage] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
      
        self.view.backgroundColor = .white
        labelHeight = photoNumberLabel.frame.height
        labelHeightConstraint.constant = 0
        showSelectImage()
        
        noAuthorityCallback = { (type) in
            switch type {
            case .library:
                debugPrint("No library authority")
            case .camera:
                debugPrint("No camera authority")
            case .microphone:
                debugPrint("No microphone authority")
            }
        }
    }
    
    @IBAction func uploadPhoto() {
        
        let status = PHPhotoLibrary.authorizationStatus()
        if status == .restricted || status == .denied {
            self.showNoAuthorityAlert()
        } else if status == .notDetermined {
            PHPhotoLibrary.requestAuthorization { (status) in
                DispatchQueue.main.async {
                    if status == .denied {
                        self.showNoAuthorityAlert()
                    } else if status == .authorized {
                        self.showThumbnailViewController()
                    }
                }
            }

        } else {
            showThumbnailViewController()
        }
    }
    
    
    func showNoAuthorityAlert() {
        let alert = UIAlertController(title: nil, message: String(format: localLanguageTextValue(.noPhotoLibratyAuthority),
                                                                  getAppName()), preferredStyle: .alert)
        let action = UIAlertAction(title: localLanguageTextValue(.ok), style: .default) { (_) in
            self.noAuthorityCallback?(.library)
        }
        alert.addAction(action)
        self.showDetailViewController(alert, sender: nil)
    }
    
    
    func showSelectImage() {
        selectImageBlock = { (images, asset, _) in
            // hide
            DispatchQueue.main.async { [weak self] in
                
                guard let `self` = self else { return }
                
                self.placeholderImageView.isHidden = true
                self.labelHeightConstraint.constant = self.labelHeight
                self.showPhotoBrowserView()
  
                for item in images {
                    self.selectedImages.append(item)
                }
                self.photoBrowserView.photos = self.selectedImages
                
                debugPrint("Frame Stack View: \(self.frameStackView.frame)")
                debugPrint("Dash View: \(self.dashFrameView.frame)")
               
            }
        }
    }
    
    
    func showPhotoBrowserView() {
     
        photoBrowserView = PhotoBrowserView()
        photoBrowserView.delegate = self
        frameStackView.addSubview(photoBrowserView)
        
        photoBrowserView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            photoBrowserView.topAnchor.constraint(equalTo: frameStackView.topAnchor),
            photoBrowserView.leadingAnchor.constraint(equalTo: frameStackView.leadingAnchor),
            photoBrowserView.trailingAnchor.constraint(equalTo: frameStackView.trailingAnchor),
            photoBrowserView.bottomAnchor.constraint(equalTo: frameStackView.bottomAnchor)
        ])
        print(frameStackView.frame)
       
    }
    
    
    func getAppName() -> String {
        if let name = Bundle.main.localizedInfoDictionary?["CFBundleDisplayName"] as? String {
            return name
        }
        if let name = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String {
            return name
        }
        if let name = Bundle.main.infoDictionary?["CFBundleName"] as? String {
            return name
        }
        return "App"
    }
}



extension MultiplePhotosViewController: PhotoBrowserDelegate {
 
    func deleteImage(image: UIImage) {
        if let index = selectedImages.firstIndex(of: image) {
            selectedImages.remove(at: Int(index))
       
            if selectedImages.count == 0 {

                labelHeightConstraint.constant = 0
                photoBrowserView.removeFromSuperview()
                photoBrowserView = nil
                placeholderImageView.isHidden = false
     
            } else {
                updateCounterLabel(photoBrowser: photoBrowserView)
            }
            
        }
    }
   
    func photoBrowser(_ photoBrowser: PhotoBrowserView, firedEvent: PhotoBrowserEvent) {
        switch firedEvent {
               case .didSwipeToImage:
                print("EVENT: didSwipeToImage")
                updateCounterLabel(photoBrowser: photoBrowser)
       //        case .doubleTapZoom: print("EVENT: double tap zoom")
       //        case .pinchout: print("EVENT: pinchout")
       //        case .pinchZoom: print("EVENT: pinchzoom")
               case .tap:
                print("EVENT: tap")
//                let total = photoBrowser.photos.count
//                for i in 0..<total {
//                    photoBrowser.showImage(index: i)
//                }
               default: break
       //            photoBrowser.showImage(index: 2)
        }
    }

    private func updateCounterLabel(photoBrowser: PhotoBrowserView) {
        let total = photoBrowser.photos.count
        let text = "\(photoBrowser.currentPageIndex + 1)/\(total)"
        photoNumberLabel.text = text
        photoNumberLabel.textColor = .black
    }
}

extension MultiplePhotosViewController {
    
    func showThumbnailViewController() {
        
        let imageCount = selectedImages.count
        let maxImgCount = 3 - imageCount
        
        if maxImgCount == 0 { return }
        PhotoManager.getCameraRollAlbum(allowSelectImage: true,
                                        allowSelectVideo: false) { [weak self] (cameraRoll) in
            guard let `self` = self else { return }
            
            let tvc = ThumbnailViewController(albumList: cameraRoll, maxCount: maxImgCount)
            let nav = self.getImageNav(rootViewController: tvc)
            self.showDetailViewController(nav, sender: nil)
        }
    }
    
    func getImageNav(rootViewController: UIViewController) -> ImageNavController {
        let nav = ImageNavController(rootViewController: rootViewController)
        nav.modalPresentationStyle = .fullScreen
        nav.selectImageBlock = { [weak self, weak nav] in
            
            self?.arrSelectedModels.removeAll()
            self?.arrSelectedModels.append(contentsOf: nav?.arrSelectedModels ?? [])
            self?.requestSelectPhoto(viewController: nav)
        }
        
        nav.cancelBlock = { [weak self] in
//            self?.hide {
                self?.cancelBlock?()
//            }
        }
        nav.arrSelectedModels.removeAll()
        nav.arrSelectedModels.append(contentsOf: self.arrDataSources)
        return nav
    }
    
    func requestSelectPhoto(viewController: UIViewController? = nil) {
        guard !self.arrSelectedModels.isEmpty else {
            self.selectImageBlock?([], [], false)
            viewController?.dismiss(animated: true, completion: nil)
            return
        }
        
        let hud = ProgressHUD(style: .lightBlur)
        
        var timeout = false
        hud.timeoutBlock = { [weak self] in
            timeout = true
            debugPrint(localLanguageTextValue(.timeout))
            self?.fetchImageQueue.cancelAllOperations()
        }
        
        hud.show(timeout: 20)
        
        let callback = { [weak self] (sucImages: [UIImage], sucAssets: [PHAsset],
                                      errorAssets: [PHAsset], errorIndexs: [Int]) in
            hud.hide()
            
            func call() {
 
                if !errorAssets.isEmpty {
                    self?.selectImageRequestErrorBlock?(errorAssets, errorIndexs)
                } else {
                    self?.selectImageBlock?(sucImages, sucAssets, false)
                }
            }
            
            if let vc = viewController {

                vc.dismiss(animated: true) {
                    call()
                }
            }
            
            self?.arrSelectedModels.removeAll()
            self?.arrDataSources.removeAll()
        }
        
        var images: [UIImage?] = Array(repeating: nil, count: self.arrSelectedModels.count)
        var assets: [PHAsset?] = Array(repeating: nil, count: self.arrSelectedModels.count)
        
        var errorAssets: [PHAsset] = []
        var errorIndexs: [Int] = []
        
        var sucCount = 0
        let totalCount = self.arrSelectedModels.count
        self.arrDataSources = self.arrSelectedModels
        
        for (i, m) in self.arrSelectedModels.enumerated() {
            let operation = FetchImageOperation(model: m, isOriginal: false) { (image, asset) in
                guard !timeout else { return }
                
                sucCount += 1
                
                if let image = image {
                    images[i] = image
                    assets[i] = asset ?? m.asset

                    debugPrint("ZLPhotoBrowser: suc request \(i)")
                } else {
                    errorAssets.append(m.asset)
                    errorIndexs.append(i)
                    debugPrint("ZLPhotoBrowser: failed request \(i)")
                }
                
                guard sucCount >= totalCount else { return }
                
                callback(
                    images.compactMap { $0 },
                    assets.compactMap { $0 },
                    errorAssets,
                    errorIndexs
                )
            }
            self.fetchImageQueue.addOperation(operation)
        }
    }

}
