//
//  ChatsController.swift
//  LemelLabsTest
//
//  Created by Vladislav Yakubets on 25.03.21.
//

import UIKit
import CoreData

class UsersController: UITableViewController {
    var user: UserMO!
    
    private var chats: [ChatMO]! {
        didSet {
            for chat in chats {
                print("Chat: \(chat.users!.description)")
            }
            
            tableView.reloadData()
        }
    }
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetchUsers()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return chats.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "cell")

        cell.textLabel?.text = chats[indexPath.row].users!.description

        return cell
    }
    
    func fetchUsers() {
        let fetchRequest = NSFetchRequest<ChatMO>(entityName: "Chat")
        
        do {
            chats = try appDelegate.persistentContainer.viewContext.fetch(fetchRequest)
        } catch  {
            fatalError(error.localizedDescription)
        }
    }
}
