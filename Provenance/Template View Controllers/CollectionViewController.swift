import UIKit

class CollectionViewController: UICollectionViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
}

extension CollectionViewController {
    private func configure() {
        collectionView.backgroundColor = .systemGroupedBackground
        collectionView.showsHorizontalScrollIndicator = false
        navigationItem.backButtonDisplayMode = .minimal
        navigationItem.hidesSearchBarWhenScrolling = false
        #if !targetEnvironment(macCatalyst)
        collectionView.showsVerticalScrollIndicator = false
        #endif
    }
}
