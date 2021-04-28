import UIKit
import Alamofire
import NotificationBannerSwift
import Rswift

class TagsVC: TableViewController {
    var transaction: TransactionResource! {
        didSet {
            if transaction.relationships.tags.data.isEmpty {
                navigationController?.popViewController(animated: true)
            } else {
                applySnapshot()
            }
        }
    }

    private typealias DataSource = UITableViewDiffableDataSource<Section, RelationshipData>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, RelationshipData>

    private lazy var dataSource = makeDataSource()

    private enum Section: CaseIterable {
        case main
    }

    private func makeDataSource() -> DataSource {
        return DataSource(
            tableView: tableView,
            cellProvider: { tableView, indexPath, tag in
                let cell = tableView.dequeueReusableCell(withIdentifier: "tagCell", for: indexPath) as! BasicTableViewCell
                cell.selectedBackgroundView = selectedBackgroundCellView
                cell.accessoryType = .disclosureIndicator
                cell.textLabel?.font = R.font.circularStdBook(size: UIFont.labelFontSize)
                cell.textLabel?.textColor = .label
                cell.textLabel?.numberOfLines = 0
                cell.textLabel?.text = tag.id
                return cell
            }
        )
    }

    private func applySnapshot() {
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(transaction.relationships.tags.data, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureProperties()
        configureNavigation()
        configureTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        fetchTags()
    }
}

private extension TagsVC {
    @objc private func appMovedToForeground() {
        fetchTags()
    }

    private func configureProperties() {
        title = "Transaction Tags"
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    private func configureNavigation() {
        navigationItem.title = "Tags"
        navigationItem.backBarButtonItem = UIBarButtonItem(image: R.image.tag(), style: .plain, target: self, action: nil)
    }
    
    private func configureTableView() {
        tableView.dataSource = dataSource
        tableView.register(BasicTableViewCell.self, forCellReuseIdentifier: "tagCell")
    }

    private func fetchTags() {
        AF.request("https://api.up.com.au/api/v1/transactions/\(transaction.id)", method: .get, headers: [acceptJsonHeader, authorisationHeader]).responseJSON { response in
            switch response.result {
                case .success:
                    if let decodedResponse = try? JSONDecoder().decode(SingleTransactionResponse.self, from: response.data!) {
                        self.transaction = decodedResponse.data
                    } else {
                        print("JSON decoding failed")
                    }
                case .failure:
                    print(response.error?.localizedDescription ?? "Unknown error")
            }
        }
    }
}

extension TagsVC {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        navigationController?.pushViewController({let vc = TransactionsByTagVC(style: .grouped);vc.tag = TagResource(type: "tags", id: dataSource.itemIdentifier(for: indexPath)!.id);return vc}(), animated: true)
    }
    
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let tag = dataSource.itemIdentifier(for: indexPath)!

        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            UIMenu(children: [
                UIAction(title: "Copy Tag Name", image: R.image.docOnClipboard()) { _ in
                    UIPasteboard.general.string = tag.id
                },
                UIAction(title: "Remove", image: R.image.trash(), attributes: .destructive) { _ in
                    let ac = UIAlertController(title: nil, message: "Are you sure you want to remove \"\(tag.id)\" from \"\(self.transaction.attributes.description)\"?", preferredStyle: .actionSheet)
                    let confirmAction = UIAlertAction(title: "Remove", style: .destructive, handler: { _ in
                        let url = URL(string: "https://api.up.com.au/api/v1/transactions/\(self.transaction.id)/relationships/tags")!
                        var request = URLRequest(url: url)
                        let bodyObject: [String : Any] = [
                            "data": [
                                [
                                    "type": "tags",
                                    "id": tag.id
                                ]
                            ]
                        ]
                        request.httpMethod = "DELETE"
                        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                        request.addValue("Bearer \(appDefaults.apiKey)", forHTTPHeaderField: "Authorization")
                        request.httpBody = try! JSONSerialization.data(withJSONObject: bodyObject, options: [])
                        URLSession.shared.dataTask(with: request) { data, response, error in
                            if error == nil {
                                let statusCode = (response as! HTTPURLResponse).statusCode
                                if statusCode != 204 {
                                    DispatchQueue.main.async {
                                        let notificationBanner = NotificationBanner(title: "Failed", subtitle: "\(tag.id) was not removed from \(self.transaction.attributes.description).", style: .danger)
                                        notificationBanner.duration = 2
                                        notificationBanner.show()
                                    }
                                } else {
                                    DispatchQueue.main.async {
                                        let notificationBanner = NotificationBanner(title: "Success", subtitle: "\(tag.id) was removed from \(self.transaction.attributes.description).", style: .success)
                                        notificationBanner.duration = 2
                                        notificationBanner.show()
                                        self.fetchTags()
                                    }
                                }
                            } else {
                                DispatchQueue.main.async {
                                    let notificationBanner = NotificationBanner(title: "Failed", subtitle: error?.localizedDescription ?? "\(tag.id) was not removed from \(self.transaction.attributes.description).", style: .danger)
                                    notificationBanner.duration = 2
                                    notificationBanner.show()
                                }
                            }
                        }
                        .resume()
                    })
                    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
                    cancelAction.setValue(R.color.accentColour(), forKey: "titleTextColor")
                    ac.addAction(confirmAction)
                    ac.addAction(cancelAction)
                    self.present(ac, animated: true)
                }
            ])
        }
    }
}
