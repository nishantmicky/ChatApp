//
//  RegisterViewController.swift
//  ChatApp
//
//  Created by Nishant Kumar on 26/04/25.
//

import Foundation
import UIKit
import FirebaseAuth
import FirebaseDatabase

class RegisterViewController: UIViewController {

    // MARK: - UI Elements
    
    let nameTextField = UITextField()
    let emailTextField = UITextField()
    let passwordTextField = UITextField()
    let signupButton = UIButton(type: .system)
    let backToLoginButton = UIButton(type: .system)
    let errorLabel = UILabel()
    
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupViews()
    }
    
    // MARK: - Layout

    private func setupViews() {
        nameTextField.placeholder = "Full Name"
        nameTextField.borderStyle = .roundedRect
        nameTextField.autocapitalizationType = .words

        emailTextField.placeholder = "Email"
        emailTextField.borderStyle = .roundedRect
        emailTextField.autocapitalizationType = .none

        passwordTextField.placeholder = "Password"
        passwordTextField.borderStyle = .roundedRect
        passwordTextField.isSecureTextEntry = true

        signupButton.setTitle("Register", for: .normal)
        signupButton.setTitleColor(.white, for: .normal)
        signupButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        signupButton.backgroundColor = .systemGreen
        signupButton.addTarget(self, action: #selector(handleSignup), for: .touchUpInside)

        backToLoginButton.setTitle("Back to Login", for: .normal)
        backToLoginButton.addTarget(self, action: #selector(goToLogin), for: .touchUpInside)
        
        errorLabel.textColor = .systemRed
        errorLabel.font = .systemFont(ofSize: 14)
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 0

        let stackView = UIStackView(arrangedSubviews: [nameTextField, emailTextField, passwordTextField, signupButton, backToLoginButton, errorLabel])
        stackView.axis = .vertical
        stackView.spacing = 24
        stackView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -50)
        ])
    }

    @objc func handleSignup() {
        guard let name = nameTextField.text,
              let email = emailTextField.text,
              let password = passwordTextField.text,
              !name.isEmpty else {
            self.errorLabel.text = "Register failed: Name can't be empty"
            return
        }
            
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                print("Register error: \(error.localizedDescription)")
                self.errorLabel.text = "Register failed: \(error.localizedDescription)"
                return
            }

            let changeRequest = result?.user.createProfileChangeRequest()
            changeRequest?.displayName = name
            changeRequest?.commitChanges { error in
                if let error = error {
                    print("Profile update error: \(error.localizedDescription)")
                    self.errorLabel.text = "Register failed: \(error.localizedDescription)"
                } else {
                    self.errorLabel.text = ""
                    print("Register success! Welcome, \(name)")
                    UserDefaults.standard.set(email, forKey: "email")
                    UserDefaults.standard.set(name, forKey: "name")
                    let newUser = User(email: email, name: name)
                    DatabaseManager.shared.insertUser(with: newUser)
                    let chatsVC = ChatsViewController(email)
                    let navController = UINavigationController(rootViewController: chatsVC)
                    navController.modalPresentationStyle = .fullScreen
                    self.present(navController, animated: true)
                }
            }
        }
    }

    @objc func goToLogin() {
        dismiss(animated: true, completion: nil)
    }
}

