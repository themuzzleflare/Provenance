import UIKit

class ViewController: UIViewController {
        // MARK: - Life Cycle
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
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
