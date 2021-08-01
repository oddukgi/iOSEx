//
//  InfoViewController.swift
//  CustomBlurBackground
//
//  Created by Sunmi on 2021/08/01.
//

import UIKit

class InfoViewController: UIViewController {

    lazy var blurredView: UIView = {
        
        let containerView = UIView()
        let blurEffect = UIBlurEffect(style: .light)
        let customBlurEffectView = CustomVisualEffectView(effect: blurEffect, intensity: 0.2)
        customBlurEffectView.frame = self.view.bounds
     
        // create semi-transparent black view
        let dimmedView = UIView()
        dimmedView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        dimmedView.frame = self.view.bounds
        
        // add both as subviews
        containerView.addSubview(customBlurEffectView)
        containerView.addSubview(dimmedView)
        
        return containerView
        
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        createTapGestureRecognizer()
    }
    
    func setupView() {
        view.addSubview(blurredView)
        view.sendSubviewToBack(blurredView)
    }
    
    fileprivate func createTapGestureRecognizer() {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(touchedView(_:)))
        view.addGestureRecognizer(gesture)
    }
    
    
    @objc func touchedView(_ gesture: UITapGestureRecognizer) {
        dismiss(animated: true)
    }


    @IBAction func dismissAction(_ sender: UIButton) {
        dismiss(animated: true)
    }
}
