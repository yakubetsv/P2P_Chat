//
//  CommandPopUpController.swift
//  LemelLabsTest
//
//  Created by Vladislav Yakubets on 2.04.21.
//

import UIKit

class CommandPopUpController: UITableViewController {
    let cellIdentifier = "DefaultCell"
    let commands = [CommandType.Update, CommandType.Delete]
    var complition: ((CommandType) -> ())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.isScrollEnabled = false
        tableView.separatorStyle = .none
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        self.tableView.contentInset = UIEdgeInsets(top: self.tableView.safeAreaInsets.top, left: 0, bottom: 0, right: 0)
    }
    
    // MARK: - TableView DataSource Methods

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 2
    }

    //MARK: -TableView Delegate Methods
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as UITableViewCell
        cell.textLabel?.text = commands[indexPath.row].rawValue
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        complition?(commands[indexPath.row])
        dismiss(animated: true, completion: nil)
    }
}
