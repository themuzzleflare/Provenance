import UIKit
import Rswift

class CollectionViewController: UICollectionViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
}

extension CollectionViewController {
    private func configure() {
        collectionView.backgroundColor = R.color.bgColour()
        collectionView.indicatorStyle = .white
        collectionView.showsHorizontalScrollIndicator = false
        
        #if !targetEnvironment(macCatalyst)
        collectionView.showsVerticalScrollIndicator = false
        #endif
    }
}
