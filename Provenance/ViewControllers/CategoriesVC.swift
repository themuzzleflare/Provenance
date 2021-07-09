import UIKit
import FLAnimatedImage
import SwiftyBeaver
import TinyConstraints
import Rswift

final class CategoriesVC: UIViewController {
    // MARK: - Properties

    private enum Section {
        case main
    }

    private typealias DataSource = UICollectionViewDiffableDataSource<Section, CategoryResource>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, CategoryResource>
    private typealias CategoryCell = UICollectionView.CellRegistration<CategoryCollectionViewCell, CategoryResource>

    private lazy var dataSource = makeDataSource()

    private let collectionView = UICollectionView(frame: .zero, collectionViewLayout: twoColumnGridLayout())

    private let searchController = SearchController(searchResultsController: nil)

    private let collectionRefreshControl: UIRefreshControl = {
        let rc = UIRefreshControl()
        rc.addTarget(self, action: #selector(refreshCategories), for: .valueChanged)
        return rc
    }()

    private let cellRegistration = CategoryCell { cell, indexPath, category in
        cell.category = category
    }

    private weak var apiKeyObserver: NSKeyValueObservation?

    private var noCategories: Bool = false

    private var categories: [CategoryResource] = [] {
        didSet {
            log.info("didSet categories: \(categories.count.description)")

            noCategories = categories.isEmpty
            applySnapshot()
            collectionView.refreshControl?.endRefreshing()
            searchController.searchBar.placeholder = "Search \(categories.count.description) \(categories.count == 1 ? "Category" : "Categories")"
        }
    }

    private var categoriesError: String = ""

    private var filteredCategories: [CategoryResource] {
        categories.filter { category in
            searchController.searchBar.text!.isEmpty || category.attributes.name.localizedStandardContains(searchController.searchBar.text!)
        }
    }
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        log.debug("viewDidLoad")
        view.addSubview(collectionView)
        configureProperties()
        configureNavigation()
        configureSearch()
        configureCollectionView()
        applySnapshot()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        log.debug("viewDidLayoutSubviews")
        collectionView.frame = view.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        log.debug("viewWillAppear(animated: \(animated.description))")
        fetchCategories()
    }
}

// MARK: - Configuration

private extension CategoriesVC {
    private func configureProperties() {
        log.verbose("configureProperties")

        title = "Categories"
        definesPresentationContext = true

        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)

        apiKeyObserver = appDefaults.observe(\.apiKey, options: .new) { [self] object, change in
            fetchCategories()
        }
    }
    
    private func configureNavigation() {
        log.verbose("configureNavigation")

        navigationItem.title = "Loading"
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.backBarButtonItem = UIBarButtonItem(image: R.image.trayFull())
        navigationItem.searchController = searchController
    }
    
    private func configureSearch() {
        log.verbose("configureSearch")

        searchController.searchBar.delegate = self
    }
    
    private func configureCollectionView() {
        log.verbose("configureCollectionView")

        collectionView.dataSource = dataSource
        collectionView.delegate = self
        collectionView.refreshControl = collectionRefreshControl
        collectionView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        collectionView.backgroundColor = .systemGroupedBackground
    }
}

// MARK: - Actions

private extension CategoriesVC {
    @objc private func appMovedToForeground() {
        log.verbose("appMovedToForeground")

        fetchCategories()
    }

    @objc private func refreshCategories() {
        log.verbose("refreshCategories")

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
            fetchCategories()
        }
    }

    private func makeDataSource() -> DataSource {
        log.verbose("makeDataSource")

        return DataSource(collectionView: collectionView) { [self] collectionView, indexPath, category in
            collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: category)
        }
    }

    private func applySnapshot(animate: Bool = true) {
        log.verbose("applySnapshot(animate: \(animate.description))")

        var snapshot = Snapshot()

        snapshot.appendSections([.main])
        snapshot.appendItems(filteredCategories, toSection: .main)

        if snapshot.itemIdentifiers.isEmpty && categoriesError.isEmpty {
            if categories.isEmpty && !noCategories {
                collectionView.backgroundView = {
                    let view = UIView(frame: collectionView.bounds)

                    let loadingIndicator = FLAnimatedImageView()

                    view.addSubview(loadingIndicator)

                    loadingIndicator.centerInSuperview()
                    loadingIndicator.width(100)
                    loadingIndicator.height(100)
                    loadingIndicator.animatedImage = upZapSpinTransparentBackground

                    return view
                }()
            } else {
                collectionView.backgroundView = {
                    let view = UIView(frame: collectionView.bounds)

                    let icon = UIImageView(image: R.image.xmarkDiamond())

                    icon.width(70)
                    icon.height(64)
                    icon.tintColor = .secondaryLabel

                    let label = UILabel()

                    label.translatesAutoresizingMaskIntoConstraints = false
                    label.textAlignment = .center
                    label.textColor = .secondaryLabel
                    label.font = R.font.circularStdBook(size: 23)
                    label.text = "No Categories"

                    let vStack = UIStackView(arrangedSubviews: [icon, label])

                    view.addSubview(vStack)

                    vStack.horizontalToSuperview(insets: .horizontal(16))
                    vStack.centerInSuperview()
                    vStack.axis = .vertical
                    vStack.alignment = .center
                    vStack.spacing = 10

                    return view
                }()
            }
        } else {
            if !categoriesError.isEmpty {
                collectionView.backgroundView = {
                    let view = UIView(frame: collectionView.bounds)

                    let label = UILabel()

                    view.addSubview(label)

                    label.horizontalToSuperview(insets: .horizontal(16))
                    label.centerInSuperview()
                    label.textAlignment = .center
                    label.textColor = .secondaryLabel
                    label.font = R.font.circularStdBook(size: UIFont.labelFontSize)
                    label.numberOfLines = 0
                    label.text = categoriesError

                    return view
                }()
            } else {
                if collectionView.backgroundView != nil {
                    collectionView.backgroundView = nil
                }
            }
        }

        dataSource.apply(snapshot, animatingDifferences: animate)
    }

    private func fetchCategories() {
        log.verbose("fetchCategories")

        if #available(iOS 15.0, *) {
            async {
                do {
                    let categories = try await Up.listCategories()
                    
                    display(categories)
                } catch {
                    display(error as! NetworkError)
                }
            }
        } else {
            Up.listCategories { [self] result in
                DispatchQueue.main.async {
                    switch result {
                        case .success(let categories):
                            display(categories)
                        case .failure(let error):
                            display(error)
                    }
                }
            }
        }
    }

    private func display(_ categories: [CategoryResource]) {
        log.verbose("display(categories: \(categories.count.description))")

        categoriesError = ""
        self.categories = categories

        if navigationItem.title != "Categories" {
            navigationItem.title = "Categories"
        }
    }

    private func display(_ error: NetworkError) {
        log.verbose("display(error: \(errorString(for: error)))")

        categoriesError = errorString(for: error)
        categories = []

        if navigationItem.title != "Error" {
            navigationItem.title = "Error"
        }
    }
}

// MARK: - UICollectionViewDelegate

extension CategoriesVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        log.debug("collectionView(didSelectItemAt indexPath: \(indexPath))")

        collectionView.deselectItem(at: indexPath, animated: true)

        if let category = dataSource.itemIdentifier(for: indexPath) {
            navigationController?.pushViewController(TransactionsByCategoryVC(category: category), animated: true)
        }
    }

    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let category = dataSource.itemIdentifier(for: indexPath)?.attributes.name else {
            return nil
        }

        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            UIMenu(children: [
                UIAction(title: "Copy", image: R.image.docOnClipboard()) { _ in
                    UIPasteboard.general.string = category
                }
            ])
        }
    }
}

// MARK: - UISearchBarDelegate

extension CategoriesVC: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        log.debug("searchBar(textDidChange: \(searchText))")

        applySnapshot(animate: true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        log.debug("searchBarCancelButtonClicked")

        if !searchBar.text!.isEmpty {
            searchBar.text = ""
            applySnapshot(animate: true)
        }
    }
}
