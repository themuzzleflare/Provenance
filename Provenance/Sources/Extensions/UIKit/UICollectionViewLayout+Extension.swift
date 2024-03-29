import UIKit

extension UICollectionViewLayout {
  static var flowLayout: UICollectionViewLayout {
    return UICollectionViewFlowLayout()
  }

  static var sectionHeadersPinned: UICollectionViewLayout {
    let layout = UICollectionViewFlowLayout()
    layout.sectionHeadersPinToVisibleBounds = true
    return layout
  }

  static var twoColumnGrid: UICollectionViewLayout {
    return UICollectionViewCompositionalLayout { (_, _) in
      let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                            heightDimension: .fractionalHeight(1.0))
      let item = NSCollectionLayoutItem(layoutSize: itemSize)
      let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                             heightDimension: .absolute(100))
      let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 2)
      group.interItemSpacing = .fixed(10)
      let section = NSCollectionLayoutSection(group: group)
      section.interGroupSpacing = 10
      section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
      return section
    }
  }

  static var grid: UICollectionViewLayout {
    let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.2),
                                          heightDimension: .fractionalHeight(1.0))
    let item = NSCollectionLayoutItem(layoutSize: itemSize)
    let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                           heightDimension: .fractionalWidth(0.2))
    let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
    let section = NSCollectionLayoutSection(group: group)
    let layout = UICollectionViewCompositionalLayout(section: section)
    return layout
  }
}
