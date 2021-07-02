import UIKit
import IGListKit
import FLAnimatedImage
import MarqueeLabel
import TinyConstraints
import Rswift

final class TransactionDetailCVC: UIViewController {
    // MARK: - Properties

    private var transaction: TransactionResource {
        didSet {
            upApi.retrieveAccount(for: transaction.relationships.account.data.id) { result in
                switch result {
                    case .success(let account):
                        DispatchQueue.main.async {
                            self.account = account
                        }
                    case .failure:
                        break
                }
            }

            if let tAccount = transaction.relationships.transferAccount.data {
                upApi.retrieveAccount(for: tAccount.id) { result in
                    switch result {
                        case .success(let account):
                            DispatchQueue.main.async {
                                self.transferAccount = account
                            }
                        case .failure:
                            break
                    }
                }
            }

            if let pCategory = transaction.relationships.parentCategory.data {
                upApi.retrieveCategory(for: pCategory.id) { result in
                    switch result {
                        case .success(let category):
                            DispatchQueue.main.async {
                                self.parentCategory = category
                            }
                        case .failure:
                            break
                    }
                }
            }

            if let category = transaction.relationships.category.data {
                upApi.retrieveCategory(for: category.id) { result in
                    switch result {
                        case .success(let category):
                            DispatchQueue.main.async {
                                self.category = category
                            }
                        case .failure:
                            break
                    }
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
                transactionUpdate(animate: false)
                collectionView.refreshControl?.endRefreshing()
                configureNavigation()
            }
        }
    }

    private lazy var adapter = ListAdapter(updater: ListAdapterUpdater(), viewController: self)

    private let collectionRefreshControl = RefreshControl(frame: .zero)
    private let scrollingTitle = MarqueeLabel()
    private let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())

    private var dateStyleObserver: NSKeyValueObservation?
    private var sections: [Section] = []
    private var filteredSections: [Section] {
        sections.filter { section in
            !section.detailAttributes.allSatisfy { attribute in
                attribute.value.isEmpty || (attribute.key == "Tags" && attribute.value == "0")
            }
        }.map { section in
            Section(title: section.title, detailAttributes: section.detailAttributes.filter { attribute in
                !attribute.value.isEmpty
            })
        }
    }
    private var account: AccountResource?
    private var transferAccount: AccountResource?
    private var parentCategory: CategoryResource?
    private var category: CategoryResource?
    private var holdTransValue: String {
        switch transaction.attributes.holdInfo {
            case nil:
                return ""
            default:
                switch transaction.attributes.holdInfo!.amount.value {
                    case transaction.attributes.amount.value:
                        return ""
                    default:
                        return transaction.attributes.holdInfo!.amount.valueLong
                }
        }
    }
    private var holdForeignTransValue: String {
        switch transaction.attributes.holdInfo?.foreignAmount {
            case nil:
                return ""
            default:
                switch transaction.attributes.holdInfo!.foreignAmount!.value {
                    case transaction.attributes.foreignAmount!.value:
                        return ""
                    default:
                        return transaction.attributes.holdInfo!.foreignAmount!.valueLong
                }
        }
    }
    private var foreignTransValue: String {
        switch transaction.attributes.foreignAmount {
            case nil:
                return ""
            default:
                return transaction.attributes.foreignAmount!.valueLong
        }
    }

    // MARK: - Life Cycle

    init(transaction: TransactionResource) {
        self.transaction = transaction

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(collectionView)

        adapter.collectionView = collectionView
        adapter.dataSource = self
        adapter.collectionViewDelegate = self

        configureProperties()
        configureCollectionView()
        configureScrollingTitle()
        configureRefreshControl()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        collectionView.frame = view.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        fetchTransaction()
    }
}

// MARK: - Configuration

private extension TransactionDetailCVC {
    private func configureProperties() {
        title = "Transaction Details"

        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)

        dateStyleObserver = appDefaults.observe(\.dateStyle, options: .new) { [self] object, change in
            adapter.reloadData()
        }
    }

    private func configureCollectionView() {
        collectionView.refreshControl = collectionRefreshControl
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .systemGroupedBackground
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
    }

    private func configureScrollingTitle() {
        scrollingTitle.translatesAutoresizingMaskIntoConstraints = false
        scrollingTitle.speed = .rate(65)
        scrollingTitle.fadeLength = 20
        scrollingTitle.textAlignment = .center
        scrollingTitle.font = .boldSystemFont(ofSize: UIFont.labelFontSize)
        scrollingTitle.text = transaction.attributes.description
    }

    private func configureRefreshControl() {
        collectionRefreshControl.addTarget(self, action: #selector(refreshTransaction), for: .valueChanged)
    }

    private func configureNavigation() {
        navigationItem.title = transaction.attributes.description
        navigationItem.titleView = scrollingTitle
        navigationItem.setRightBarButton(UIBarButtonItem(image: transaction.attributes.statusIcon, style: .plain, target: self, action: #selector(openStatusIconHelpView)), animated: false)
        navigationItem.rightBarButtonItem?.tintColor = transaction.attributes.isSettled ? .systemGreen : .systemYellow
    }
}

// MARK: - Actions

private extension TransactionDetailCVC {
    @objc private func appMovedToForeground() {
        fetchTransaction()
    }

    @objc private func openStatusIconHelpView() {
        present(NavigationController(rootViewController: StatusIconHelpView()), animated: true)
    }

    @objc private func refreshTransaction() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
            fetchTransaction()
        }
    }

    private func transactionUpdate(animate: Bool = false) {
        sections = [
            Section(title: "Section 1", detailAttributes: [
                DetailAttribute(
                    key: "Status",
                    value: transaction.attributes.statusString
                ),
                DetailAttribute(
                    key: "Account",
                    value: account?.attributes.displayName ?? ""
                ),
                DetailAttribute(
                    key: "Transfer Account",
                    value: transferAccount?.attributes.displayName ?? ""
                )
            ]),
            Section(title: "Section 2", detailAttributes: [
                DetailAttribute(
                    key: "Description",
                    value: transaction.attributes.description
                ),
                DetailAttribute(
                    key: "Raw Text",
                    value: transaction.attributes.rawText ?? ""
                ),
                DetailAttribute(
                    key: "Message",
                    value: transaction.attributes.message ?? ""
                )
            ]),
            Section(title: "Section 3", detailAttributes: [
                DetailAttribute(
                    key: "Hold \(transaction.attributes.holdInfo?.amount.transactionType ?? "")",
                    value: holdTransValue
                ),
                DetailAttribute(
                    key: "Hold Foreign \(transaction.attributes.holdInfo?.foreignAmount?.transactionType ?? "")",
                    value: holdForeignTransValue
                ),
                DetailAttribute(
                    key: "Foreign \(transaction.attributes.foreignAmount?.transactionType ?? "")",
                    value: foreignTransValue
                ),
                DetailAttribute(
                    key: transaction.attributes.amount.transactionType,
                    value: transaction.attributes.amount.valueLong
                )
            ]),
            Section(title: "Section 4", detailAttributes: [
                DetailAttribute(
                    key: "Creation Date",
                    value: transaction.attributes.creationDate
                ),
                DetailAttribute(
                    key: "Settlement Date",
                    value: transaction.attributes.settlementDate ?? ""
                )
            ]),
            Section(title: "Section 5", detailAttributes: [
                DetailAttribute(
                    key: "Parent Category",
                    value: parentCategory?.attributes.name ?? ""
                ),
                DetailAttribute(
                    key: "Category",
                    value: category?.attributes.name ?? ""
                )
            ]),
            Section(title: "Section 6", detailAttributes: [
                DetailAttribute(
                    key: "Tags",
                    value: transaction.relationships.tags.data.count.description
                )
            ])
        ]

        adapter.performUpdates(animated: animate)
    }

    private func fetchTransaction() {
        if #available(iOS 15.0, *) {
            async {
                do {
                    let transaction = try await Up.retrieveTransaction(for: transaction)
                    display(transaction)
                } catch {
                    display(error as! NetworkError)
                }
            }
        } else {
            upApi.retrieveTransaction(for: transaction) { [self] result in
                DispatchQueue.main.async {
                    switch result {
                        case .success(let transaction):
                            display(transaction)
                        case .failure(let error):
                            display(error)
                    }
                }
            }
        }
    }

    private func display(_ transaction: TransactionResource) {
        self.transaction = transaction
    }

    private func display(_ error: NetworkError) {
        collectionView.refreshControl?.endRefreshing()
        print(errorString(for: error))
    }
}

extension TransactionDetailCVC: ListAdapterDataSource {
    func objects(for listAdapter: ListAdapter) -> [ListDiffable] {
        filteredSections
    }

    func listAdapter(_ listAdapter: ListAdapter, sectionControllerFor object: Any) -> ListSectionController {
        let controller = TransactionDetailSC()
        
        controller.transaction = transaction
        controller.account = account
        controller.transferAccount = transferAccount
        controller.parentCategory = parentCategory
        controller.category = category

        return controller
    }

    func emptyView(for listAdapter: ListAdapter) -> UIView? {
        let view = UIView(frame: collectionView.bounds)

        let loadingIndicator = FLAnimatedImageView()

        view.addSubview(loadingIndicator)
        
        loadingIndicator.centerInSuperview()
        loadingIndicator.width(100)
        loadingIndicator.height(100)
        loadingIndicator.animatedImage = upZapSpinTransparentBackground

        return view
    }
}

extension TransactionDetailCVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let attribute = filteredSections[indexPath.section].detailAttributes[indexPath.item]

        switch attribute.key {
            case "Tags":
                return nil
            default:
                return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
                    UIMenu(children: [
                        UIAction(title: "Copy \(attribute.key)", image: R.image.docOnClipboard()) { _ in
                            UIPasteboard.general.string = attribute.value
                        }
                    ])
                }
        }
    }
}
