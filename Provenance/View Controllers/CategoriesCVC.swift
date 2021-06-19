import UIKit
import Alamofire
import TinyConstraints
import Rswift

final class CategoriesCVC: CollectionViewController {
    // MARK: - Properties

    private enum Section {
        case main
    }

    private typealias DataSource = UICollectionViewDiffableDataSource<Section, CategoryResource>
    private typealias CategoryCell = UICollectionView.CellRegistration<CategoryCollectionViewCell, CategoryResource>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, CategoryResource>

    private lazy var dataSource = makeDataSource()

    private let searchController = SearchController(searchResultsController: nil)
    private let refreshControl = RefreshControl(frame: .zero)
    private let cellRegistration = CategoryCell { cell, indexPath, category in
        cell.category = category
    }

    private var apiKeyObserver: NSKeyValueObservation?
    private var categoriesStatusCode: Int = 0
    private var categories: [CategoryResource] = [] {
        didSet {
            applySnapshot()
            collectionView.refreshControl?.endRefreshing()
            searchController.searchBar.placeholder = "Search \(categories.count.description) \(categories.count == 1 ? "Category" : "Categories")"
        }
    }
    private var categoriesErrorResponse: [ErrorObject] = []
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
    
    override init(collectionViewLayout layout: UICollectionViewLayout) {
        super.init(collectionViewLayout: layout)
        configureProperties()
        configureNavigation()
        configureSearch()
        configureRefreshControl()
        configureCollectionView()
        applySnapshot()
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
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
        navigationItem.backBarButtonItem = UIBarButtonItem(image: R.image.arrowUpArrowDownCircle())
        navigationItem.searchController = searchController
    }
    
    private func configureSearch() {
        searchController.searchBar.delegate = self
    }
    
    private func configureRefreshControl() {
        refreshControl.addTarget(self, action: #selector(refreshCategories), for: .valueChanged)
    }
    
    private func configureCollectionView() {
        collectionView.refreshControl = refreshControl
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
        if snapshot.itemIdentifiers.isEmpty && categoriesError.isEmpty && categoriesErrorResponse.isEmpty {
            if categories.isEmpty && categoriesStatusCode == 0 {
                collectionView.backgroundView = {
                    let view = UIView(frame: CGRect(x: collectionView.bounds.midX, y: collectionView.bounds.midY, width: collectionView.bounds.width, height: collectionView.bounds.height))
                    let loadingIndicator = ActivityIndicator(style: .medium)
                    view.addSubview(loadingIndicator)
                    loadingIndicator.center(in: view)
                    loadingIndicator.startAnimating()
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
            } else if !categoriesErrorResponse.isEmpty {
                collectionView.backgroundView = {
                    let view = UIView(frame: CGRect(x: collectionView.bounds.midX, y: collectionView.bounds.midY, width: collectionView.bounds.width, height: collectionView.bounds.height))
                    let titleLabel = UILabel()
                    let detailLabel = UILabel()
                    let verticalStack = UIStackView()
                    view.addSubview(verticalStack)
                    titleLabel.translatesAutoresizingMaskIntoConstraints = false
                    titleLabel.textAlignment = .center
                    titleLabel.textColor = .systemRed
                    titleLabel.font = R.font.circularStdBold(size: UIFont.labelFontSize)
                    titleLabel.numberOfLines = 0
                    titleLabel.text = categoriesErrorResponse.first?.title
                    detailLabel.translatesAutoresizingMaskIntoConstraints = false
                    detailLabel.textAlignment = .center
                    detailLabel.textColor = .secondaryLabel
                    detailLabel.font = R.font.circularStdBook(size: UIFont.labelFontSize)
                    detailLabel.numberOfLines = 0
                    detailLabel.text = categoriesErrorResponse.first?.detail
                    verticalStack.addArrangedSubview(titleLabel)
                    verticalStack.addArrangedSubview(detailLabel)
                    verticalStack.edges(to: view, excluding: [.top, .bottom, .leading, .trailing], insets: .horizontal(16))
                    verticalStack.center(in: view)
                    verticalStack.axis = .vertical
                    verticalStack.alignment = .center
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
        AF.request(UpAPI.Categories().listCategories, method: .get, headers: [acceptJsonHeader, authorisationHeader]).responseJSON { response in
            self.categoriesStatusCode = response.response?.statusCode ?? 0
            switch response.result {
                case .success:
                    if let decodedResponse = try? JSONDecoder().decode(Category.self, from: response.data!) {
                        self.categoriesError = ""
                        self.categoriesErrorResponse = []
                        self.categories = decodedResponse.data
                        if self.navigationItem.title != "Categories" {
                            self.navigationItem.title = "Categories"
                        }
                    } else if let decodedResponse = try? JSONDecoder().decode(ErrorResponse.self, from: response.data!) {
                        self.categoriesErrorResponse = decodedResponse.errors
                        self.categoriesError = ""
                        self.categories = []
                        if self.navigationItem.title != "Error" {
                            self.navigationItem.title = "Error"
                        }
                    } else {
                        self.categoriesError = "JSON Decoding Failed!"
                        self.categoriesErrorResponse = []
                        self.categories = []
                        if self.navigationItem.title != "Error" {
                            self.navigationItem.title = "Error"
                        }
                    }
                case .failure:
                    self.categoriesError = response.error?.localizedDescription ?? "Unknown Error!"
                    self.categoriesErrorResponse = []
                    self.categories = []
                    if self.navigationItem.title != "Error" {
                        self.navigationItem.title = "Error"
                    }
            }
        }
    }
}

// MARK: - UICollectionViewDelegate

extension CategoriesCVC {
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        navigationController?.pushViewController({let vc = TransactionsByCategoryVC(style: .insetGrouped);vc.category = dataSource.itemIdentifier(for: indexPath);return vc}(), animated: true)
    }

    override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            UIMenu(children: [
                UIAction(title: "Copy", image: R.image.docOnClipboard()) { action in
                    UIPasteboard.general.string = self.dataSource.itemIdentifier(for: indexPath)!.attributes.name
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
