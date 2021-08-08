//
//  PlayerTableViewCell.swift
//  PaginationDemo
//
//  Created by Sunmi on 2021/08/08.
//

import UIKit

class PlayerTableViewCell: UITableViewCell {

    
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var teamLabel: UILabel!
    @IBOutlet var cityLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func prepareForReuse() {
        nameLabel.text = nil
        teamLabel.text = nil
        cityLabel.text = nil
    }
    
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func updateValue(name: String, team: String, city: String) {
        nameLabel.text = name
        teamLabel.text = team
        cityLabel.text = city
    }
}
