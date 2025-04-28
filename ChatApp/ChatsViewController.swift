//
//  ChatsViewController.swift
//  ChatApp
//
//  Created by Nishant Kumar on 26/04/25.
//

import Foundation
import UIKit
import FirebaseAuth

struct Conversation {
    let id: String
    let name: String
    let otherUserEmail: String
    let latestMessage: LatestMessage
}

struct LatestMessage {
    let date: String
    let text: String
    let isRead: Bool
}

class ChatsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    let tableView = UITableView()
    let noUsersLabel = UILabel()
    var currentUserEmail: String
    var users: [User] = []
    var conversations: [Conversation] = []
    
    init(_ email: String) {
        self.currentUserEmail = email
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Chats"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit",
                                                            style: .plain,
                                                            target: self,
                                                            action: #selector(editProfileTapped))
        view.backgroundColor = .white
        setupNoUsersLabel()
        setupTableView()
        fetchUserChats()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        noUsersLabel.frame = CGRect(x: 0,
                                    y: view.bounds.midY - 50,
                                    width: view.bounds.width,
                                    height: 50)
        tableView.frame = view.bounds
    }
    
    func setupNoUsersLabel() {
        noUsersLabel.text = "No other users found"
        noUsersLabel.textAlignment = .center
        noUsersLabel.textColor = .gray
        noUsersLabel.font = .systemFont(ofSize: 20, weight: .medium)
        noUsersLabel.isHidden = true
        view.addSubview(noUsersLabel)
    }

    func setupTableView() {
        tableView.frame = view.bounds
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ChatCell.self, forCellReuseIdentifier: "ChatCell")
        tableView.rowHeight = 70
        tableView.isHidden = true
        view.addSubview(tableView)
    }

    func fetchUserChats() {
        DatabaseManager.shared.getAllUsers { [weak self] result in
            switch result {
            case .success(let users):
                self?.filterCurrentUser(allUsers: users)
            case .failure(let error):
                print("Error: \(error)")
                self?.updateUI(dataPresent: false)
            }
        }
    }
    
    @objc func editProfileTapped() {
        let editVC = EditProfileViewController()
        navigationController?.pushViewController(editVC, animated: true)
    }
    
    func getAllConversations() {
        let safeEmail = Utils.getSafeEmail(from: currentUserEmail)
        DatabaseManager.shared.getAllConversations(for: safeEmail, completion: { [weak self] result in
            switch result {
            case .success(let conversations):
                self?.conversations = conversations
                print("Conversations: \(conversations)")
            case .failure(let error):
                print("Error: \(error)")
            }
            if self?.users.count == 0 {
                self?.updateUI(dataPresent: false)
            } else {
                self?.updateUI(dataPresent: true)
            }
        })
    }
    
    func updateUI(dataPresent: Bool) {
        DispatchQueue.main.async {
            if dataPresent {
                self.noUsersLabel.isHidden = true
                self.tableView.isHidden = false
                self.tableView.reloadData()
            } else {
                self.tableView.isHidden = true
                self.noUsersLabel.isHidden = false
            }
        }
    }
    
    func filterCurrentUser(allUsers: [User]) {
        users = allUsers.filter { $0.email != currentUserEmail }
        getAllConversations()

        var name = ""
        for user in users {
            if user.email == currentUserEmail {
                name = user.name
                break;
            }
        }
        UserDefaults.standard.set(name, forKey: "name")
    }

    // MARK: - TableView

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatCell", for: indexPath) as! ChatCell

        let user = users[indexPath.row]
        var latestMessage = ""
        for conversation in conversations {
            if conversation.otherUserEmail == user.email {
                latestMessage = conversation.latestMessage.text
                break
            }
        }
        cell.configure(with: user.name, message: latestMessage, imageURL: nil)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Tapped on \(indexPath.row)")
        tableView.deselectRow(at: indexPath, animated: true)
    
        let otherUserEmail = users[indexPath.row].email
        let vc = ConversationViewController(currentUserEmail, otherUserEmail)
        vc.title = users[indexPath.row].name
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
}

