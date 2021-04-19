import UIKit
import Rswift

class TagsVC: TableViewController {
    var transaction: TransactionResource!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureProperties()
        configureNavigation()
        configureTableView()
    }
}

extension TagsVC {
    private func configureProperties() {
        title = "Tags"
    }
    
    private func configureNavigation() {
        navigationItem.title = "Tags"
        navigationItem.backBarButtonItem = UIBarButtonItem(image: R.image.tag(), style: .plain, target: self, action: nil)
    }
    
    private func configureTableView() {
        tableView.register(BasicTableViewCell.self, forCellReuseIdentifier: "tagCell")
    }
}

extension TagsVC {
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transaction.relationships.tags.data.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "tagCell", for: indexPath) as! BasicTableViewCell

        cell.selectedBackgroundView = selectedBackgroundCellView
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.font = R.font.circularStdBook(size: UIFont.labelFontSize)
        cell.textLabel?.text = transaction.relationships.tags.data[indexPath.row].id
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        navigationController?.pushViewController({let vc = TransactionsByTagVC(style: .grouped);vc.tag = TagResource(type: "tags", id: transaction.relationships.tags.data[indexPath.row].id);return vc}(), animated: true)
    }
    
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            UIMenu(children: [
                UIAction(title: "Copy", image: R.image.docOnClipboard()) { _ in
                    UIPasteboard.general.string = self.transaction.relationships.tags.data[indexPath.row].id
                },
                UIAction(title: "Remove", image: R.image.trash(), attributes: .destructive) { _ in
                    let ac = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

                    let confirmAction = UIAlertAction(title: "Remove", style: .destructive, handler: { _ in
                        let url = URL(string: "https://api.up.com.au/api/v1/transactions/\(self.transaction.id)/relationships/tags")!

                        var request = URLRequest(url: url)

                        request.httpMethod = "DELETE"
                        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                        request.addValue("Bearer \(appDefaults.string(forKey: "apiKey") ?? "")", forHTTPHeaderField: "Authorization")

                        let bodyObject: [String : Any] = [
                            "data": [
                                [
                                    "type": "tags",
                                    "id": self.transaction.relationships.tags.data[indexPath.row].id
                                ]
                            ]
                        ]

                        request.httpBody = try! JSONSerialization.data(withJSONObject: bodyObject, options: [])

                        URLSession.shared.dataTask(with: request) { data, response, error in
                            if error == nil {
                                let statusCode = (response as! HTTPURLResponse).statusCode

                                if statusCode != 204 {
                                    DispatchQueue.main.async {
                                        let ac = UIAlertController(title: "", message: "", preferredStyle: .alert)

                                        let titleFont = [NSAttributedString.Key.font: R.font.circularStdBold(size: 17)!]
                                        let messageFont = [NSAttributedString.Key.font: R.font.circularStdBook(size: 12)!]

                                        let titleAttrString = NSMutableAttributedString(string: "Failed", attributes: titleFont)
                                        let messageAttrString = NSMutableAttributedString(string: "\(self.transaction.relationships.tags.data[indexPath.row].id) was not removed from \(self.transaction.attributes.description).", attributes: messageFont)

                                        ac.setValue(titleAttrString, forKey: "attributedTitle")
                                        ac.setValue(messageAttrString, forKey: "attributedMessage")

                                        let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel)

                                        dismissAction.setValue(R.color.accentColor(), forKey: "titleTextColor")

                                        ac.addAction(dismissAction)

                                        self.present(ac, animated: true)

                                    }
                                } else {
                                    DispatchQueue.main.async {
                                        self.navigationController?.popToRootViewController(animated: true)
                                    }
                                }
                            } else {
                                DispatchQueue.main.async {
                                    let ac = UIAlertController(title: "", message: "", preferredStyle: .alert)

                                    let titleFont = [NSAttributedString.Key.font: R.font.circularStdBold(size: 17)!]
                                    let messageFont = [NSAttributedString.Key.font: R.font.circularStdBook(size: 12)!]

                                    let titleAttrString = NSMutableAttributedString(string: "Failed", attributes: titleFont)
                                    let messageAttrString = NSMutableAttributedString(string: error?.localizedDescription ?? "\(self.transaction.relationships.tags.data[indexPath.row].id) was not removed from \(self.transaction.attributes.description).", attributes: messageFont)

                                    ac.setValue(titleAttrString, forKey: "attributedTitle")
                                    ac.setValue(messageAttrString, forKey: "attributedMessage")

                                    let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel)

                                    dismissAction.setValue(R.color.accentColor(), forKey: "titleTextColor")

                                    ac.addAction(dismissAction)

                                    self.present(ac, animated: true)
                                }
                            }
                        }
                        .resume()
                    })
                    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

                    cancelAction.setValue(R.color.accentColor(), forKey: "titleTextColor")

                    ac.addAction(confirmAction)
                    ac.addAction(cancelAction)

                    self.present(ac, animated: true)
                }
            ])
        }
    }
}
