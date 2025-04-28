//
//  EditProfileViewController.swift
//  ChatApp
//
//  Created by Nishant Kumar on 26/04/25.
//

import Foundation
import UIKit
import FirebaseAuth
import FirebaseDatabase

class EditProfileViewController: UIViewController {
    
    // MARK: - UI Elements

    let nameLabel = UILabel()
    let nameTextField = UITextField()
    let saveButton = UIButton(type: .system)
    let logoutButton = UIButton(type: .system)
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Edit Profile"
        view.backgroundColor = .white
        setupViews()
        
        let currentEmail = UserDefaults.standard.object(forKey: "email") as! String
        DatabaseManager.shared.getUserName(currentEmail: currentEmail, completion: { [weak self] name in
            DispatchQueue.main.async {
                self?.nameTextField.text = name
                UserDefaults.standard.set(name, forKey: "name")
            }
        })
    }
    
    // MARK: - Layout

    private func setupViews() {
        nameLabel.text = "Name"
        nameLabel.font = UIFont.boldSystemFont(ofSize: 16)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        nameTextField.placeholder = "Enter your name"
        nameTextField.text = UserDefaults.standard.string(forKey: "name")
        nameTextField.borderStyle = .roundedRect
        nameTextField.translatesAutoresizingMaskIntoConstraints = false

        saveButton.setTitle("Save", for: .normal)
        saveButton.backgroundColor = .systemBlue
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.layer.cornerRadius = 8
        saveButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        saveButton.addTarget(self, action: #selector(saveChanges), for: .touchUpInside)
        
        logoutButton.setTitle("Logout", for: .normal)
        logoutButton.setTitleColor(.systemRed, for: .normal)
        logoutButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        logoutButton.translatesAutoresizingMaskIntoConstraints = false
        logoutButton.addTarget(self, action: #selector(handleLogout), for: .touchUpInside)


        let stack = UIStackView(arrangedSubviews: [nameLabel, nameTextField, saveButton, logoutButton])
        stack.axis = .vertical
        stack.spacing = 24
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)

        NSLayoutConstraint.activate([
            nameTextField.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.85),

            saveButton.widthAnchor.constraint(equalTo: nameTextField.widthAnchor),

            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    @objc func saveChanges() {
        if let currentEmail = UserDefaults.standard.object(forKey: "email") as? String,
            let text = self.nameTextField.text, !text.isEmpty {
            DatabaseManager.shared.updateUserName(currentEmail: currentEmail, newName: text)
            UserDefaults.standard.set(text, forKey: "name")
        }
        navigationController?.popViewController(animated: true)
    }
    
    @objc func handleLogout() {
        do {
            try Auth.auth().signOut()
            UserDefaults.standard.removeObject(forKey: "email")
            UserDefaults.standard.removeObject(forKey: "name")

            let loginVC = LoginViewController()
            let nav = UINavigationController(rootViewController: loginVC)
            nav.modalPresentationStyle = .fullScreen
            self.present(nav, animated: true, completion: nil)
        } catch {
            print("Logout error: \(error)")
        }
    }
}

