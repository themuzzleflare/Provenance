import AsyncDisplayKit

final class NavigationController: ASDKNavigationController {
  override func viewDidLoad() {
    super.viewDidLoad()
    navigationBar.prefersLargeTitles = true
  }
}
