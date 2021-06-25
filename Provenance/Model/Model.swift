import Foundation
import UIKit
import FLAnimatedImage
import Rswift

// MARK: - Application Metadata & Reusable Values

let appName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "Provenance"
let appCopyright = Bundle.main.infoDictionary?["NSHumanReadableCopyright"] as? String ?? "Copyright © 2021 Paul Tavitian"
let upApi = APIFacade()

var selectedBackgroundCellView: UIView {
    let view = UIView()
    view.backgroundColor = R.color.accentColour()
    return view
}

// MARK: - UICollectionView Layouts

func twoColumnGridLayout() -> UICollectionViewLayout {
    UICollectionViewCompositionalLayout { sectionIndex, layoutEnvironment in
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(100))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 2)
        group.interItemSpacing = .fixed(10)
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 10
        section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        return section
    }
}

func gridLayout() -> UICollectionViewLayout {
    let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.2), heightDimension: .fractionalHeight(1.0))
    let item = NSCollectionLayoutItem(layoutSize: itemSize)
    let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalWidth(0.2))
    let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
    let section = NSCollectionLayoutSection(group: group)
    let layout = UICollectionViewCompositionalLayout(section: section)
    return layout
}

// MARK: - GIF Stickers Array

private let stickerTwo = try! FLAnimatedImage(animatedGIFData: Data(contentsOf: Bundle.main.url(forResource: "StickerTwo", withExtension: "gif")!))
private let stickerThree = try! FLAnimatedImage(animatedGIFData: Data(contentsOf: Bundle.main.url(forResource: "StickerThree", withExtension: "gif")!))
private let stickerSix = try! FLAnimatedImage(animatedGIFData: Data(contentsOf: Bundle.main.url(forResource: "StickerSix", withExtension: "gif")!))
private let stickerSeven = try! FLAnimatedImage(animatedGIFData: Data(contentsOf: Bundle.main.url(forResource: "StickerSeven", withExtension: "gif")!))

let upLogoWhiteSunsetTransparentBackground = try! FLAnimatedImage(animatedGIFData: Data(contentsOf: Bundle.main.url(forResource: "up-logo-white-sunset-transparent-bg", withExtension: "gif")!))
let upLogoDrawMidnightYellowTransparentBackground = try! FLAnimatedImage(animatedGIFData: Data(contentsOf: Bundle.main.url(forResource: "up-logo-draw-midnight-yellow-transparent-bg", withExtension: "gif")!))
let upZapSpinTransparentBackground = try! FLAnimatedImage(animatedGIFData: Data(contentsOf: Bundle.main.url(forResource: "up-zap-spin-transparent-bg", withExtension: "gif")!))

let stickerGifs = [stickerTwo, stickerThree, stickerSix, stickerSeven]

// MARK: - Animated Application Logo

let upAnimation = UIImage.animatedImage(with: [
    R.image.upLogoSequence.first()!,
    R.image.upLogoSequence.second()!,
    R.image.upLogoSequence.third()!,
    R.image.upLogoSequence.fourth()!,
    R.image.upLogoSequence.fifth()!,
    R.image.upLogoSequence.sixth()!,
    R.image.upLogoSequence.seventh()!,
    R.image.upLogoSequence.eighth()!
], duration: 0.65)!
