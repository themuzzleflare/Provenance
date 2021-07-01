import UIKit
import FLAnimatedImage
import TinyConstraints
import Rswift

final class CategoriesCVC: UIViewController {
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
    private let collectionRefreshControl = RefreshControl(frame: .zero)
    private let cellRegistration = CategoryCell { cell, indexPath, category in
        cell.category = category
    }

    private var apiKeyObserver: NSKeyValueObservation?
    private var noCategories: Bool = false
    private var categories: [CategoryResource] = [] {
        didSet {
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
    private var filteredCategoriesList: Category {
        Category(data: filteredCategories)
    }
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(collectionView)

        configureProperties()
        configureNavigation()
        configureSearch()
        configureRefreshControl()
        configureCollectionView()

        applySnapshot()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        collectionView.frame = view.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        fetchCategories()
    }
}

// MARK: - Configuration

private extension CategoriesCVC {
    private func configureProperties() {
        title = "Categories"
        definesPresentationContext = true

        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)

        apiKeyObserver = appDefaults.observe(\.apiKey, options: .new) { object, change in
            self.fetchCategories()
        }
    }
    
    private func configureNavigation() {
        navigationItem.title = "Loading"
        navigationItem.backBarButtonItem = UIBarButtonItem(image: R.image.trayFull())
        navigationItem.searchController = searchController
    }
    
    private func configureSearch() {
        searchController.searchBar.delegate = self
    }
    
    private func configureRefreshControl() {
        collectionRefreshControl.addTarget(self, action: #selector(refreshCategories), for: .valueChanged)
    }
    
    private func configureCollectionView() {
        collectionView.dataSource = dataSource
        collectionView.delegate = self
        collectionView.refreshControl = collectionRefreshControl
        collectionView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
}

// MARK: - Actions

private extension CategoriesCVC {
    @objc private func appMovedToForeground() {
        fetchCategories()
    }

    @objc private func refreshCategories() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.fetchCategories()
        }
    }

    private func makeDataSource() -> DataSource {
        DataSource(collectionView: collectionView) { collectionView, indexPath, category in
            collectionView.dequeueConfiguredReusableCell(using: self.cellRegistration, for: indexPath, item: category)
        }
    }

    private func applySnapshot(animate: Bool = false) {
        var snapshot = Snapshot()

        snapshot.appendSections([.main])
        snapshot.appendItems(filteredCategoriesList.data, toSection: .main)

        if snapshot.itemIdentifiers.isEmpty && categoriesError.isEmpty {
            if categories.isEmpty && !noCategories {
                collectionView.backgroundView = {
                    let view = UIView(frame: CGRect(x: collectionView.bounds.midX, y: collectionView.bounds.midY, width: collectionView.bounds.width, height: collectionView.bounds.height))

                    let loadingIndicator = FLAnimatedImageView()

                    loadingIndicator.animatedImage = upZapSpinTransparentBackground
                    loadingIndicator.width(100)
                    loadingIndicator.height(100)

                    view.addSubview(loadingIndicator)

                    loadingIndicator.center(in: view)

                    return view
                }()
            } else {
                collectionView.backgroundView = {
                    let view = UIView(frame: CGRect(x: collectionView.bounds.midX, y: collectionView.bounds.midY, width: collectionView.bounds.width, height: collectionView.bounds.height))

                    let icon = UIImageView(image: R.image.xmarkDiamond())

                    icon.tintColor = .secondaryLabel
                    icon.width(70)
                    icon.height(64)

                    let label = UILabel()

                    label.translatesAutoresizingMaskIntoConstraints = false
                    label.textAlignment = .center
                    label.textColor = .secondaryLabel
                    label.font = R.font.circularStdBook(size: 23)
                    label.text = "No Categories"

                    let vstack = UIStackView(arrangedSubviews: [icon, label])

                    vstack.axis = .vertical
                    vstack.alignment = .center
                    vstack.spacing = 10

                    view.addSubview(vstack)

                    vstack.edges(to: view, excluding: [.top, .bottom, .leading, .trailing], insets: .horizontal(16))
                    vstack.center(in: view)

                    return view
                }()
            }
        } else {
            if !categoriesError.isEmpty {
                collectionView.backgroundView = {
                    let view = UIView(frame: CGRect(x: collectionView.bounds.midX, y: collectionView.bounds.midY, width: collectionView.bounds.width, height: collectionView.bounds.height))

                    let label = UILabel()

                    view.addSubview(label)

                    label.edges(to: view, excluding: [.top, .bottom, .leading, .trailing], insets: .horizontal(16))
                    label.center(in: view)
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
        upApi.listCategories { result in
            switch result {
                case .success(let categories):
                    DispatchQueue.main.async {
                        self.categoriesError = ""
                        self.categories = categories

                        if self.navigationItem.title != "Categories" {
                            self.navigationItem.title = "Categories"
                        }
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.categoriesError = errorString(for: error)
                        self.categories = []

                        if self.navigationItem.title != "Error" {
                            self.navigationItem.title = "Error"
                        }
                    }
            }
        }
    }
}

// MARK: - UICollectionViewDelegate

extension CategoriesCVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)

        let vc = TransactionsByCategoryVC()
        
        vc.category = dataSource.itemIdentifier(for: indexPath)

        navigationController?.pushViewController(vc, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let category = dataSource.itemIdentifier(for: indexPath)?.attributes.name else {
            return nil
        }

        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            UIMenu(children: [
                UIAction(title: "Copy", image: R.image.docOnClipboard()) { action in
                    UIPasteboard.general.string = category
                }
            ])
        }
    }
}

// MARK: - UISearchBarDelegate

extension CategoriesCVC: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        applySnapshot(animate: true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        if !searchBar.text!.isEmpty {
            searchBar.text = ""
            applySnapshot(animate: true)
        }
    }
}
