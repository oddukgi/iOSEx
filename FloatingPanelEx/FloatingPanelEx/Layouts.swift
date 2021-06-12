//
//  Layouts.swift
//  FloatingPanelEx
//
//  Created by Sunmi on 2021/06/12.
//

import Foundation
import FloatingPanel

class FlexiblePanelLayout: FloatingPanelLayout {
    
    
    unowned let owner: TableViewController

    init(owner: TableViewController) {
        self.owner = owner
    }
    
    
    let position: FloatingPanelPosition = .bottom
    let initialState: FloatingPanelState = .half

    
    
    var anchors: [FloatingPanelState : FloatingPanelLayoutAnchoring] {
        
        let height = owner.tableView.contentSize.height
        return [
            .half: FloatingPanelLayoutAnchor(absoluteInset: CGFloat(0 + height), edge: .bottom, referenceGuide: .safeArea)
        ]
    }

    func backdropAlpha(for state: FloatingPanelState) -> CGFloat {
        return 0.3
    }
}
