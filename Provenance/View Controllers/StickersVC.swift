import UIKit

final class StickersVC: UIViewController {
    // MARK: - Properties

    private let collectionView = UICollectionView(frame: .zero, collectionViewLayout: gridLayout())

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(collectionView)

        configure()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        collectionView.frame = view.bounds
    }
}

// MARK: - Configuration

private extension StickersVC {
    private func configure() {
        title = "Stickers"

        navigationItem.title = "Stickers"

        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(StickerCollectionViewCell.self, forCellWithReuseIdentifier: StickerCollectionViewCell.reuseIdentifier)
        collectionView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
}

// MARK: - UICollectionViewDataSource

extension StickersVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        stickerGifs.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StickerCollectionViewCell.reuseIdentifier, for: indexPath) as! StickerCollectionViewCell
        
        cell.image = stickerGifs[indexPath.item]

        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension StickersVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let vc = StickerView()

        vc.image = stickerGifs[indexPath.item]

        navigationController?.pushViewController(vc, animated: true)
    }
}
