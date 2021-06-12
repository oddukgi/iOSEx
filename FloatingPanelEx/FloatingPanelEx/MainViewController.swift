//
//  MainViewController.swift
//  FloatingPanelEx
//
//  Created by Sunmi on 2021/06/12.
//

import UIKit
import FloatingPanel



class MainViewController: UIViewController {



    var fpc: FloatingPanelController!
    var tableViewController: TableViewController!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupFloatingPanel()
        // Do any additional setup after loading the view.
    }


    
    func setupFloatingPanel() {
        fpc = FloatingPanelController()
        let appearance = SurfaceAppearance()
        appearance.cornerRadius = 40.0
        fpc.surfaceView.appearance = appearance
        tableViewController = storyboard?.instantiateViewController(identifier: "TableViewController")
        tableViewController.delegate = self
        fpc.set(contentViewController: tableViewController)
        
        fpc.delegate = self
        fpc.contentMode = .fitToBounds
        fpc.backdropView.dismissalTapGestureRecognizer.isEnabled = true
        fpc.isRemovalInteractionEnabled = true
    }
    
    
    @IBAction func tappedOpenTableVC() {
        tableViewController.myOrderList.removeValue(forKey: "아오리라멘")
        tableViewController.myOrderList.updateValue("어묵핫바", forKey: "튀김집")
        fpc.addPanel(toParent: self)
    }
}


extension MainViewController: FloatingPanelControllerDelegate {
    func floatingPanel(_ fpc: FloatingPanelController, contentOffsetForPinning trackingScrollView: UIScrollView) -> CGPoint {
        return CGPoint(x: 0.0, y: 0.0 - trackingScrollView.contentInset.top)
    }
    
    
    func floatingPanel(_ fpc: FloatingPanelController, layoutFor newCollection: UITraitCollection) -> FloatingPanelLayout {
        return FlexiblePanelLayout(owner: tableViewController)
    }

    func floatingPanelDidRemove(_ fpc: FloatingPanelController) {
    }

}

extension MainViewController: TableViewControllerDelegate {
    
    func updateTableViewHeight() {
        
        
        UIView.animate(withDuration: 0.2) {
              self.view.layoutIfNeeded()
              self.fpc.invalidateLayout()
        }
        
    }


}
