import UIKit
import IGListKit
import Rswift

final class TransactionDetailSC: ListSectionController {
    private var model: Section!

    private var transaction: TransactionResource

    private var account: AccountResource?
    private var transferAccount: AccountResource?
    private var parentCategory: CategoryResource?
    private var category: CategoryResource?

    required init(transaction: TransactionResource, account: AccountResource? = nil, transferAccount: AccountResource? = nil, parentCategory: CategoryResource? = nil, category: CategoryResource? = nil) {
        self.transaction = transaction

        self.account = account
        self.transferAccount = transferAccount
        self.parentCategory = parentCategory
        self.category = category
        
        super.init()
        
        inset = UIEdgeInsets(top: 0, left: 0, bottom: 40, right: 0)
    }

    override func numberOfItems() -> Int {
        model.detailAttributes.count
    }

    override func sizeForItem(at index: Int) -> CGSize {
        CGSize(width: collectionContext!.containerSize.width, height: 100)
    }

    override func cellForItem(at index: Int) -> UICollectionViewCell {
        let cell = collectionContext?.dequeueReusableCell(
            of: AttributeCollectionViewCell.self,
            for: self,
            at: index
        ) as! AttributeCollectionViewCell

        let attribute = model.detailAttributes[index]

        cell.leftLabel.text = attribute.key
        cell.rightLabel.font = attribute.key == "Raw Text" ? R.font.sfMonoRegular(size: UIFont.labelFontSize)! : R.font.circularStdBook(size: UIFont.labelFontSize)!
        cell.rightLabel.text = attribute.value
        
        return cell
    }

    override func didUpdate(to object: Any) {
        self.model = object as? Section
    }

    override func didSelectItem(at index: Int) {
        let attribute = model.detailAttributes[index]

        collectionContext?.deselectItem(at: index, sectionController: self, animated: true)

        switch attribute.key {
            case "Account":
                viewController?.navigationController?.pushViewController(TransactionsByAccountVC(account: account!), animated: true)
            case "Transfer Account":
                viewController?.navigationController?.pushViewController(TransactionsByAccountVC(account: transferAccount!), animated: true)
            case "Parent Category":
                viewController?.navigationController?.pushViewController(TransactionsByCategoryVC(category: parentCategory!), animated: true)
            case "Category":
                viewController?.navigationController?.pushViewController(TransactionsByCategoryVC(category: category!), animated: true)
            case "Tags":
                viewController?.navigationController?.pushViewController(TagsCVC(transaction: transaction), animated: true)
            default:
                break
        }
    }
}
