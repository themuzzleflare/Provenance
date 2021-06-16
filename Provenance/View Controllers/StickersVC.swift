import UIKit

class StickersVC: CollectionViewController {
        // MARK: - View Life Cycle

    override init(collectionViewLayout layout: UICollectionViewLayout) {
        super.init(collectionViewLayout: layout)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }
}

    // MARK: - Configuration

private extension StickersVC {
    private func configure() {
        title = "Stickers"
        navigationItem.title = "Stickers"
        collectionView.register(StickerCollectionViewCell.self, forCellWithReuseIdentifier: StickerCollectionViewCell.reuseIdentifier)
    }
}

    // MARK: - UICollectionViewDataSource

extension StickersVC {
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        stickerGifs.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StickerCollectionViewCell.reuseIdentifier, for: indexPath) as! StickerCollectionViewCell
        cell.image = stickerGifs[indexPath.item]
        return cell
    }
}

    // MARK: - UICollectionViewDelegate

extension StickersVC {
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        navigationController?.pushViewController({let vc = StickerView();vc.image = stickerGifs[indexPath.item];return vc}(), animated: true)
    }
}
