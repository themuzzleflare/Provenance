import UIKit
import Rswift

class AddTagWorkflowThreeVC: TableViewController {
    var transaction: TransactionResource!
    var tag: String!

    private var dateStyleObserver: NSKeyValueObservation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureProperties()
        configureNavigation()
        configureTableView()
    }
}

extension AddTagWorkflowThreeVC {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Adding Tag"
        } else if section == 1 {
            return "To Transaction"
        } else {
            return "Summary"
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 2 {
            return "No more than 6 tags may be present on any single transaction. Duplicate tags are silently ignored."
        } else {
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let headerView = view as? UITableViewHeaderFooterView {
            headerView.textLabel?.textAlignment = .center
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        if let footerView = view as? UITableViewHeaderFooterView {
            footerView.textLabel?.textAlignment = .center
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = indexPath.section

        let cell = tableView.dequeueReusableCell(withIdentifier: "attributeCell", for: indexPath) as! SubtitleTableViewCell
        let transactionCell = tableView.dequeueReusableCell(withIdentifier: TransactionTableViewCell.reuseIdentifier, for: indexPath) as! TransactionTableViewCell
        
        cell.selectionStyle = .none
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.font = R.font.circularStdBook(size: UIFont.labelFontSize)
        cell.detailTextLabel?.font = R.font.circularStdBook(size: UIFont.labelFontSize)
        
        transactionCell.selectionStyle = .none

        if section == 0 {
            cell.textLabel?.text = tag
            return cell
        } else if section == 1 {
            transactionCell.transaction = transaction
            return transactionCell
        } else {
            cell.textLabel?.text = "You are adding the tag \"\(tag!)\" to the transaction \"\(transaction.attributes.description)\", which was created \(transaction.attributes.creationDate)."
            return cell
        }
    }
}

extension AddTagWorkflowThreeVC {
    private func errorAlert(_ statusCode: Int) -> (title: String, content: String) {
        switch statusCode {
            case 403: return (title: "Forbidden", content: "Too many tags added to this transaction. Each transaction may have up to 6 tags.")
            default: return (title: "Failed", content: "The tag was not added to the transaction.")
        }
    }
    
    @objc private func addTag() {
        let url = URL(string: "https://api.up.com.au/api/v1/transactions/\(transaction.id)/relationships/tags")!
        var request = URLRequest(url: url)
        let bodyObject: [String : Any] = [
            "data": [
                [
                    "type": "tags",
                    "id": tag
                ]
            ]
        ]
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(appDefaults.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try! JSONSerialization.data(withJSONObject: bodyObject, options: [])
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil {
                let statusCode = (response as! HTTPURLResponse).statusCode
                if statusCode != 204 {
                    DispatchQueue.main.async {
                        let ac = UIAlertController(title: self.errorAlert(statusCode).title, message: self.errorAlert(statusCode).content, preferredStyle: .alert)
                        let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel, handler: { _ in
                            self.navigationController?.popViewController(animated: true)
                        })
                        dismissAction.setValue(R.color.accentColour(), forKey: "titleTextColor")
                        ac.addAction(dismissAction)
                        self.present(ac, animated: true)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    let ac = UIAlertController(title: "Failed", message: error?.localizedDescription ?? "\(self.tag!) was not added to \(self.transaction.attributes.description).", preferredStyle: .alert)
                    let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel, handler: { _ in
                        self.navigationController?.popToRootViewController(animated: true)
                    })
                    dismissAction.setValue(R.color.accentColour(), forKey: "titleTextColor")
                    ac.addAction(dismissAction)
                    self.present(ac, animated: true)
                }
            }
        }
        .resume()
    }
    
    private func configureProperties() {
        title = "Confirmation"
        dateStyleObserver = appDefaults.observe(\.dateStyle, options: [.new, .old]) { (object, change) in
            self.tableView.reloadData()
        }
    }
    
    private func configureNavigation() {
        navigationItem.title = "Confirmation"
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: R.image.checkmark(), style: .plain, target: self, action: #selector(addTag))
    }
    
    private func configureTableView() {
        tableView.register(SubtitleTableViewCell.self, forCellReuseIdentifier: "attributeCell")
        tableView.register(TransactionTableViewCell.self, forCellReuseIdentifier: TransactionTableViewCell.reuseIdentifier)
    }
}
