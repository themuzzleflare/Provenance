import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    weak var submitActionProxy: UIAlertAction?
    private var textDidChangeObserver: NSObjectProtocol!
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions:[UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        
        let viewController = TabBarController()
        let settingsController = SettingsVC(style: .grouped)
        
        window?.rootViewController = viewController
        
        window?.makeKeyAndVisible()
        
        if UserDefaults.standard.string(forKey: "apiKey") == "" || UserDefaults.standard.string(forKey: "apiKey") == nil {
            let ac = UIAlertController(title: "API Key Required", message: "You don't have an API Key set. Set one now.", preferredStyle: .alert)
            ac.addTextField(configurationHandler: { textField in
                textField.autocapitalizationType = .none
                textField.autocorrectionType = .no
                textField.text = UserDefaults.standard.string(forKey: "apiKey") ?? nil
                
                self.textDidChangeObserver = NotificationCenter.default.addObserver(
                    forName: UITextField.textDidChangeNotification,
                    object: textField,
                    queue: OperationQueue.main) { (notification) in
                    if let textField = notification.object as? UITextField {
                        if let text = textField.text {
                            self.submitActionProxy!.isEnabled = text.count >= 1 && text != UserDefaults.standard.string(forKey: "apiKey")
                        } else {
                            self.submitActionProxy!.isEnabled = false
                        }
                    }
                }
            })
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            
            let submitAction = UIAlertAction(title: "Save", style: .default) { _ in
                let answer = ac.textFields![0]
                if (answer.text != "" && answer.text != nil) && answer.text != UserDefaults.standard.string(forKey: "apiKey") {
                    let url = URL(string: "https://api.up.com.au/api/v1/util/ping")!
                    var request = URLRequest(url: url)
                    request.httpMethod = "GET"
                    request.addValue("application/json", forHTTPHeaderField: "Accept")
                    request.addValue("Bearer \(answer.text!)", forHTTPHeaderField: "Authorization")
                    URLSession.shared.dataTask(with: request) { data, response, error in
                        if error == nil {
                            let statusCode = (response as! HTTPURLResponse).statusCode
                            if statusCode == 200 {
                                DispatchQueue.main.async {
                                    UserDefaults.standard.set(answer.text!, forKey: "apiKey")
                                    self.window?.rootViewController?.present(UINavigationController(rootViewController: settingsController), animated: true)
                                }
                            } else {
                                DispatchQueue.main.async {
                                    let ac = UIAlertController(title: "Failed", message: "The API Key could not be verified.", preferredStyle: .alert)
                                    let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel, handler: { _ in
                                        self.window?.rootViewController?.present(UINavigationController(rootViewController: settingsController), animated: true)
                                    })
                                    ac.addAction(dismissAction)
                                    self.window?.rootViewController?.present(ac, animated: true)
                                }
                            }
                        } else {
                            DispatchQueue.main.async {
                                let ac = UIAlertController(title: "Failed", message: error?.localizedDescription ?? "The API Key could not be verified.", preferredStyle: .alert)
                                let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel, handler: { _ in
                                    self.window?.rootViewController?.present(UINavigationController(rootViewController: settingsController), animated: true)
                                })
                                ac.addAction(dismissAction)
                                self.window?.rootViewController?.present(ac, animated: true)
                            }
                        }
                    }
                    .resume()
                } else {
                    let ac = UIAlertController(title: "Failed", message: "The provided API Key was the same as the current one.", preferredStyle: .alert)
                    let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel, handler: { _ in
                        self.window?.rootViewController?.present(UINavigationController(rootViewController: settingsController), animated: true)
                    })
                    ac.addAction(dismissAction)
                    self.window?.rootViewController?.present(ac, animated: true)
                }
            }
            
            submitAction.isEnabled = false
            submitActionProxy = submitAction
            
            ac.addAction(cancelAction)
            ac.addAction(submitAction)
            
            window?.rootViewController?.present(ac, animated: true)
        }
        
        return true
    }
}
