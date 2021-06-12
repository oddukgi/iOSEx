//
//  TableViewController.swift
//  FloatingPanelEx
//
//  Created by Sunmi on 2021/06/12.
//

import UIKit
import FloatingPanel


protocol TableViewControllerDelegate: AnyObject {
    func updateTableViewHeight()
}

class TableViewController: UIViewController, UITableViewDelegate,
                           UITableViewDataSource {
    
    @IBOutlet var tableView: UITableView!
    
    var myOrderList = [ "이화수 육개장": "전통육개장, 메밀전병",
                        "파이하우스" : "바나나크럼블파이" ,
                        "아오리라멘" : "아오리돈코츠라멘, ",
                        "소소한 식당" : "연어덮밥, "]
    

    var count: Int {
        return myOrderList.count
    }
    
    weak var delegate: TableViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        var insets = UIEdgeInsets.zero
        insets.top += 8.0
        tableView.contentInset = insets

        tableView.reloadData()
        
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = myOrderList.count
        
        return count 
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // cell update
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        let keys = Array(myOrderList.keys)
        let restaurant = keys[indexPath.row]

        cell.textLabel?.text = restaurant
        cell.detailTextLabel?.text = myOrderList[restaurant]
        
        return cell
    }
}

