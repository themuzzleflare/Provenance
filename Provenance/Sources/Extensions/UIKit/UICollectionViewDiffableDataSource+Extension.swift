import UIKit

extension UICollectionViewDiffableDataSource {
  convenience init(collectionView: UICollectionView, cellProvider: @escaping UICollectionViewDiffableDataSource<SectionIdentifierType, ItemIdentifierType>.CellProvider, supplementaryViewProvider: UICollectionViewDiffableDataSource<SectionIdentifierType, ItemIdentifierType>.SupplementaryViewProvider?) {
    self.init(collectionView: collectionView, cellProvider: cellProvider)
    self.supplementaryViewProvider = supplementaryViewProvider
  }
}
