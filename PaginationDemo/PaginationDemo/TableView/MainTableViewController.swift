//
//  MainTableViewController.swift
//  PrefetcherDemo
//
//  Created by Sunmi on 2021/08/08.
//

import UIKit

class MainTableViewController: UITableViewController {
    
    
    private var offset = 68
    private var isLoading = false
    private var players = [Player]() {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.tableView.reloadData()
            }
        }
    }
    
    var totalPages = 0

    private lazy var refresh: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.backgroundColor = .clear
        refreshControl.tintColor = .black
        refreshControl.addTarget(self, action: #selector(refreshIt), for: .valueChanged)
        return refreshControl
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        fetchNBAPlayers()
    }

    
    private func setupView() {
        title = "NBA Player List"
        
        // Register Loading Cell
        let loadingCellNib = UINib(nibName: "LoadingTableViewCell", bundle: nil)
        self.tableView.register(loadingCellNib, forCellReuseIdentifier: "LoadingTableViewCell")
        tableView.refreshControl = refresh
    }
    
    // MARK: - API Handler
    
    private func fetchNBAPlayers(completed: ((Bool) -> Void)? = nil) {
        
        self.isLoading = true
        
        NetworkManager.shared.getPlayers(page: offset, success: { [weak self] (players, meta) in
            
            guard let self = self,
                  let newPlayers = players,
                  let meta = meta else { return }
           
    
            self.totalPages = meta.totalPages
            self.players.append(contentsOf: newPlayers)
            self.isLoading = false
            
        }, failure: { error in
            debugPrint(error.localizedDescription)
            completed?(false)
            
        })
    }
    
    @objc func refreshIt(_ sender: Any) {
        self.refresh.endRefreshing()
        fetchNBAPlayers()
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // 8
      
        switch section {
        case 0:
            return players.count
        default:
            return offset < totalPages ? 1 : 0
        }
    }
    

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
        if indexPath.section == 0 {
      
            let cell = tableView.dequeueReusableCell(withIdentifier: "PlayerCell",
                                                           for: indexPath) as! PlayerTableViewCell
            let player = players[indexPath.row]
            let name = player.lastName + player.firstName
            let team = player.team.name
            let city = player.team.city
            cell.updateValue(name: name, team: team, city: city)
            return cell
            
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "LoadingTableViewCell",
                                                     for: indexPath) as! LoadingTableViewCell
            cell.activityIndicator.startAnimating()
            return cell
        }
    }
    
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if players.isEmpty { return }

        if indexPath.section == 1 {
            
            offset += 1
            fetchNBAPlayers { [weak self] success in
                if !success {
                    
                    let cell = tableView.dequeueReusableCell(withIdentifier: "LoadingTableViewCell",
                                                             for: indexPath) as! LoadingTableViewCell
                    cell.activityIndicator.stopAnimating()
                    self?.hideLoadingCell()
                }
            }
            print("Offset: \(offset), totalPages: \(totalPages)")
        }
    }
//
    private func hideLoadingCell() {
        DispatchQueue.main.async {
            let lastListIndexPath = IndexPath(row: self.players.count - 1, section: 0)
            self.tableView.scrollToRow(at: lastListIndexPath, at: .bottom, animated: true)
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 112 //Item Cell height
        } else {
            return 44 //Loading Cell height
        }
    }
    // Show/Hide the NavigationBar when scrolling
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.panGestureRecognizer.translation(in: scrollView).y < 0 {
            navigationController?.setNavigationBarHidden(true, animated: true)
        } else {
            navigationController?.setNavigationBarHidden(false, animated: true)
        }
    }
    
    
    
//        let offsetY = scrollView.contentOffset.y
//        let contentHeight = scrollView.contentSize.height
//
//        if (offsetY > contentHeight - scrollView.frame.height * 4)
//            && (offset < totalPages) {
//                offset += 1
//
//                fetchNBAPlayers { [weak self] success in
//                    if !success {
//                        self?.hideLoadingCell()
//                    }
//                }
//
//            print("Offset: \(offset), totalPages: \(totalPages)")
//
//        }
//    }

}

