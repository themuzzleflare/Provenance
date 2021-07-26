import UIKit
import SwiftyBeaver

class ViewController: UIViewController {
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(
            nibName: nibNameOrNil,
            bundle: nibBundleOrNil
        )

        log.debug("init(nibName: \(nibNameOrNil ?? "nil"), bundle: \(nibBundleOrNil?.bundlePath ?? "nil"))")

        configure()
    }

    required init?(coder: NSCoder) { fatalError("Not implemented") }
}

private extension ViewController {
    private func configure() {
        log.verbose("configure")

        view.backgroundColor = .systemGroupedBackground
    }
}
