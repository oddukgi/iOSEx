//
//  PhotoScrollView.swift
//  MultiplePictureUploader
//
//  Created by Sunmi on 2021/10/13.
//

import UIKit

class PhotoScrollView: UIScrollView, UIScrollViewDelegate {
    
    var photo: UIImage? {
        didSet {
            displayImage()
        }
    }
    
    var padding: CGFloat = 0
    weak var photoBrowserView: PhotoBrowserView?
 
    private let activityIndicatorView: UIActivityIndicatorView
    private let tapView: UIView
    private let photoImageView: UIImageView
    private var isPinchoutDetected = false
    
    
    func prepareForReuse() {
        photo = nil
    }
    
    required init?(coder aDecoder: NSCoder) {
         fatalError("init(coder:) has not been implemented")
    }
    
    init(photoBrowserView: PhotoBrowserView) {
        self.photoBrowserView = photoBrowserView
    
        activityIndicatorView = UIActivityIndicatorView()
        tapView = UIView(frame: CGRect.zero)
        photoImageView = UIImageView(frame: CGRect.zero)
        
        super.init(frame: CGRect.zero)
        
        activityIndicatorView.style = .gray
        activityIndicatorView.hidesWhenStopped = true
        addSubview(activityIndicatorView)
        
        tapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tapView.backgroundColor = UIColor.clear
        let tapViewSingleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap(gestureRecognizer:)))
//        let tapViewDoubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(gestureRecognizer:)))
//        tapViewDoubleTapRecognizer.numberOfTapsRequired = 2
//        tapViewSingleTapRecognizer.require(toFail: tapViewDoubleTapRecognizer)
        tapView.addGestureRecognizer(tapViewSingleTapRecognizer)
//        tapView.addGestureRecognizer(tapViewDoubleTapRecognizer)
        
        photoImageView.backgroundColor = UIColor.clear
        let imageViewSingleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap(gestureRecognizer:)))
//        let imageViewDoubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(gestureRecognizer:)))
//        imageViewDoubleTapRecognizer.numberOfTapsRequired = 2
//        imageViewSingleTapRecognizer.require(toFail: imageViewDoubleTapRecognizer)
        photoImageView.contentMode = .scaleAspectFit
        photoImageView.isUserInteractionEnabled = true
        photoImageView.addGestureRecognizer(imageViewSingleTapRecognizer)
//        photoImageView.addGestureRecognizer(imageViewDoubleTapRecognizer)
        addSubview(tapView)
        addSubview(photoImageView)
    
        
        backgroundColor = UIColor.clear
        delegate = self
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        decelerationRate = UIScrollView.DecelerationRate.fast
        autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
    
    
    func displayImage() {
        guard let photo = photo else {
            return
        }
        
        if  photo.size.width > 0, photo.size.height > 0 {
            minimumZoomScale = 1
            maximumZoomScale = 1
            zoomScale = 1
            
            photoImageView.image = photo
            photoImageView.isHidden = false
            
            photoImageView.frame = CGRect(x: 0, y: 0, width: photo.size.width, height: photo.size.height)
            contentSize = photoImageView.frame.size
            
            setMaxMinZoomScalesForCurrentBounds()
            
            
            let boundsSize = contentSize
           
            activityIndicatorView.stopAnimating()
        } else {
            photoImageView.isHidden = true
            activityIndicatorView.startAnimating()
        }
        setNeedsLayout()
    }
    
    private func setMaxMinZoomScalesForCurrentBounds() {
        if photoImageView.image == nil {
            return
        }
        
        var boundsSize = bounds.size
        boundsSize.width -= 0.1
        boundsSize.height -= 0.1
        
        let imageSize = photoImageView.frame.size
        
        let xScale = boundsSize.width / imageSize.width;    // the scale needed to perfectly fit the image width-wise
        let yScale = boundsSize.height / imageSize.height;  // the scale needed to perfectly fit the image height-wise
        let minScale = min(xScale, yScale);                 // use minimum of these to allow the image to become fully visible
        let maxScale = minScale * 2.5
        
        maximumZoomScale = maxScale;
        minimumZoomScale = minScale;
        zoomScale = minScale;
        
        let paddingX =  photoImageView.frame.size.width > padding * 4 ? padding : 0
        let paddingY =  photoImageView.frame.size.height > padding * 4 ? padding : 0
        
        photoImageView.frame = CGRect(x: 10, y: 10, width: photoImageView.frame.size.width, height: photoImageView.frame.size.height).insetBy(dx: paddingX, dy: paddingY)
        

        setNeedsLayout()
    }
    
    override func layoutSubviews() {
        tapView.frame = bounds
        
        super.layoutSubviews()
        
        let boundsSize = bounds.size
        var frameToCenter = photoImageView.frame
        
        if frameToCenter.size.width < boundsSize.width {
            frameToCenter.origin.x = floor((boundsSize.width - frameToCenter.size.width) / CGFloat(2))
        } else {
            frameToCenter.origin.x = 0;
        }
    
        if frameToCenter.size.height < boundsSize.height {
            frameToCenter.origin.y = floor((boundsSize.height - frameToCenter.size.height) / CGFloat(2));
        } else {
            frameToCenter.origin.y = 0;
        }
        
        photoImageView.frame = frameToCenter
        
        activityIndicatorView.center = CGPoint(x: bounds.midX, y: bounds.midY)
    }
    
    // MARK: UIScrollViewDelegate
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return photoImageView
    }
    
//    func scrollViewDidZoom(_ scrollView: UIScrollView) {
//        setNeedsLayout()
//        layoutIfNeeded()
//        if zoomScale < (minimumZoomScale - minimumZoomScale * 0.4) {
//            isPinchoutDetected = true
//        }
//    }
//
//    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
//        photoBrowserView?.scrollViewDidEndZooming(scrollView, with: view, atScale: scale)
//        if isPinchoutDetected {
//            isPinchoutDetected = false
//            photoBrowserView?.onPinchout()
//        }
//    }
    
    // MARK: Tap Detection
    
    @objc func handleSingleTap(gestureRecognizer: UITapGestureRecognizer) {
        photoBrowserView?.onTap()
    }

    
//    @objc func handleDoubleTap(gestureRecognizer: UITapGestureRecognizer) {
//        let touchPoint = gestureRecognizer.location(in: photoImageView)
//        if zoomScale == maximumZoomScale {
//            setZoomScale(minimumZoomScale, animated: true)
//        } else {
//            zoom(to: CGRect(x: touchPoint.x, y: touchPoint.y, width: 1, height: 1), animated: true)
//        }
//
//        photoBrowserView?.onZoomedWithDoubleTap()
//    }
    
    
    
    
    
}
    
//    var photo: UIImage? {
//        didSet {
//            displayImage()
//        }
//    }
//
//    var padding: CGFloat = 8
//    weak var photoBrowserView: PhotoBrowserView?
//    private let activityIndicatorView: UIActivityIndicatorView
//    private let tapView: UIView
//    private var isPinchoutDetected = false
//    private let maxCount = 3
//
//    private var photoView: PhotoView!
//
//    var photoSize: CGSize {
//        return photoView.imageView.frame.size
//    }
//
//    func prepareForReuse() {
//        photo = nil
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//         fatalError("init(coder:) has not been implemented")
//    }
//
//
//    init(photoBrowserView: PhotoBrowserView) {
//        self.photoBrowserView = photoBrowserView
//        activityIndicatorView = UIActivityIndicatorView()
//        tapView = UIView(frame: CGRect.zero)
//        photoView = PhotoView()
//        super.init(frame: CGRect.zero)
//
//
//        activityIndicatorView.style = .gray
//        activityIndicatorView.hidesWhenStopped = true
//        addSubview(activityIndicatorView)
//
//        tapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//        tapView.backgroundColor = UIColor.white
//        let tapViewSingleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap(gestureRecognizer:)))
//        tapView.addGestureRecognizer(tapViewSingleTapRecognizer)
//
//
//        let imageViewSingleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap(gestureRecognizer:)))
//////        let imageViewDoubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(gestureRecognizer:)))
////        imageViewDoubleTapRecognizer.numberOfTapsRequired = 2
////        imageViewSingleTapRecognizer.require(toFail: imageViewDoubleTapRecognizer)
////        photoImageView.contentMode = .scaleAspectFit
//        photoView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//        photoView.backgroundColor = .white
//        photoView.isUserInteractionEnabled = true
//        photoView.addGestureRecognizer(imageViewSingleTapRecognizer)
////        photoImageView.addGestureRecognizer(imageViewDoubleTapRecognizer)
//        addSubview(tapView)
//        addSubview(photoView)
////        photoView.translatesAutoresizingMaskIntoConstraints = false
////        NSLayoutConstraint.activate([
////
////            photoView.topAnchor.constraint(equalTo: self.topAnchor),
////            photoView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
////            photoView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
////            photoView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
////        ])
////
//
////        photoView.imageView.isUserInteractionEnabled = true
////        photoView.imageView.addGestureRecognizer(imageViewSingleTapRecognizer)
////
//        backgroundColor = UIColor.clear
//        delegate = self
//        showsVerticalScrollIndicator = false
//        showsHorizontalScrollIndicator = false
//        decelerationRate = UIScrollView.DecelerationRate.fast
//        autoresizingMask = [.flexibleHeight, .flexibleWidth]
//        deleteImage()
//    }
//
//
//
//    func displayImage() {
//        guard let photo = photo else {
//            return
//        }
//
//        if photo.size.width > 0, photo.size.height > 0 {
//            minimumZoomScale = 1
//            maximumZoomScale = 1
//            zoomScale = 1
////
//            photoView.imageView.image = photo
//            photoView.imageView.isHidden = false
//
//            photoView.imageView.frame = CGRect(x: 0, y: 0, width: photo.size.width, height: photo.size.height)
//            contentSize = photoView.frame.size
//
//            setMaxMinZoomScalesForCurrentBounds()
////            resizeImageView(imageView: photoView.imageView, image: photo)
//            activityIndicatorView.stopAnimating()
//
//        } else {
//            photoView.imageView.isHidden = true
//            activityIndicatorView.startAnimating()
//        }
//        setNeedsLayout()
//    }
//
//    private func setMaxMinZoomScalesForCurrentBounds() {
//        if photoView.imageView.image == nil {
//            return
//        }
//
//        var boundsSize = bounds.size
//        boundsSize.width -= 0.1
//        boundsSize.height -= 0.1
//
//        let imageSize = photoView.imageView.frame.size
//
//        let xScale = boundsSize.width / imageSize.width;    // the scale needed to perfectly fit the image width-wise
//        let yScale = boundsSize.height / imageSize.height;  // the scale needed to perfectly fit the image height-wise
//        let minScale = min(xScale, yScale);                 // use minimum of these to allow the image to become fully visible
//        let maxScale = minScale * 2.5
//
//        maximumZoomScale = maxScale;
//        minimumZoomScale = minScale;
////        zoomScale = minScale;
//
//        let paddingX =  imageSize.width > padding * 4 ? padding : 0
//        let paddingY =  imageSize.height > padding * 4 ? padding : 0
//
//
////        photoView.imageView.frame = CGRect(x: 0, y: 0, width: imageSize.width / 2, height: imageSize.height / 2).insetBy(dx: paddingX, dy: paddingY)
//
//        photoView.layoutIfNeeded()
//
//    }
//
//    func resizeImageView(imageView: UIImageView, image: UIImage) {
//        let size = CGSize(width: image.size.width, height: image.size.height)
//        var frame: CGRect = .zero
//
//        let viewW = self.bounds.width
//        let viewH = self.bounds.height
//
//        let width = viewW
//
//
//        frame.size.width = width
//
//        let imageHWRatio = size.height / size.width
//        let viewHWRatio = viewH / viewW
//
//        if imageHWRatio > viewHWRatio {
//            frame.size.height = floor(width * imageHWRatio)
//        } else {
//            var height = floor(width * imageHWRatio)
//            if height < 1 || height.isNaN {
//                height = viewH
//            }
//            frame.size.height = height
//        }
//
//
//        imageView.frame = frame
//
//        if UIApplication.shared.statusBarOrientation.isLandscape {
//            if frame.height < viewH {
//                imageView.center = CGPoint(x: viewW / 2, y: viewH / 2)
//            } else {
//                imageView.frame = CGRect(origin: CGPoint(x: (viewW-frame.width)/2, y: 0), size: frame.size)
//            }
//        } else {
//            if frame.width < viewW || frame.height < viewH {
//                imageView.center = CGPoint(x: viewW / 2, y: viewH / 2)
//            }
//        }
//    }
//
//    override func layoutSubviews() {
//        tapView.frame = bounds
//
//        super.layoutSubviews()
//
////        let boundsSize = bounds.size
////        var frameToCenter = tapView.frame
//
////        if frameToCenter.size.width < boundsSize.width {
////            frameToCenter.origin.x = floor((boundsSize.width - frameToCenter.size.width) / CGFloat(2))
////        } else {
////            frameToCenter.origin.x = 0;
////        }
////
////        if frameToCenter.size.height < boundsSize.height {
////            frameToCenter.origin.y = floor((boundsSize.height - frameToCenter.size.height) / CGFloat(2));
////        } else {
////            frameToCenter.origin.y = 0;
////        }
//
////        photoView.frame = frameToCenter
//
//
//        activityIndicatorView.center = CGPoint(x: bounds.midX, y: bounds.midY)
//    }
//
//    // MARK: UIScrollViewDelegate
//
//    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
//        return photoView.imageView
//    }
//
//    func deleteImage() {
//
//        photoView.deleteBlock = { [weak self] (image) in
//            guard let self = self,
//                  let image = image else { return }
//
//            self.photoBrowserView?.deleteImage(image: image)
//        }
//    }
//
////    func scrollViewDidZoom(_ scrollView: UIScrollView) {
////        setNeedsLayout()
////        layoutIfNeeded()
////        if zoomScale < (minimumZoomScale - minimumZoomScale * 0.4) {
////            isPinchoutDetected = true
////        }
////    }
////
////    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
////        photoBrowserView?.scrollViewDidEndZooming(scrollView, with: view, atScale: scale)
////        if isPinchoutDetected {
////            isPinchoutDetected = false
////            photoBrowserView?.onPinchout()
////        }
////    }
////
//    // MARK: Tap Detection
//
//    @objc func handleSingleTap(gestureRecognizer: UITapGestureRecognizer) {
//        photoBrowserView?.onTap()
//    }
//
////    @objc func handleDoubleTap(gestureRecognizer: UITapGestureRecognizer) {
////        let touchPoint = gestureRecognizer.location(in: photoImageView)
////        if zoomScale == maximumZoomScale {
////            setZoomScale(minimumZoomScale, animated: true)
////        } else {
////            zoom(to: CGRect(x: touchPoint.x, y: touchPoint.y, width: 1, height: 1), animated: true)
////        }
////
////        photoBrowserView?.onZoomedWithDoubleTap()
////    }
//
//
//
//}
//
