import UIKit
import Firebase
import NotificationBannerSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions:[UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        
        let viewController = TabBarController()
        let settingsController = SettingsVC(style: .grouped)
        
        window?.rootViewController = viewController
        
        window?.makeKeyAndVisible()
        
        FirebaseApp.configure()
        
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
            
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        application.registerForRemoteNotifications()
        
        Messaging.messaging().delegate = self
        
        if UserDefaults.standard.string(forKey: "apiKey") == "" || UserDefaults.standard.string(forKey: "apiKey") == nil {
            let ac = UIAlertController(title: "API Key Required", message: "You don't have an API Key set. Set one now.", preferredStyle: .alert)
            ac.addTextField(configurationHandler: { field in
                field.autocapitalizationType = .none
                field.autocorrectionType = .no
                field.text = UserDefaults.standard.string(forKey: "apiKey") ?? nil
            })
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            
            let submitAction = UIAlertAction(title: "Save", style: .default) { [unowned ac] _ in
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
                                    let banner = NotificationBanner(title: "Success", subtitle: "The API Key was verified and set.", leftView: nil, rightView: nil, style: .success, colors: nil)
                                    banner.duration = 2
                                    settingsController.appearingBanner = banner
                                    self.window?.rootViewController?.present(UINavigationController(rootViewController: settingsController), animated: true)
                                }
                            } else {
                                DispatchQueue.main.async {
                                    let banner = NotificationBanner(title: "Failed", subtitle: "The API Key could not be verified.", leftView: nil, rightView: nil, style: .danger, colors: nil)
                                    banner.duration = 2
                                    settingsController.appearingBanner = banner
                                    self.window?.rootViewController?.present(UINavigationController(rootViewController: settingsController), animated: true)
                                }
                            }
                        } else {
                            DispatchQueue.main.async {
                                let banner = NotificationBanner(title: "Failed", subtitle: error?.localizedDescription ?? "The API Key could not be verified.", leftView: nil, rightView: nil, style: .danger, colors: nil)
                                banner.duration = 2
                                settingsController.appearingBanner = banner
                                self.window?.rootViewController?.present(UINavigationController(rootViewController: settingsController), animated: true)
                            }
                        }
                    }
                    .resume()
                } else {
                    let banner = NotificationBanner(title: "Failed", subtitle: "The provided API Key was either empty, or the same as the current one.", leftView: nil, rightView: nil, style: .danger, colors: nil)
                    banner.duration = 2
                    settingsController.appearingBanner = banner
                    self.window?.rootViewController?.present(UINavigationController(rootViewController: settingsController), animated: true)
                }
            }
            
            ac.addAction(cancelAction)
            ac.addAction(submitAction)
            
            window?.rootViewController?.present(ac, animated: true)
        }
        
        return true
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        let dataDict:[String: String] = ["token": fcmToken ?? ""]
        NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: dataDict)
    }
}
