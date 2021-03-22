import UIKit
import Rswift

class CollectionViewController: UICollectionViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCollectionViewStyle()
    }
    
    private func setupCollectionViewStyle() {
        collectionView.backgroundColor = R.color.bgColour()
        collectionView.indicatorStyle = .white
        collectionView.showsHorizontalScrollIndicator = false
        #if !targetEnvironment(macCatalyst)
        collectionView.showsVerticalScrollIndicator = false
        #endif
    }
}
