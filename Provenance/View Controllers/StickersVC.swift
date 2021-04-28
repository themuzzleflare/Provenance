import UIKit

class StickersVC: CollectionViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
}

private extension StickersVC {
    private func configure() {
        title = "Stickers"
        navigationItem.title = "Stickers"
        collectionView.register(StickerCollectionViewCell.self, forCellWithReuseIdentifier: StickerCollectionViewCell.reuseIdentifier)
    }
}

extension StickersVC {
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return stickerGifs.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StickerCollectionViewCell.reuseIdentifier, for: indexPath) as! StickerCollectionViewCell
        cell.image = stickerGifs[indexPath.item]
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        navigationController?.pushViewController({let vc = StickerView();vc.image = stickerGifs[indexPath.item];return vc}(), animated: true)
    }
}
