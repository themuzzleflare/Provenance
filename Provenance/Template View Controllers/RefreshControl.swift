import UIKit

class RefreshControl: UIRefreshControl {
    override init(frame: CGRect) {
        super.init(frame: .zero)
        
        configure()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

extension RefreshControl {
    private func configure() {
        self.tintColor = .white
    }
}
