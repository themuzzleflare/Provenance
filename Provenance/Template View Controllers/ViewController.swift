import UIKit
import Rswift

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViewStyle()
    }
    
    private func setupViewStyle() {
        view.backgroundColor = R.color.bgColour()
    }
}
