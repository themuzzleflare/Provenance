import UIKit

class RefreshControl: UIRefreshControl {
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension RefreshControl {
    private func configure() {
        tintColor = .white
    }
}
