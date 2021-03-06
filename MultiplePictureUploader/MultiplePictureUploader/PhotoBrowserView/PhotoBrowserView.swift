//
//  PhotoBrowserView.swift
//  PhotoBrowser
//
//  Created by Sunmi on 2021/10/13.
//

import UIKit


public enum PhotoBrowserEvent {
    case pinchout // The user pinch-zoomed out beyond a certain treshold. Can be used as a close event.
    case tap
    case pinchZoom
    case doubleTapZoom
    case didSwipeToImage
}

public protocol PhotoBrowserDelegate: AnyObject {
    func photoBrowser(_ photoBrowser: PhotoBrowserView, firedEvent: PhotoBrowserEvent)
    func deleteImage(image: UIImage)
}

public class PhotoBrowserView: UIView, UIScrollViewDelegate {
    
    private let tagOffset = 1000
    private let pagingScrollView: UIScrollView
    private var visiblePages = Set<PhotoScrollView>()
    private var _currentPageIndex = 0
    private var isLastEventDoubleTapZoom = false
    private var _photos = [UIImage]()
    private var _passedPhotos = [UIImage]()
    
    public var margin: CGFloat = 0
    public var padding: CGFloat = 0
    
    public var deleteBtn: UIButton!

    var btnTrash: UIButton!
    public var photos: [UIImage] {
        set {
            _passedPhotos = newValue
            _photos = newValue 
            load()
        }
        get {
            return _passedPhotos
        }
    }
    
    public var currentPageIndex: Int {
        if numberOfPhotos() == 0 { return 0 }
        return _currentPageIndex % numberOfPhotos()
    }
    
    public func showImage(index: Int) {
        _currentPageIndex = index
        centerContentOffsetToMiddleSegment()
        didStartViewingPage(atIndex: index)
    }
    
    public weak var delegate: PhotoBrowserDelegate?
    
    public override init(frame: CGRect) {
        pagingScrollView = UIScrollView()
    
        super.init(frame: frame)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        pagingScrollView = UIScrollView()
        super.init(coder: aDecoder)
    }
    
    private func load() {
        backgroundColor = UIColor.white
        clipsToBounds = true
        
        pagingScrollView.isPagingEnabled = true
        pagingScrollView.delegate = self
        pagingScrollView.showsVerticalScrollIndicator = false
        pagingScrollView.showsHorizontalScrollIndicator = false
        pagingScrollView.backgroundColor = UIColor.clear
        addSubview(pagingScrollView)
        
        setNeedsLayout()
        layoutIfNeeded()
        
        centerContentOffsetToMiddleSegment()
        didStartViewingPage(atIndex: _currentPageIndex)
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        
        pagingScrollView.frame = bounds
        pagingScrollView.contentSize = contentSizeForPagingScrollView()
        
        for page in visiblePages {
            page.removeFromSuperview()
        }
        
        visiblePages.removeAll()
        
        pagingScrollView.contentOffset = contentOffsetForPage(atIndex: _currentPageIndex)
        createDeleteButton()
        createPages()
        
        let boundsSize = self.bounds.size
        deleteBtn.frame = CGRect(x: boundsSize.width - 25, y: 5, width: 25, height: 25)
    }
    
    
    
    private func createPages() {
        if numberOfPhotos() == 0 { return }
        
        let visibleBounds = pagingScrollView.bounds
        
        var firstIndex = Int(floor(visibleBounds.minX + margin * 2) / visibleBounds.width)
        var lastIndex = Int(floor(visibleBounds.maxX - margin * 2 - 1) / visibleBounds.width)
        
        firstIndex = max(0, min(numberOfPhotos() - 1, firstIndex))
        lastIndex = max(0, min(numberOfPhotos() - 1, lastIndex))

        var pageIndex = 0
        for page in visiblePages {
            pageIndex = page.tag - tagOffset
            if (pageIndex < firstIndex || pageIndex > lastIndex) {
                visiblePages.remove(page)
                page.prepareForReuse()
                page.removeFromSuperview()
            }
        }
        
        // Add missing pages
        (firstIndex...lastIndex).forEach { (index) in
            if !isDisplayingPageForIndex(index: index) {
                // Add new page
                
                let page = PhotoScrollView(photoBrowserView: self)
                page.backgroundColor = UIColor.clear
                page.isOpaque = true
                page.padding = padding
                
                configurePage(page, forIndex: index)
                visiblePages.insert(page)
                pagingScrollView.addSubview(page)
            }
        }
    }
    
    func createDeleteButton() {
        deleteBtn = UIButton(type: .custom)
        let deleteImg = UIImage(named: "Delete")
  
        deleteBtn.clipsToBounds = true
        deleteBtn.contentMode = .scaleAspectFill
        deleteBtn.setImage(deleteImg, for: .normal)
        deleteBtn.addTarget(self, action: #selector(deleteImage(_:)), for: .touchUpInside)
        deleteBtn.adjustsImageWhenHighlighted = false
        deleteBtn.enlargeValidTouchArea(insets: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
        addSubview(self.deleteBtn)

    }
    
    @objc func deleteImage(_ sender: UIButton) {
        let image = photos[currentPageIndex]
        self.deleteImage(image: image)
    }
    
    func onTap() {
        delegate?.photoBrowser(self, firedEvent: .tap)
    }
    
    func onZoomedWithDoubleTap() {
        delegate?.photoBrowser(self, firedEvent: .doubleTapZoom)
        isLastEventDoubleTapZoom = true
    }
    
    func onPinchout() {
        delegate?.photoBrowser(self, firedEvent: .pinchout)
    }
    
    func deleteImage(image: UIImage) {
        photos.remove(at: currentPageIndex)

        delegate?.deleteImage(image: image)
    }

    private func configurePage(_ page: PhotoScrollView, forIndex index: Int) {
        page.frame = frameForPage(atIndex: index)
        page.tag = tagOffset + index
        page.photo = _photos[index]
    }
    
    private func didStartViewingPage(atIndex index: Int) {
        if numberOfPhotos() == 0 { return }
        
        let photo = _photos[index]
        if photo.size.width > 0 &&
           photo.size.height > 0 {
            loadAndDisplay(photo: photo)
        } else {
            loadAdjacentPhotosIfNecessary(forPhoto: photo)
        }
        
        delegate?.photoBrowser(self, firedEvent: .didSwipeToImage)
    }
    
    private func loadAdjacentPhotosIfNecessary(forPhoto photo: UIImage) {
        guard let page = pageDisplayingPhoto(photo) else { return }
        
        let pIndex = pageIndex(page)
        if _currentPageIndex == pIndex {
            if pIndex > 0 {
                let photoAtIndex = _photos[pIndex - 1]
                loadAndDisplay(photo: photoAtIndex)

            }
            
            if pIndex < numberOfPhotos() - 1 {
                let photoAtIndex = _photos[pIndex+1]
                loadAndDisplay(photo: photoAtIndex)
            }
        }
    }
    
    private func loadAndDisplay(photo: UIImage) {
        if let page = self.pageDisplayingPhoto(photo) {
            page.photo = photo
            page.displayImage()
            self.loadAdjacentPhotosIfNecessary(forPhoto: photo)
        }
    }
    
    private func pageDisplayingPhoto(_ photo: UIImage) -> PhotoScrollView? {
        return visiblePages.filter {
            if let pagePhoto = $0.photo, pagePhoto == photo {
                return true
            }
            return false
        }.first
    }
    
    private func pageIndex(_ page: PhotoScrollView) -> Int {
        return page.tag - tagOffset
    }
    
    private func isDisplayingPageForIndex(index: Int) -> Bool {
        return visiblePages.map{ pageIndex($0) }.contains(index)
    }
    
    private func numberOfPhotos() -> Int {
        return _photos.count
    }
    
    private func realNumberOfPhotos() -> Int {
        return _photos.count / 3
    }
    
    private func frameForPage(atIndex index: Int) -> CGRect {
        let bounds = pagingScrollView.bounds
        var pageFrame = bounds
        pageFrame.size.width -= 2 * margin
        pageFrame.origin.x = (bounds.size.width * CGFloat(index)) + margin;
        return pageFrame
    }
    
    private func contentSizeForPagingScrollView() -> CGSize {
        let bounds = pagingScrollView.bounds
        return CGSize(width: bounds.size.width * CGFloat(numberOfPhotos()), height: bounds.size.height)
    }
    
    private func contentOffsetForPage(atIndex index: Int) -> CGPoint {
        let pageWidth = pagingScrollView.bounds.size.width
        let newOffset = CGFloat(index) * pageWidth
        return CGPoint(x: newOffset, y: 0)
    }
    
    private func centerContentOffsetToMiddleSegment() {
        if numberOfPhotos() == 0 { return }
        
        _currentPageIndex = _currentPageIndex % numberOfPhotos()
        let pageFrame = frameForPage(atIndex: _currentPageIndex)
        
        pagingScrollView.setContentOffset(CGPoint(x: pageFrame.origin.x - margin, y: 0), animated: false)
    }
    
    // MARK: UIScrollViewDelegate
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        createPages()
        
        let visibleBounds = pagingScrollView.bounds
        var index = Int(floor(visibleBounds.midX / visibleBounds.width))
        index = max(0, min(numberOfPhotos() - 1, index))
        
        let previousCurrentPageIndex = _currentPageIndex
        _currentPageIndex = index
        
        if _currentPageIndex != previousCurrentPageIndex {
            didStartViewingPage(atIndex: index)
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        centerContentOffsetToMiddleSegment()
    }
    
    public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        if isLastEventDoubleTapZoom {
            isLastEventDoubleTapZoom = false
        } else {
            delegate?.photoBrowser(self, firedEvent: .pinchZoom)
        }
    }
}
