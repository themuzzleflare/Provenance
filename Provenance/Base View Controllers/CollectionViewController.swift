import UIKit

class CollectionViewController: UICollectionViewController {
    // MARK: - Life Cycle
    
    override init(collectionViewLayout layout: UICollectionViewLayout) {
        super.init(collectionViewLayout: layout)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }
}

// MARK: - Configuration

private extension CollectionViewController {
    private func configure() {
        collectionView.backgroundColor = .systemGroupedBackground
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        navigationItem.backButtonDisplayMode = .minimal
        navigationItem.hidesSearchBarWhenScrolling = false
    }
}
