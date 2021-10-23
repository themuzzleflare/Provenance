import UIKit

extension UIWindow {
  static func provenance(windowScene: UIWindowScene) -> UIWindow {
    let window = UIWindow(windowScene: windowScene)
    window.backgroundColor = .systemBackground
    window.tintColor = .accentColor
    window.rootViewController = TabBarController()
    window.makeKeyAndVisible()
    return window
  }
}
