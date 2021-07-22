import UIKit
import SwiftyBeaver

final class StickersVC: UIViewController {
    // MARK: - Properties

    private let collectionView = UICollectionView(frame: .zero, collectionViewLayout: gridLayout())

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        log.debug("viewDidLoad")
        view.addSubview(collectionView)
        configure()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        log.debug("viewDidLayoutSubviews")
        collectionView.frame = view.bounds
    }
}

// MARK: - Configuration

private extension StickersVC {
    private func configure() {
        log.verbose("configure")

        title = "Stickers"

        navigationItem.title = "Stickers"
        navigationItem.largeTitleDisplayMode = .never

        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(StickerCollectionViewCell.self, forCellWithReuseIdentifier: StickerCollectionViewCell.reuseIdentifier)
        collectionView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        collectionView.backgroundColor = .systemGroupedBackground
    }
}

// MARK: - UICollectionViewDataSource

extension StickersVC: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return stickerGifs.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StickerCollectionViewCell.reuseIdentifier, for: indexPath) as? StickerCollectionViewCell else {
            fatalError("Unable to dequeue reusable cell with identifier: \(StickerCollectionViewCell.reuseIdentifier)")
        }
        
        cell.image = stickerGifs[indexPath.item]

        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension StickersVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        log.debug("collectionView(didSelectItemAt indexPath: \(indexPath))")

        if let image = stickerGifs[indexPath.item] {
            navigationController?.pushViewController(StickerView(image: image), animated: true)
        }
    }
}
