import UIKit

class ViewController: UIViewController {    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
}

private extension ViewController {
    private func configure() {
        view.backgroundColor = .systemGroupedBackground
        navigationItem.backButtonDisplayMode = .minimal
        navigationItem.hidesSearchBarWhenScrolling = false
    }
}
