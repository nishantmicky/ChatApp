//
//  LoginViewController.swift
//  ChatApp
//
//  Created by Nishant Kumar on 25/04/25.
//

import Foundation
import UIKit
import FirebaseAuth

class LoginViewController: UIViewController {
    
    // MARK: - UI Elements
    
    let emailTextField = UITextField()
    let passwordTextField = UITextField()
    let loginButton = UIButton(type: .system)
    let switchToSignUpButton = UIButton(type: .system)
    let errorLabel = UILabel()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupViews()
        loginButton.addTarget(self, action: #selector(handleLogin), for: .touchUpInside)
    }
    
    // MARK: - Layout

    private func setupViews() {
        emailTextField.placeholder = "Email"
        emailTextField.borderStyle = .roundedRect
        emailTextField.autocapitalizationType = .none

        passwordTextField.placeholder = "Password"
        passwordTextField.borderStyle = .roundedRect
        passwordTextField.isSecureTextEntry = true

        loginButton.setTitle("Login", for: .normal)
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        loginButton.backgroundColor = .systemBlue
        loginButton.addTarget(self, action: #selector(handleLogin), for: .touchUpInside)

        let attributedTitle = NSMutableAttributedString(string: "Don't have an account? ",
                                                        attributes: [.foregroundColor: UIColor.gray])
        attributedTitle.append(NSAttributedString(string: "Register",
                                                  attributes: [.foregroundColor: UIColor.systemBlue]))
        switchToSignUpButton.setAttributedTitle(attributedTitle, for: .normal)
        switchToSignUpButton.addTarget(self, action: #selector(navigateToRegister), for: .touchUpInside)
        
        errorLabel.textColor = .systemRed
        errorLabel.font = .systemFont(ofSize: 14)
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 0

        let stackView = UIStackView(arrangedSubviews: [emailTextField, passwordTextField, loginButton, switchToSignUpButton, errorLabel])
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
    
    // MARK: - Actions
    
    @objc private func handleLogin() {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            errorLabel.text = "Please enter email and password."
            return
        }
        
        errorLabel.text = ""
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                self?.errorLabel.text = "Login failed: \(error.localizedDescription)"
            } else {
                self?.errorLabel.text = ""
                self?.navigateToHome(email: email)
            }
        }
    }
    
    @objc func navigateToRegister() {
        let registerVC = RegisterViewController()
        let navController = UINavigationController(rootViewController: registerVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }
    
    private func navigateToHome(email: String) {
        UserDefaults.standard.set(email, forKey: "email")
        DatabaseManager.shared.getUserName(currentEmail: email, completion: { name in
            DispatchQueue.main.async {
                UserDefaults.standard.set(name, forKey: "name")
                let chatsVC = ChatsViewController(email)
                let navController = UINavigationController(rootViewController: chatsVC)
                navController.modalPresentationStyle = .fullScreen
                self.present(navController, animated: true)
            }
        })
    }
}

