//
//  LoginViewController.swift
//  Messenger
//
//  Created by Алексей Авдейчик on 13.07.21.
//

import UIKit
import Firebase
import FBSDKLoginKit
import JGProgressHUD
import GoogleSignIn

final class LoginViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "logo")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let emailField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Email adress"
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        field.layer.shadowOpacity = 1
        field.layer.shadowRadius = 5
        field.layer.shadowOffset = CGSize(width: 10, height: 10)
        return field
    }()
    
    private let passwordField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .done
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Password"
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        field.isSecureTextEntry = true
        return field
    }()
    
    private let loginButton: UIButton = {
        let button = UIButton()
        button.setTitle("Log in", for: .normal)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    
    private let facebookloginButton: FBLoginButton = {
        let button = FBLoginButton()
        button.permissions = ["email", "public_profile"]
        return button
    }()
    
    private var loginObserver: NSObjectProtocol?
    
    let gradientlayer = CAGradientLayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        loginObserver = NotificationCenter.default.addObserver(forName: .didLogInNotification, object: nil, queue: .main, using: { [weak self] _ in
            guard let strongSelf = self else {
                return
            }
         
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
        })
        
        title = "Log in"
//        view.backgroundColor = .systemBackground
        view.layer.addSublayer(gradientlayer)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(didTapRegister))
        
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        
        emailField.delegate = self
        passwordField.delegate = self
        facebookloginButton.delegate = self
        
        // Add subviews
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(loginButton)
        scrollView.addSubview(facebookloginButton)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setGrayGradientBackground()
        
    }
    
    func setGrayGradientBackground() {
        let topColor = UIColor(red: 151/255.0, green: 151/255.0, blue: 151.0/255.0, alpha: 1.0).cgColor
        let midleColor = UIColor(red: 195.0/255.0, green: 165.0/255.0, blue: 1.0, alpha: 1.0).cgColor
        let bottomColor = UIColor(red: 72.0/255.0, green: 84.0/255.0, blue: 100.0/255.0, alpha: 1.0).cgColor
        gradientlayer.frame = view.bounds
        gradientlayer.colors = [topColor, midleColor, bottomColor]
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        let size = scrollView.width / 3
        imageView.frame = CGRect(x:(scrollView.width - size)/2,
                                 y: 20,
                                 width: size,
                                 height: size)
        emailField.frame = CGRect(x: 30,
                                  y: imageView.bottom + 10,
                                  width: scrollView.width - 60,
                                  height: 52)
        emailField.frame = CGRect(x: 30,
                                  y: imageView.bottom + 10,
                                  width: scrollView.width - 60,
                                  height: 52)
        passwordField.frame = CGRect(x: 30,
                                     y: emailField.bottom + 15,
                                     width: scrollView.width - 60,
                                     height: 52)
        loginButton.frame = CGRect(x: 30,
                                   y: passwordField.bottom + 15,
                                   width: scrollView.width - 60,
                                   height: 52)
        facebookloginButton.frame = CGRect(x: 30,
                                           y: loginButton.bottom + 15,
                                           width: scrollView.width - 60,
                                           height: 52)
        facebookloginButton.frame.origin.y = loginButton.bottom + 20
    }
    
    @objc func loginButtonTapped() {
        
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        
        guard let email = emailField.text, let password = passwordField.text,
              !email.isEmpty, !password.isEmpty  else {
            alertUserLoginError()
            return
        }
        
        guard password.count >= 6 else {
            alertPasswordError()
            return
        }
        
        spinner.show(in: view)
        
        //MARK: - Firebase log in
        Firebase.Auth.auth().signIn(withEmail: email, password: password, completion: { [weak self] (authResult, error) in
            guard let strongSelf = self else {
                return
            }
            
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss()
            }
            
            guard let result = authResult, error == nil else {
                print("Faled to log in with email \(email)")
                return
            }
            
            let user = result.user
            
            let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
            DatabaseManager.shared.getDataFor(path: safeEmail) { result in
                switch result {
                case .success(let data):
                    guard let userData = data as? [String: Any],
                    let firstName = userData["first_name"] as? String,
                    let lastName = userData["last_name"] as? String else {
                        return
                    }
                    UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
                case .failure(let error):
                    print("Falue to read data with error \(error)")
                }
            }
            
            UserDefaults.standard.set(email, forKey: "email")
            
            
            print("Logged in User \(user)")
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
        })
    }
    
    func alertUserLoginError() {
        let alert = UIAlertController(title: "Woops",
                                      message: "Please enter all information to log in",
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Dissmis", style: .cancel, handler: nil))
        
        present(alert, animated: true)
    }
    
    func alertPasswordError() {
        
        let alert = UIAlertController(title: "Woops",
                                      message: "Password must contain at least 6 characters",
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Dissmis", style: .cancel, handler: nil))
        
        present(alert, animated: true)
    }
    
    @objc func didTapRegister() {
        
        let vc = RegisterViewController()
        vc.title = "Create Account"
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension LoginViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == emailField {
            passwordField.becomeFirstResponder()
        } else if textField == passwordField {
            loginButtonTapped()
        }
        
        return true
    }
}

extension LoginViewController: LoginButtonDelegate {
    
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        // no operation
    }
    // MARK: - Facebook log in button
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        guard let token = result?.token?.tokenString else {
            print("User failed to log in with facebook")
            return
        }
        // запрос на получение данных вошедшего в систему пользователя (имейл имя)
        let facebookRequest = FBSDKLoginKit.GraphRequest(graphPath: "me",
                                                         parameters: ["fields" :
                                                                        "email, first_name, last_name, picture.type(large)"],
                                                         tokenString: token,
                                                         version: nil,
                                                         httpMethod: .get)
        // вызов выполнения получения данных
        facebookRequest.start { (_, result, error ) in
            guard let result = result as? [String: Any], error == nil else {
                print("Faled to make facebook graph request")
                return
            }
            print(result)
            
            guard let firstName = result["first_name"] as? String,
                  let lastName = result["last_name"] as? String,
                  let email = result["email"] as? String,
                  let picture = result["picture"] as? [String: Any],
                  let data = picture["data"] as? [String: Any],
                  let pictureUrl = data["url"] as? String else {
                print("Faled to get name and email from fb result")
                return
            }
            
            UserDefaults.standard.set(email, forKey: "email")
            UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
            
            
            DatabaseManager.shared.userExists(with: email, completion: { exists in
                if !exists {
                    
                    let chatUser = ChatAppUser(firstName: firstName,
                                               lastName: lastName,
                                               emailAdress: email)
                    
                    DatabaseManager.shared.insertUser(with: chatUser, completion: { success in
                        if success {
                            
                            guard  let url = URL(string: pictureUrl) else {
                                return
                            }
                            print("Downloading data from facebook image")
                            
                            URLSession.shared.dataTask(with: url, completionHandler: { data, _, _ in
                                guard let data = data else {
                                    print("faled to get data from fb")
                                    return
                                }
                                
                                print("got data from fb")
                                
                                //upload image
                                let filename =  chatUser.profilePictureFileName
                                StorageManager.shared.uploadProfileImage(with: data, fileName: filename, completion: { result in
                                    switch result {
                                    case .success(let downloadUrl):
                                        UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
                                        print(downloadUrl)
                                    case .failure(let error):
                                        print("Storage manager error: \(error)")
                                    }
                                })
                            }).resume()
                        }
                    })
                }
            })
            //учетные данные
            let credential = FacebookAuthProvider.credential(withAccessToken: token)
            
            Firebase.Auth.auth().signIn(with: credential, completion: { [weak self] authResult, error in
                guard let strongSelf = self else { return }
                
                guard authResult != nil, error == nil else {
                    if let error = error {
                        // multi-factor auth
                        print("Facebook credential login faled, MFA maybe needed - \(error)")
                    }
                    
                    return
                }
                print("Sucessfuly logged user in")
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            })
        }
    }
}
