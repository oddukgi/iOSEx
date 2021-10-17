//
//  ThumbnailViewController.swift
//  ZLPhotoBrowser
//
//  Created by long on 2020/8/19.
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

extension ThumbnailViewController {
    
    enum SlideSelectType {
        
        case none
        case select
        case cancel
    }
    
}

struct BottomLayout {
    static let bottomToolViewH: CGFloat = 45
    
    static let bottomToolBtnH: CGFloat = 34
    
    static let bottomToolBtnY: CGFloat = 10
    
    static let bottomToolTitleFont = UIFont.systemFont(ofSize: 17)
    
    static let bottomToolBtnCornerRadius: CGFloat = 5
    
}

class ThumbnailViewController: UIViewController {

    var albumList: AlbumListModel

    var embedNavView: EmbedAlbumListNavView?
    
    var embedAlbumListView: EmbedAlbumListView?
    
    var collectionView: UICollectionView!
    
    var bottomView: UIView!
    
    var bottomBlurView: UIVisualEffectView?
    
    var limitAuthTipsView: LimitedAuthorityTipsView?
        
    var originalBtn: UIButton!
    
    var doneBtn: UIButton!
    
    var arrDataSources: [PhotoModel] = []
    
    var showCameraCell: Bool {
        if  self.albumList.isCameraRoll {
            return true
        }
        return false
    }
    
    /// 所有滑动经过的indexPath
    lazy var arrSlideIndexPaths: [IndexPath] = []
    
    /// 所有滑动经过的indexPath的初始选择状态
    lazy var dicOriSelectStatus: [IndexPath: Bool] = [:]
    
    var isLayoutOK = false
    
    /// 设备旋转前第一个可视indexPath
    var firstVisibleIndexPathBeforeRotation: IndexPath?
    
    /// 是否触发了横竖屏切换
    var isSwitchOrientation = false
    
    /// 是否开始出发滑动选择
    var beginPanSelect = false
    
    /// 滑动选择 或 取消
    /// 当初始滑动的cell处于未选择状态，则开始选择，反之，则开始取消选择
    var panSelectType: ThumbnailViewController.SlideSelectType = .none
    
    /// 开始滑动的indexPath
    var beginSlideIndexPath: IndexPath?
    
    /// 最后滑动经过的index，开始的indexPath不计入
    /// 优化拖动手势计算，避免单个cell中冗余计算多次
    var lastSlideIndex: Int?
    
    /// 预览所选择图片，手势返回时候不调用scrollToIndex
    var isPreviewPush = false
    
    /// 拍照后置为true，需要刷新相册列表
    var hasTakeANewAsset = false
    
    var slideCalculateQueue = DispatchQueue(label: "com.ZLhotoBrowser.slide")
    
    var autoScrollTimer: CADisplayLink?
    
    var lastPanUpdateTime = CACurrentMediaTime()
    
    private var maxSelectCount = 3

    let autoScrollMaxSpeed: CGFloat = 600
    
    var showCaptureImageOnTakePhotoBtn = false
    
    let showLimitAuthTipsView: Bool = {
        if #available(iOS 14.0, *), PHPhotoLibrary.authorizationStatus(for: .readWrite) == .limited {
            return true
        } else {
            return false
        }
    }()
    
    private enum AutoScrollDirection {
        case none
        case top
        case bottom
    }
    
    private var autoScrollInfo: (direction: AutoScrollDirection, speed: CGFloat) = (.none, 0)
    
    @available(iOS 14, *)
    var showAddPhotoCell: Bool {
        PHPhotoLibrary.authorizationStatus(for: .readWrite) == .limited && self.albumList.isCameraRoll
    }
    
    /// 照相按钮+添加图片按钮的数量
    /// the count of addPhotoButton & cameraButton
    private var offset: Int {
        if #available(iOS 14, *) {
            
            return Int(self.showAddPhotoCell) + Int(self.showCameraCell)
        } else {
            return Int(self.showCameraCell)
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    var panGes: UIPanGestureRecognizer!
    
    deinit {
        debugPrint("ThumbnailViewController deinit")
        self.cleanTimer()
    }
    
    init(albumList: AlbumListModel, maxCount: Int) {
        self.albumList = albumList
        self.maxSelectCount = maxCount
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.setupUI()
        self.panGes = UIPanGestureRecognizer(target: self, action: #selector(slideSelectAction(_:)))
        self.panGes.delegate = self
        self.view.addGestureRecognizer(self.panGes)
        
        self.loadPhotos()
        
        // Register for the album change notification when the status is limited, because the photoLibraryDidChange method will be repeated multiple times each time the album changes, causing the interface to refresh multiple times. So the album changes are not monitored in other authority.
        if #available(iOS 14.0, *), PHPhotoLibrary.authorizationStatus(for: .readWrite) == .limited {
            PHPhotoLibrary.shared().register(self)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = true
        self.collectionView.reloadItems(at: self.collectionView.indexPathsForVisibleItems)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.isLayoutOK = true
        self.isPreviewPush = false
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let navViewNormalH: CGFloat = 44
        
        var insets = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        var collectionViewInsetTop: CGFloat = 20
        if #available(iOS 11.0, *) {
            insets = self.view.safeAreaInsets
            collectionViewInsetTop = navViewNormalH
        } else {
            collectionViewInsetTop += navViewNormalH
        }
        
        let navViewFrame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: insets.top + navViewNormalH)
        self.embedNavView?.frame = navViewFrame
        
        self.embedNavView?.addBorder(toSide: .bottom, withColor: UIColor.lightGray.cgColor, andThickness: 0.4)
        self.embedAlbumListView?.frame = CGRect(x: 0, y: navViewFrame.maxY, width: self.view.bounds.width, height: self.view.bounds.height-navViewFrame.maxY)
        
        var bottomViewH: CGFloat = 0
        // show bottom tips for Limit authority
        let showBottomToolBtns = true

        if self.showLimitAuthTipsView, showBottomToolBtns {
            bottomViewH = BottomLayout.bottomToolViewH + 30
        } else if self.showLimitAuthTipsView {
            bottomViewH = LimitedAuthorityTipsView.height
        } else if showBottomToolBtns {
            bottomViewH = BottomLayout.bottomToolViewH
        }
        
        let totalWidth = self.view.frame.width - insets.left - insets.right
        self.collectionView.frame = CGRect(x: insets.left, y: 0, width: totalWidth, height: self.view.frame.height)
        self.collectionView.contentInset = UIEdgeInsets(top: collectionViewInsetTop, left: 0, bottom: bottomViewH, right: 0)
        self.collectionView.scrollIndicatorInsets = UIEdgeInsets(top: insets.top, left: 0, bottom: bottomViewH, right: 0)
        
        if !self.isLayoutOK {
            self.scrollToTop()
        } else if self.isSwitchOrientation {
            self.isSwitchOrientation = false
            if let ip = self.firstVisibleIndexPathBeforeRotation {
                self.collectionView.scrollToItem(at: ip, at: .top, animated: false)
            }
        }

        guard showBottomToolBtns || self.showLimitAuthTipsView else { return }

        self.bottomView.frame = CGRect(x: 0, y: self.view.frame.height-insets.bottom - bottomViewH,
                                       width: self.view.bounds.width, height: bottomViewH + insets.bottom)
        self.bottomBlurView?.frame = self.bottomView.bounds
        
        if self.showLimitAuthTipsView {
            self.limitAuthTipsView?.frame = CGRect(x: 0, y: 0, width: self.bottomView.bounds.width, height: LimitedAuthorityTipsView.height)
        }
    }
    
    func setupUI() {
  
//        self.automaticallyAdjustsScrollViewInsets = true
        self.edgesForExtendedLayout = .all
        self.view.backgroundColor = .white
        
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 3, left: 0, bottom: 3, right: 0)
        
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        self.collectionView.backgroundColor = .white
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        self.collectionView.alwaysBounceVertical = true
        if #available(iOS 11.0, *) {
            self.collectionView.contentInsetAdjustmentBehavior = .always
        }
        self.view.addSubview(self.collectionView)

        collectionView.register(AddPhotoCell.self, forCellWithReuseIdentifier: "AddPhotoCell")
        collectionView.register(CameraCell.self, forCellWithReuseIdentifier: "CameraCell")
        collectionView.register(ThumbnailPhotoCell.self, forCellWithReuseIdentifier: "ThumbnailPhotoCell")

        self.bottomView = UIView()
        let toolViewBgColor = UIColor(red: 240/255, green: 241/255, blue: 244/255, alpha: 1.0) /* #f0f1f4 */
        self.bottomView.backgroundColor = toolViewBgColor
        self.view.addSubview(self.bottomView)
        
        let effect = UIBlurEffect(style: .light)
        self.bottomBlurView = UIVisualEffectView(effect: effect)
        self.bottomView.addSubview(self.bottomBlurView!)
        
        
        if self.showLimitAuthTipsView {
            self.limitAuthTipsView = LimitedAuthorityTipsView(frame: CGRect(x: 0, y: 0,
                                                                            width: self.view.bounds.width, height: LimitedAuthorityTipsView.height))
            self.bottomView.addSubview(self.limitAuthTipsView!)
        }
        
        func createBtn(_ title: String, _ action: Selector) -> UIButton {
            let btn = UIButton(type: .custom)
            btn.titleLabel?.font = UIFont.systemFont(ofSize: 17)
            btn.setTitle(title, for: .normal)
            btn.setTitleColor(UIColor.black, for: .normal)
            btn.setTitleColor(UIColor.darkGray, for: .disabled)
            btn.addTarget(self, action: action, for: .touchUpInside)
            return btn
        }
        
        self.setupNavView()
    }
    
    func setupNavView() {
        self.embedNavView = EmbedAlbumListNavView(title: self.albumList.title)
        
        self.embedNavView?.selectAlbumBlock = { [weak self] in
            if self?.embedAlbumListView?.isHidden == true {
                self?.embedAlbumListView?.show(reloadAlbumList: self?.hasTakeANewAsset ?? false)
                self?.hasTakeANewAsset = false
            } else {
                self?.embedAlbumListView?.hide()
            }
        }
        
        self.embedNavView?.cancelBlock = { [weak self] in
            let nav = self?.navigationController as? ImageNavController
            nav?.dismiss(animated: true, completion: {
                nav?.cancelBlock?()
            })
        }
        
        self.embedNavView?.doneBlock = { [weak self] in
            let nav = self?.navigationController as? ImageNavController
            self?.embedNavView?.arrSelectedModels = nav?.arrSelectedModels ?? []

            nav?.dismiss(animated: true, completion: {
                nav?.selectImageBlock?()
            })
            
        }

        self.view.addSubview(self.embedNavView!)
        
        self.embedAlbumListView = EmbedAlbumListView(selectedAlbum: self.albumList)
        self.embedAlbumListView?.isHidden = true
        
        self.embedAlbumListView?.selectAlbumBlock = { [weak self] (album) in
            guard self?.albumList != album else {
                return
            }
            self?.albumList = album
            self?.embedNavView?.title = album.title
            self?.loadPhotos()
            self?.embedNavView?.reset()
        }
        
        self.embedAlbumListView?.hideBlock = { [weak self] in
            self?.embedNavView?.reset()
        }
        
        self.view.addSubview(self.embedAlbumListView!)
    }
    
    func loadPhotos() {
        let nav = self.navigationController as! ImageNavController
        if self.albumList.models.isEmpty {
            let hud = ProgressHUD(style: .lightBlur)
            hud.show()
            DispatchQueue.global().async {
                self.albumList.refetchPhotos()
                DispatchQueue.main.async {
                    self.arrDataSources.removeAll()
                    self.arrDataSources.append(contentsOf: self.albumList.models)
                    self.markSelected(source: &self.arrDataSources, selected: &nav.arrSelectedModels)
                    hud.hide()
                    self.collectionView.reloadData()
                    self.scrollToTop()
                }
            }
        } else {
            self.arrDataSources.removeAll()
            self.arrDataSources.append(contentsOf: self.albumList.models)
            self.markSelected(source: &self.arrDataSources, selected: &nav.arrSelectedModels)
            self.collectionView.reloadData()
            self.scrollToTop()
        }
    }
    
    func markSelected(source: inout [PhotoModel], selected: inout [PhotoModel]) {
        guard selected.count > 0 else {
            return
        }
        
        var selIds: [String: Bool] = [:]
        var selIdAndIndex: [String: Int] = [:]
        
        for (index, m) in selected.enumerated() {
            selIds[m.ident] = true
            selIdAndIndex[m.ident] = index
        }
        
        source.forEach { (m) in
            if selIds[m.ident] == true {
                m.isSelected = true
                selected[selIdAndIndex[m.ident]!] = m
            } else {
                m.isSelected = false
            }
        }
    }
    
    // MARK: btn actions
    
    
    @objc func originalPhotoClick() {
        self.originalBtn.isSelected = !self.originalBtn.isSelected
        (self.navigationController as? ImageNavController)?.isSelectedOriginal = self.originalBtn.isSelected
    }
    
    @objc func doneBtnClick() {
        let nav = self.navigationController as? ImageNavController
        nav?.selectImageBlock?()
    }
    

    @objc func slideSelectAction(_ pan: UIPanGestureRecognizer) {
        
        let maxSelectedCount = 3
        
        let point = pan.location(in: self.collectionView)
        guard let indexPath = self.collectionView.indexPathForItem(at: point) else {
            return
        }
        let nav = self.navigationController as! ImageNavController
        
        let cell = self.collectionView.cellForItem(at: indexPath) as? ThumbnailPhotoCell
        let asc = false     // 내림차순 (descending)
        
        if pan.state == .began {
            self.beginPanSelect = (cell != nil)
            
            if self.beginPanSelect {
                let index = indexPath.row - self.offset
                
                let m = self.arrDataSources[index]
                self.panSelectType = m.isSelected ? .cancel : .select
                self.beginSlideIndexPath = indexPath
                
                if !m.isSelected, nav.arrSelectedModels.count < maxSelectedCount,
                   canAddModel(m, currentSelectCount: nav.arrSelectedModels.count) {
//                    if self.shouldDirectEdit(m) {
//                        self.panSelectType = .none
//                        return
//                    } else {
                        m.isSelected = true
                        nav.arrSelectedModels.append(m)
//                    }
                } else if m.isSelected {
                    m.isSelected = false
                    nav.arrSelectedModels.removeAll { $0 == m }
                }
                
                cell?.btnSelect.isSelected = m.isSelected
                self.refreshCellIndexAndMaskView()
                self.lastSlideIndex = indexPath.row
            }
        } else if pan.state == .changed {
            self.autoScrollWhenSlideSelect(pan)
            
            if !self.beginPanSelect || indexPath.row == self.lastSlideIndex || self.panSelectType == .none || cell == nil {
                return
            }
            guard let beginIndexPath = self.beginSlideIndexPath else {
                return
            }
            self.lastPanUpdateTime = CACurrentMediaTime()
            
            let visiblePaths = self.collectionView.indexPathsForVisibleItems
            self.slideCalculateQueue.async {
                self.lastSlideIndex = indexPath.row
                let minIndex = min(indexPath.row, beginIndexPath.row)
                let maxIndex = max(indexPath.row, beginIndexPath.row)
                let minIsBegin = minIndex == beginIndexPath.row
                
                var i = beginIndexPath.row
                while (minIsBegin ? i <= maxIndex : i >= minIndex) {
                    if i != beginIndexPath.row {
                        let p = IndexPath(row: i, section: 0)
                        if !self.arrSlideIndexPaths.contains(p) {
                            self.arrSlideIndexPaths.append(p)
                            let index = asc ? i : i - self.offset
                            let m = self.arrDataSources[index]
                            self.dicOriSelectStatus[p] = m.isSelected
                        }
                    }
                    i += (minIsBegin ? 1 : -1)
                }
                
                var selectedArrHasChange = false
                
                for path in self.arrSlideIndexPaths {
                    if !visiblePaths.contains(path) {
                        continue
                    }
                    let index = asc ? path.row : path.row - self.offset
                    // 是否在最初和现在的间隔区间内
                    let inSection = path.row >= minIndex && path.row <= maxIndex
                    let m = self.arrDataSources[index]
                    
                    if self.panSelectType == .select {
                        if inSection,
                           !m.isSelected,
                           self.canAddModel(m, currentSelectCount: nav.arrSelectedModels.count, showAlert: false) {
                            m.isSelected = true
                        }
                    } else if self.panSelectType == .cancel {
                        if inSection {
                            m.isSelected = false
                        }
                    }
                    
                    if !inSection {
                        // 未在区间内的model还原为初始选择状态
                        m.isSelected = self.dicOriSelectStatus[path] ?? false
                    }
                    if !m.isSelected {
                        if let index = nav.arrSelectedModels.firstIndex(where: { $0 == m }) {
                            nav.arrSelectedModels.remove(at: index)
                            self.embedNavView?.arrSelectedModels.remove(at: index)
                            selectedArrHasChange = true
                        }
                    } else {
                        if !nav.arrSelectedModels.contains(where: { $0 == m }) {
                            nav.arrSelectedModels.append(m)
                            self.embedNavView?.arrSelectedModels.append(m)
                            selectedArrHasChange = true
                        }
                    }
                    
                    DispatchQueue.main.async {
                        let c = self.collectionView.cellForItem(at: path) as? ThumbnailPhotoCell
                        c?.btnSelect.isSelected = m.isSelected
                    }
                }
                
                if selectedArrHasChange {
                    DispatchQueue.main.async {
                        self.refreshCellIndexAndMaskView()
                    }
                }
            }
        } else if pan.state == .ended || pan.state == .cancelled {
            self.cleanTimer()
            self.panSelectType = .none
            self.arrSlideIndexPaths.removeAll()
            self.dicOriSelectStatus.removeAll()
        }
    }
    
    func autoScrollWhenSlideSelect(_ pan: UIPanGestureRecognizer) {
//        guard ZLPhotoConfiguration.default().autoScrollWhenSlideSelectIsActive else {
//            return
//        }
        
        
        let arrSel = (self.navigationController as? ImageNavController)?.arrSelectedModels ?? []
        guard arrSel.count < maxSelectCount else {
            // Stop auto scroll when reach the max select count.
            self.cleanTimer()
            return
        }
        
        let top = (self.embedNavView?.frame.height ?? 44) + 30

        let point = pan.location(in: self.view)
        
        var diff: CGFloat = 0
        var direction: AutoScrollDirection = .none
        if point.y < top {
            diff = top - point.y
            direction = .top
        } else if point.y > 0 {
            diff = point.y
            direction = .bottom
        } else {
            self.autoScrollInfo = (.none, 0)
            self.cleanTimer()
            return
        }
        
        guard diff > 0 else { return }
        
        let s = min(diff, 60) / 60 * autoScrollMaxSpeed
        
        self.autoScrollInfo = (direction, s)
        
        if self.autoScrollTimer == nil {
            self.cleanTimer()
            self.autoScrollTimer = CADisplayLink(target: ZLWeakProxy(target: self), selector: #selector(autoScrollAction))
            self.autoScrollTimer?.add(to: RunLoop.current, forMode: .common)
        }
    }
    
    func cleanTimer() {
        self.autoScrollTimer?.remove(from: RunLoop.current, forMode: .common)
        self.autoScrollTimer?.invalidate()
        self.autoScrollTimer = nil
    }
    
    @objc func autoScrollAction() {
        guard self.autoScrollInfo.direction != .none else { return }
        let duration = CGFloat(self.autoScrollTimer?.duration ?? 1 / 60)
        if CACurrentMediaTime() - self.lastPanUpdateTime > 0.2 {
            // Finger may be not moved in slide selection mode
            self.slideSelectAction(self.panGes)
        }
        let distance = self.autoScrollInfo.speed * duration
        let offset = self.collectionView.contentOffset
        let inset = self.collectionView.contentInset
        if self.autoScrollInfo.direction == .top, offset.y + inset.top > distance {
            self.collectionView.contentOffset = CGPoint(x: 0, y: offset.y - distance)
        } else if self.autoScrollInfo.direction == .bottom, offset.y + self.collectionView.bounds.height + distance - inset.bottom < self.collectionView.contentSize.height {
            self.collectionView.contentOffset = CGPoint(x: 0, y: offset.y + distance)
        }
    }

    func scrollToTop() {
        guard self.arrDataSources.count > 0 else {
            return
        }
//        let index = self.arrDataSources.count - 1 + self.offset
        self.collectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
    }
    
    func showCamera() {
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let picker = UIImagePickerController()
            picker.delegate = self
            picker.allowsEditing = false
            picker.videoQuality = .typeHigh
            picker.sourceType = .camera
            picker.cameraFlashMode = .off
            picker.mediaTypes = ["public.image"]
            self.showDetailViewController(picker, sender: nil)
        }
        
    }
    
    func save(image: UIImage?, videoUrl: URL?) {
        let hud = ProgressHUD(style: .lightBlur)
        if let image = image {
            hud.show()
            PhotoManager.saveImageToAlbum(image: image) { [weak self] (suc, asset) in
                if suc, let at = asset {
                    let model = PhotoModel(asset: at)
                    self?.handleDataArray(newModel: model)
                } else {
                    
                    let errorMsg = localLanguageTextValue(.saveImageError)
                    debugPrint(errorMsg)
                }
                hud.hide()
            }
        }
    }
    
    func handleDataArray(newModel: PhotoModel) {
        self.hasTakeANewAsset = true
        self.albumList.refreshResult()
        
        let nav = self.navigationController as? ImageNavController
        var insertIndex = 0
        
//        if config.sortAscending {
//            insertIndex = self.arrDataSources.count
//            self.arrDataSources.append(newModel)
//        } else {}
            // Save photos or videos taken and explain
            // that there must be a camera cell.
            insertIndex = self.offset
            self.arrDataSources.insert(newModel, at: 0)
 
        let canSelect = true

        if canSelect, canAddModel(newModel, currentSelectCount: nav?.arrSelectedModels.count ?? 0, showAlert: false) {
//            if !self.shouldDirectEdit(newModel) {
                newModel.isSelected = true
                nav?.arrSelectedModels.append(newModel)
                embedNavView?.arrSelectedModels.append(newModel)
//            }
        }
        
        let insertIndexPath = IndexPath(row: insertIndex, section: 0)
        self.collectionView.performBatchUpdates({
            self.collectionView.insertItems(at: [insertIndexPath])
        }) { (_) in
            self.collectionView.scrollToItem(at: insertIndexPath, at: .centeredVertically, animated: true)
            self.collectionView.reloadItems(at: self.collectionView.indexPathsForVisibleItems)
        }
            }
 
    
}


// MARK: Gesture delegate

extension ThumbnailViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {

        return true
    }
    
}


// MARK: CollectionView Delegate & DataSource

extension ThumbnailViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        let columnCount = 3
  
        let totalW = collectionView.bounds.width - CGFloat((columnCount - 1) * 2)
        let singleW = totalW / CGFloat(columnCount)
        return CGSize(width: singleW, height: singleW)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.arrDataSources.count + self.offset
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
   
        if self.showCameraCell
            &&  (indexPath.row == 0) {
            // camera cell
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CameraCell", for: indexPath) as! CameraCell
            if showCaptureImageOnTakePhotoBtn {
                cell.startCapture()
            }
            return cell
        }
        

        
        if #available(iOS 14, *) {
            if self.showAddPhotoCell && (indexPath.row == self.offset - 1) {
                return collectionView.dequeueReusableCell(withReuseIdentifier: "AddPhotoCell", for: indexPath)
            }
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ThumbnailPhotoCell",
                                                      for: indexPath) as! ThumbnailPhotoCell
        
        let model: PhotoModel
        model = self.arrDataSources[indexPath.row - self.offset]
        
        let nav = self.navigationController as? ImageNavController
        cell.selectedBlock = { [weak self, weak nav, weak cell] (isSelected) in
            
            guard let `self` = self,
                  let nav = nav,
                  let cell = cell else { return }
            if !isSelected {
                let currentSelectCount = nav.arrSelectedModels.count
                guard self.canAddModel(model, currentSelectCount: currentSelectCount) else {
                    return
                }
//                if self.shouldDirectEdit(model) == false {
                    model.isSelected = true
                    nav.arrSelectedModels.append(model)
                self.embedNavView?.arrSelectedModels.append(model)
                    cell.btnSelect.isSelected = true
                    self.refreshCellIndexAndMaskView()
//                }
            } else {
                cell.btnSelect.isSelected = false
                model.isSelected = false
                nav.arrSelectedModels.removeAll { $0 == model }
                self.embedNavView?.arrSelectedModels.removeAll { $0 == model }
                self.refreshCellIndexAndMaskView()
            }
        }
        
        cell.indexLabel.isHidden = true
        for (index, selM) in (nav?.arrSelectedModels ?? []).enumerated() {
            if model == selM {
                self.setCellIndex(cell, showIndexLabel: true, index: index + 1)
                break
            }
        }
        
        
        self.setCellMaskView(cell, isSelected: model.isSelected, model: model)
        cell.model = model
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let c = cell as? ThumbnailPhotoCell else {
            return
        }
        var index = indexPath.row
        index -= self.offset
        let model = self.arrDataSources[index]
        self.setCellMaskView(c, isSelected: model.isSelected, model: model)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let c = collectionView.cellForItem(at: indexPath)
        if c is CameraCell {
            self.showCamera()
            return
        }
        
        
        if #available(iOS 14, *) {
            if c is AddPhotoCell {
                PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: self)
                return
            }
        }

        guard let cell = c as? ThumbnailPhotoCell else {
            return
        }
        

        if !cell.enableSelect {
            return
        }
 
        var index = indexPath.row
        index -= self.offset
        
//        let m = self.arrDataSources[index]
//        if self.shouldDirectEdit(m) {
//            return
//        }
//
//        let vc = ZLPhotoPreviewController(photos: self.arrDataSources, index: index)
//        self.show(vc, sender: nil)
    }
//
//    func shouldDirectEdit(_ model: PhotoModel) -> Bool {
//        let config = ZLPhotoConfiguration.default()
//
//        let canEditImage = config.editAfterSelectThumbnailImage &&
//            config.allowEditImage &&
//            config.maxSelectCount == 1 &&
//            model.type.rawValue < ZLPhotoModel.MediaType.video.rawValue
//
//        let canEditVideo = (config.editAfterSelectThumbnailImage &&
//            config.allowEditVideo &&
//            model.type == .video &&
//            config.maxSelectCount == 1) ||
//            (config.allowEditVideo &&
//            model.type == .video &&
//            !config.allowMixSelect &&
//            config.cropVideoAfterSelectThumbnail)
//
//        //当前未选择图片 或已经选择了一张并且点击的是已选择的图片
//        let nav = self.navigationController as? ZLImageNavController
//        let arrSelectedModels = nav?.arrSelectedModels ?? []
//        let flag = arrSelectedModels.isEmpty || (arrSelectedModels.count == 1 && arrSelectedModels.first?.ident == model.ident)
//
//        if canEditImage, flag {
//            self.showEditImageVC(model: model)
//        } else if canEditVideo, flag {
//            self.showEditVideoVC(model: model)
//        }
//
//        return flag && (canEditImage || canEditVideo)
//    }
    
    func setCellIndex(_ cell: ThumbnailPhotoCell?, showIndexLabel: Bool, index: Int) {

        cell?.index = index
        cell?.indexLabel.isHidden = !showIndexLabel
    }
    
    func refreshCellIndexAndMaskView() {

        let sortAscending = false
        let visibleIndexPaths = self.collectionView.indexPathsForVisibleItems
        
        visibleIndexPaths.forEach { (indexPath) in
            guard let cell = self.collectionView.cellForItem(at: indexPath) as? ThumbnailPhotoCell else {
                return
            }
            var row = indexPath.row
            
            // 오름차순 (descending)
            if !sortAscending {
                row -= self.offset
            }
            let m = self.arrDataSources[row]
            
            let arrSel = (self.navigationController as? ImageNavController)?.arrSelectedModels ?? []
            var show = false
            var idx = 0
            var isSelected = false
            for (index, selM) in arrSel.enumerated() {
                if m == selM {
                    show = true
                    idx = index + 1
                    isSelected = true
                    break
                }
            }
             self.setCellIndex(cell, showIndexLabel: show, index: idx)
             self.setCellMaskView(cell, isSelected: isSelected, model: m)
        }
    }
    
    func setCellMaskView(_ cell: ThumbnailPhotoCell, isSelected: Bool, model: PhotoModel) {

        cell.coverView.isHidden = true
        cell.enableSelect = true


        let arrSel = (self.navigationController as? ImageNavController)?.arrSelectedModels ?? []

        if isSelected {
            cell.coverView.backgroundColor = .clear
            cell.coverView.isHidden = false
            cell.showBorderColor(true)
        } else {
            let selCount = arrSel.count
            if selCount < maxSelectCount {
                if selCount > 0 {
                    cell.coverView.backgroundColor = .clear
                    cell.coverView.isHidden = false
                    cell.enableSelect = true
                }
            } else if selCount >= maxSelectCount {
                cell.coverView.backgroundColor = .clear
                cell.coverView.isHidden = false
                cell.enableSelect = false
            }
            cell.showBorderColor(false)
        }
    }

}


extension ThumbnailViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true) {
            let image = info[.originalImage] as? UIImage
            let url = info[.mediaURL] as? URL
            self.save(image: image, videoUrl: url)
        }
    }
    
}


extension ThumbnailViewController: PHPhotoLibraryChangeObserver {
    
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        guard let changes = changeInstance.changeDetails(for: self.albumList.result)
            else { return }
        DispatchQueue.main.sync {
            // 变化后再次显示相册列表需要刷新
            self.hasTakeANewAsset = true
            self.albumList.result = changes.fetchResultAfterChanges
            let nav = (self.navigationController as! ImageNavController)
            if changes.hasIncrementalChanges {
                for sm in nav.arrSelectedModels {
                    let isDelete = changeInstance.changeDetails(for: sm.asset)?.objectWasDeleted ?? false
                    if isDelete {
                        nav.arrSelectedModels.removeAll { $0 == sm }
                    }
                }
                if (!changes.removedObjects.isEmpty || !changes.insertedObjects.isEmpty) {
                    self.albumList.models.removeAll()
                }
                
                self.loadPhotos()
            } else {
                for sm in nav.arrSelectedModels {
                    let isDelete = changeInstance.changeDetails(for: sm.asset)?.objectWasDeleted ?? false
                    if isDelete {
                        nav.arrSelectedModels.removeAll { $0 == sm }
                    }
                }
                self.albumList.models.removeAll()
                self.loadPhotos()
            }
        }
    }
    
}


extension ThumbnailViewController {
    
    func canAddModel(_ model: PhotoModel, currentSelectCount: Int, showAlert: Bool = true) -> Bool {

        if currentSelectCount >= maxSelectCount {
            if showAlert {
                let message = String(format: localLanguageTextValue(.exceededMaxSelectCount), maxSelectCount)
                debugPrint(message)
            }
            return false
        }

        return true
    }
}

