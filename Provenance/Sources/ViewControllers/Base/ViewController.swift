import UIKit

class ViewController: UIViewController {
  deinit {
#if DEBUG
    print("\(#function) \(String(describing: type(of: self)))")
#endif
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    configureView()
  }

  private func configureView() {
    view.backgroundColor = .systemBackground
  }
}
