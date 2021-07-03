import UIKit
import IGListKit

final class TransactionsSC: ListSectionController {
    private var model: SortedTransactions!

    override init() {
        super.init()
        
        supplementaryViewSource = self
    }

    override func numberOfItems() -> Int {
        model.transactions.count
    }

    override func sizeForItem(at index: Int) -> CGSize {
        CGSize(width: collectionContext!.containerSize.width, height: 90)
    }
    
    override func cellForItem(at index: Int) -> UICollectionViewCell {
        let cell = collectionContext?.dequeueReusableCell(
            of: TransactionCollectionViewCell.self,
            for: self,
            at: index
        ) as! TransactionCollectionViewCell

        cell.transaction = model.transactions[index]

        return cell

    }

    override func didUpdate(to object: Any) {
        self.model = object as? SortedTransactions
    }

    override func didSelectItem(at index: Int) {
        collectionContext?.deselectItem(at: index, sectionController: self, animated: true)
        
        viewController?.navigationController?.pushViewController(TransactionDetailCVC(transaction: model.transactions[index]), animated: true)
    }
}

// MARK: - ListSupplementaryViewSource

extension TransactionsSC: ListSupplementaryViewSource {
    func supportedElementKinds() -> [String] {
        [UICollectionView.elementKindSectionHeader]
    }

    func viewForSupplementaryElement(ofKind elementKind: String, at index: Int) -> UICollectionReusableView {
        let view = collectionContext?.dequeueReusableSupplementaryView(
            ofKind: UICollectionView.elementKindSectionHeader,
            for: self,
            class: TransactionsHeaderView.self,
            at: index
        ) as! TransactionsHeaderView
        
        view.date = model.transactions[0].attributes.creationDayMonthYear

        return view
    }
    
    func sizeForSupplementaryView(ofKind elementKind: String, at index: Int) -> CGSize {
        CGSize(width: collectionContext!.containerSize.width, height: 40)
    }
}
