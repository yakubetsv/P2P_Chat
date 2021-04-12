//
//  CommandPopUpController.swift
//  LemelLabsTest
//
//  Created by Vladislav Yakubets on 2.04.21.
//

import UIKit

class CommandPopUpController: UITableViewController {
    let cellIdentifier = "DefaultCell"
    let commands = [CommandType.Delete.rawValue, CommandType.Delete.rawValue]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 2
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        
        return cell
    }
}
