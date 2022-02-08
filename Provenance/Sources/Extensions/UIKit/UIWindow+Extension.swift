import UIKit

extension UIWindow {
  static func provenance(_ windowScene: UIWindowScene) -> UIWindow {
    let window = UIWindow(windowScene: windowScene)
    window.tintColor = .accentColor
    window.rootViewController = TabBarController()
    window.makeKeyAndVisible()
    return window
  }
}
