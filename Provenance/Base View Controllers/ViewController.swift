import UIKit

class ViewController: UIViewController {
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
}

// MARK: - Configuration

private extension ViewController {
    private func configure() {
        view.backgroundColor = .systemGroupedBackground
        navigationItem.backButtonDisplayMode = .minimal
        navigationItem.hidesSearchBarWhenScrolling = false
    }
}
