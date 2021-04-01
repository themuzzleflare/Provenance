import UIKit
import Rswift

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configure()
    }
}

extension ViewController {
    private func configure() {
        view.backgroundColor = R.color.bgColour()
    }
}
