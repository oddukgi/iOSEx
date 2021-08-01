//
//  ViewController.swift
//  CustomBlurBackground
//
//  Created by Sunmi on 2021/08/01.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func showDetailAction() {
        
        if let infoVC = storyboard?.instantiateViewController(identifier: "InfoViewController") {
            infoVC.modalPresentationStyle = .overCurrentContext
            infoVC.modalTransitionStyle = .crossDissolve
            present(infoVC, animated: true)
        }
    }
    
}

