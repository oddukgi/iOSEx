//
//  EmbedAlbumListView.swift
//  MultiplePictureUploader
//
//  Created by Sunmi on 2021/10/12.
//  refer to : https://github.com/longitachi/ZLPhotoBrowser
//

import UIKit
import Photos

class EmbedAlbumListView: UIView {

    static let rowH: CGFloat = 60
    
    var selectedAlbum: AlbumListModel
    
    var tableBgView: UIView!
    
    var tableView: UITableView!
    
    var arrDataSource: [AlbumListModel] = []
    
    var selectAlbumBlock: ( (AlbumListModel) -> Void )?
    
    var hideBlock: ( () -> Void )?

    init(selectedAlbum: AlbumListModel) {
        self.selectedAlbum = selectedAlbum
        super.init(frame: .zero)
        self.setupUI()
        self.loadAlbumList()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
      
        
        guard !self.isHidden else {
            return
        }
        
        let bgFrame = self.calculateBgViewBounds()
        
        let path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: self.frame.width, height: bgFrame.height), byRoundingCorners: [.bottomLeft, .bottomRight], cornerRadii: CGSize(width: 8, height: 8))
        self.tableBgView.layer.mask = nil
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        self.tableBgView.layer.mask = maskLayer
        
        self.tableBgView.frame = bgFrame
        self.tableView.frame = self.tableBgView.bounds
    }
    
    func setupUI() {
        self.clipsToBounds = true
        
        self.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        
        self.tableBgView = UIView()
        self.addSubview(self.tableBgView)
        
        self.tableView = UITableView(frame: .zero, style: .plain)
        self.tableView.backgroundColor = .white
        self.tableView.tableFooterView = UIView()
        self.tableView.rowHeight = 60
        self.tableView.separatorInset = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 0)
        self.tableView.separatorColor = .darkGray
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableBgView.addSubview(self.tableView)
        
        tableView.register(AlbumListCell.self, forCellReuseIdentifier: "AlbumListCell")
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapAction(_:)))
        tap.delegate = self
        self.addGestureRecognizer(tap)
    }
    
    func loadAlbumList(completion: ( () -> Void )? = nil) {
        DispatchQueue.global().async {
            PhotoManager.getPhotoAlbumList(ascending: false,
                                           allowSelectImage: true, allowSelectVideo: false) { [weak self] (albumList) in
                self?.arrDataSource.removeAll()
                self?.arrDataSource.append(contentsOf: albumList)
                
                DispatchQueue.main.async {
                    completion?()
                    self?.tableView.reloadData()
                }
            }
        }
    }
    
    func calculateBgViewBounds() -> CGRect {
        let contentH = CGFloat(self.arrDataSource.count) * EmbedAlbumListView.rowH
        let maxH = min(self.frame.height * 0.7, contentH)
        return CGRect(x: 0, y: 0, width: self.frame.width, height: maxH)
    }
    
    /// 这里不采用监听相册发生变化的方式，是因为每次变化，系统都会回调多次，造成重复获取相册列表
    func show(reloadAlbumList: Bool) {
        func animateShow() {
            let toFrame = self.calculateBgViewBounds()
            
            self.isHidden = false
            self.alpha = 0
            var newFrame = toFrame
            newFrame.origin.y -= newFrame.height
            
            if newFrame != self.tableBgView.frame {
                let path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: newFrame.width, height: newFrame.height), byRoundingCorners: [.bottomLeft, .bottomRight], cornerRadii: CGSize(width: 8, height: 8))
                self.tableBgView.layer.mask = nil
                let maskLayer = CAShapeLayer()
                maskLayer.path = path.cgPath
                self.tableBgView.layer.mask = maskLayer
            }
            
            self.tableBgView.frame = newFrame
            self.tableView.frame = self.tableBgView.bounds
            UIView.animate(withDuration: 0.25) {
                self.alpha = 1
                self.tableBgView.frame = toFrame
            }
        }
        
        if reloadAlbumList {
            if #available(iOS 14.0, *), PHPhotoLibrary.authorizationStatus(for: .readWrite) == .limited {
                self.loadAlbumList {
                    animateShow()
                }
            } else {
                self.loadAlbumList()
                animateShow()
            }
        } else {
            animateShow()
        }
    }
    
    func hide() {
        var toFrame = self.tableBgView.frame
        toFrame.origin.y = -toFrame.height
        
        UIView.animate(withDuration: 0.25, animations: {
            self.alpha = 0
            self.tableBgView.frame = toFrame
        }) { (_) in
            self.isHidden = true
            self.alpha = 1
        }
    }
    
    @objc func tapAction(_ tap: UITapGestureRecognizer) {
        self.hide()
        self.hideBlock?()
    }
    
}


extension EmbedAlbumListView: UIGestureRecognizerDelegate {
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let p = gestureRecognizer.location(in: self)
        return !self.tableBgView.frame.contains(p)
    }
    
}


extension EmbedAlbumListView: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.arrDataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AlbumListCell", for: indexPath) as! AlbumListCell
        
        let m = self.arrDataSource[indexPath.row]
        
        cell.configureCell(model: m)
        
        cell.selectBtn.isSelected = m == self.selectedAlbum
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let m = self.arrDataSource[indexPath.row]
        self.selectedAlbum = m
        self.selectAlbumBlock?(m)
        self.hide()
        if let inx = tableView.indexPathsForVisibleRows {
            tableView.reloadRows(at: inx, with: .none)
        }
    }
    
}
