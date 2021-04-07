import UIKit
import Alamofire
import Rswift

class CategoriesCVC: CollectionViewController {
    let searchController = UISearchController(searchResultsController: nil)
    let refreshControl = RefreshControl(frame: .zero)
    
    private var categoriesStatusCode: Int = 0
    private var categories: [CategoryResource] = []
    private var categoriesErrorResponse: [ErrorObject] = []
    private var categoriesError: String = ""
    
    private var filteredCategories: [CategoryResource] {
        categories.filter { category in
            searchController.searchBar.text!.isEmpty || category.attributes.name.localizedStandardContains(searchController.searchBar.text!)
        }
    }
    
    private var filteredCategoriesList: Category {
        return Category(data: filteredCategories)
    }
    
    private enum Section: CaseIterable {
        case main
    }
    
    private typealias DataSource = UICollectionViewDiffableDataSource<Section, CategoryResource>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, CategoryResource>
    
    private lazy var dataSource = makeDataSource()
    
    private func makeDataSource() -> DataSource {
        return DataSource(
            collectionView: collectionView,
            cellProvider: {  collectionView, indexPath, category in
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CategoryCollectionViewCell.reuseIdentifier, for: indexPath) as! CategoryCollectionViewCell
                
                cell.category = category
                
                return cell
            }
        )
    }
    
    private func applySnapshot(animate: Bool = true) {
        var snapshot = Snapshot()
        
        snapshot.appendSections(Section.allCases)
        
        snapshot.appendItems(filteredCategoriesList.data, toSection: .main)
        
        if snapshot.itemIdentifiers.isEmpty && categoriesError.isEmpty && categoriesErrorResponse.isEmpty  {
            if categories.isEmpty && categoriesStatusCode == 0 {
                collectionView.backgroundView = {
                    let view = UIView()
                    
                    let loadingIndicator = ActivityIndicator(style: .medium)
                    view.addSubview(loadingIndicator)
                    
                    loadingIndicator.center(in: view)
                    
                    loadingIndicator.startAnimating()
                    
                    return view
                }()
            } else {
                collectionView.backgroundView = {
                    let view = UIView()
                    
                    let label = UILabel()
                    view.addSubview(label)
                    
                    label.center(in: view)
                    
                    label.textAlignment = .center
                    label.textColor = .label
                    label.font = R.font.circularStdBook(size: UIFont.labelFontSize)
                    label.numberOfLines = 0
                    label.text = "No Categories"
                    
                    return view
                }()
            }
        } else {
            if !categoriesError.isEmpty {
                collectionView.backgroundView = {
                    let view = UIView()
                    
                    let label = UILabel()
                    view.addSubview(label)
                    
                    label.edges(to: view, excluding: [.top, .bottom, .leading, .trailing], insets: .horizontal(16))
                    label.center(in: view)
                    
                    label.textAlignment = .center
                    label.textColor = .label
                    label.font = R.font.circularStdBook(size: UIFont.labelFontSize)
                    label.numberOfLines = 0
                    label.text = categoriesError
                    
                    return view
                }()
            } else if !categoriesErrorResponse.isEmpty {
                collectionView.backgroundView = {
                    let view = UIView()
                    
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
                    detailLabel.textColor = .label
                    detailLabel.font = R.font.circularStdBook(size: UIFont.labelFontSize)
                    detailLabel.numberOfLines = 0
                    detailLabel.text = categoriesErrorResponse.first?.detail
                    
                    verticalStack.addArrangedSubview(titleLabel)
                    verticalStack.addArrangedSubview(detailLabel)
                    
                    verticalStack.edges(to: view, excluding: [.top, .bottom, .leading, .trailing], insets: .horizontal(16))
                    verticalStack.center(in: view)
                    
                    verticalStack.axis = .vertical
                    verticalStack.alignment = .center
                    verticalStack.distribution = .fill
                    
                    return view
                }()
            } else {
                collectionView.backgroundView = nil
            }
        }
        
        dataSource.apply(snapshot, animatingDifferences: animate)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureProperties()
        configureNavigation()
        configureSearch()
        configureRefreshControl()
        configureCollectionView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        applySnapshot()
        
        fetchCategories()
    }
    
    @objc private func refreshCategories() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.fetchCategories()
        }
    }
    
    private func configureProperties() {
        title = "Categories"
        definesPresentationContext = true
    }
    
    private func configureNavigation() {
        navigationItem.title = "Loading"
        navigationItem.backBarButtonItem = UIBarButtonItem(image: R.image.arrowUpArrowDownCircle(), style: .plain, target: self, action: nil)
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    private func configureSearch() {
        searchController.delegate = self
        
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = true
        
        searchController.searchBar.delegate = self
        
        searchController.searchBar.searchBarStyle = .minimal
        searchController.searchBar.placeholder = "Search"
    }
    
    private func configureRefreshControl() {
        refreshControl.addTarget(self, action: #selector(refreshCategories), for: .valueChanged)
    }
    
    private func configureCollectionView() {
        collectionView.refreshControl = refreshControl
        collectionView.dataSource = dataSource
        collectionView.register(CategoryCollectionViewCell.self, forCellWithReuseIdentifier: CategoryCollectionViewCell.reuseIdentifier)
    }
    
    private func fetchCategories() {
        let headers: HTTPHeaders = [acceptJsonHeader, authorisationHeader]
        
        AF.request(UpApi.Categories().listCategories, method: .get, headers: headers).responseJSON { response in
            self.categoriesStatusCode = response.response?.statusCode ?? 0
            
            switch response.result {
                case .success:
                    if let decodedResponse = try? JSONDecoder().decode(Category.self, from: response.data!) {
                        print("Categories JSON decoding succeeded")
                        
                        self.categories = decodedResponse.data
                        self.categoriesError = ""
                        self.categoriesErrorResponse = []
                        
                        if !decodedResponse.data.isEmpty {
                            if self.navigationItem.searchController == nil {
                                self.navigationItem.searchController = self.searchController
                            }
                        } else {
                            if self.navigationItem.searchController != nil {
                                self.navigationItem.searchController = nil
                            }
                        }
                        
                        if self.navigationItem.title != "Categories" {
                            self.navigationItem.title = "Categories"
                        }
                        
                        self.applySnapshot()
                        self.collectionView.refreshControl?.endRefreshing()
                    } else if let decodedResponse = try? JSONDecoder().decode(ErrorResponse.self, from: response.data!) {
                        print("Categories Error JSON decoding succeeded")
                        
                        self.categoriesErrorResponse = decodedResponse.errors
                        self.categoriesError = ""
                        self.categories = []
                        
                        if self.navigationItem.searchController != nil {
                            self.navigationItem.searchController = nil
                        }
                        
                        if self.navigationItem.title != "Errors" {
                            self.navigationItem.title = "Errors"
                        }
                        
                        self.applySnapshot()
                        self.collectionView.refreshControl?.endRefreshing()
                    } else {
                        print("Categories JSON decoding failed")
                        
                        self.categoriesError = "JSON Decoding Failed!"
                        self.categoriesErrorResponse = []
                        self.categories = []
                        
                        if self.navigationItem.searchController != nil {
                            self.navigationItem.searchController = nil
                        }
                        
                        if self.navigationItem.title != "Error" {
                            self.navigationItem.title = "Error"
                        }
                        
                        self.applySnapshot()
                        self.collectionView.refreshControl?.endRefreshing()
                    }
                case .failure:
                    print(response.error?.localizedDescription ?? "Unknown error")
                    
                    self.categoriesError = response.error?.localizedDescription ?? "Unknown Error!"
                    self.categoriesErrorResponse = []
                    self.categories = []
                    
                    if self.navigationItem.searchController != nil {
                        self.navigationItem.searchController = nil
                    }
                    
                    if self.navigationItem.title != "Error" {
                        self.navigationItem.title = "Error"
                    }
                    
                    self.applySnapshot()
                    self.collectionView.refreshControl?.endRefreshing()
            }
            self.searchController.searchBar.placeholder = "Search \(self.categories.count.description) \(self.categories.count == 1 ? "Category" : "Categories")"
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let copy = UIAction(title: "Copy", image: R.image.docOnClipboard()) { _ in
            UIPasteboard.general.string = self.dataSource.itemIdentifier(for: indexPath)!.attributes.name
        }
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            UIMenu(children: [copy])
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        navigationController?.pushViewController({
            let vc = TransactionsByCategoryVC(style: .grouped)
            vc.category = dataSource.itemIdentifier(for: indexPath)
            return vc
        }(),
        animated: true)
    }
}

extension CategoriesCVC: UISearchControllerDelegate, UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        applySnapshot()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        if searchBar.text != "" {
            searchBar.text = ""
            applySnapshot()
        }
    }
}
