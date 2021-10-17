//
//  PhotoView.swift
//  MultiplePictureUploader
//
//  Created by Sunmi on 2021/10/15.
//

import UIKit

@IBDesignable
public class PhotoView: UIView {
    
    @IBOutlet weak var view: UIView!
    @IBOutlet weak var subView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var deleteBtn: UIButton!
    
    var deleteBlock: ((UIImage?) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        nibSetup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        nibSetup()
    }

    private func nibSetup() {
        backgroundColor = .clear
        view = loadViewFromNib()
        view.frame = bounds
        view.backgroundColor = .white
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.translatesAutoresizingMaskIntoConstraints = true

        addSubview(view)
        
        deleteBtn.enlargeValidTouchArea(insets: UIEdgeInsets(top: 5, left: 10,
                                                             bottom: 10, right: 5))
    
    }

    private func loadViewFromNib() -> UIView {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: String(describing: type(of: self)), bundle: bundle)
        let nibView = nib.instantiate(withOwner: self, options: nil).first as! UIView

        return nibView
    }
    
    @IBAction func deleteImage() {
        deleteBlock?(imageView.image)
    }
}
