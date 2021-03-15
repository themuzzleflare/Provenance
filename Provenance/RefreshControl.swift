import UIKit

class RefreshControl: UIRefreshControl {
    override init(frame: CGRect) {
        super.init(frame: .zero)
        self.tintColor = .white
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
