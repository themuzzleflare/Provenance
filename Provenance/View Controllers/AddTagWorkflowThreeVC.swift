import UIKit
import Rswift

class AddTagWorkflowThreeVC: TableViewController {
    var transaction: TransactionResource!
    var tag: String!
    
    private func errorAlert(_ statusCode: Int) -> (title: String, content: String) {
        switch statusCode {
            case 403: return (title: "Forbidden", content: "Too many tags added to this transaction. Each transaction may have up to 6 tags.")
            default: return (title: "Failed", content: "The tag was not added to the transaction.")
        }
    }
    
    @objc private func addTag() {
        let url = URL(string: "https://api.up.com.au/api/v1/transactions/\(transaction.id)/relationships/tags")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(appDefaults.string(forKey: "apiKey") ?? "")", forHTTPHeaderField: "Authorization")
        
        let bodyObject: [String : Any] = [
            "data": [
                [
                    "type": "tags",
                    "id": tag
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
                        
                        let titleAttrString = NSMutableAttributedString(string: self.errorAlert(statusCode).title, attributes: titleFont)
                        let messageAttrString = NSMutableAttributedString(string: self.errorAlert(statusCode).content, attributes: messageFont)
                        
                        ac.setValue(titleAttrString, forKey: "attributedTitle")
                        ac.setValue(messageAttrString, forKey: "attributedMessage")
                        
                        let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel, handler: { _ in
                            self.navigationController?.popViewController(animated: true)
                        })
                        dismissAction.setValue(R.color.accentColor(), forKey: "titleTextColor")
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
                    let ac = UIAlertController(title: "", message: "", preferredStyle: .alert)
                    
                    let titleFont = [NSAttributedString.Key.font: R.font.circularStdBold(size: 17)!]
                    let messageFont = [NSAttributedString.Key.font: R.font.circularStdBook(size: 12)!]
                    
                    let titleAttrString = NSMutableAttributedString(string: "Failed", attributes: titleFont)
                    let messageAttrString = NSMutableAttributedString(string: error?.localizedDescription ?? "\(self.tag!) was not added to \(self.transaction.attributes.description).", attributes: messageFont)
                    
                    ac.setValue(titleAttrString, forKey: "attributedTitle")
                    ac.setValue(messageAttrString, forKey: "attributedMessage")
                    
                    let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel, handler: { _ in
                        self.navigationController?.popToRootViewController(animated: true)
                    })
                    dismissAction.setValue(R.color.accentColor(), forKey: "titleTextColor")
                    ac.addAction(dismissAction)
                    self.present(ac, animated: true)
                }
            }
        }
        .resume()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setProperties()
        setupNavigation()
        setupTableView()
    }
    
    private func setProperties() {
        title = "Confirmation"
    }
    
    private func setupNavigation() {
        navigationItem.title = "Confirmation"
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: R.image.checkmark(), style: .plain, target: self, action: #selector(addTag))
    }
    
    private func setupTableView() {
        tableView.register(SubtitleTableViewCell.self, forCellReuseIdentifier: "attributeCell")
        tableView.register(R.nib.transactionCell)
    }
    
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
            headerView.textLabel?.textColor = .lightGray
            headerView.textLabel?.font = R.font.circularStdBook(size: 13)
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        if let footerView = view as? UITableViewHeaderFooterView {
            footerView.textLabel?.textColor = .lightGray
            footerView.textLabel?.font = R.font.circularStdBook(size: 12)
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "attributeCell", for: indexPath) as! SubtitleTableViewCell
        let transactionCell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.transactionCell, for: indexPath)!
        let section = indexPath.section
        
        cell.selectionStyle = .none
        cell.textLabel?.font = circularStdBook
        cell.detailTextLabel?.font = circularStdBook
        
        transactionCell.selectionStyle = .none
        transactionCell.accessoryType = .none
        
        if section == 0 {
            cell.textLabel?.text = tag
            
            return cell
        } else if section == 1 {
            transactionCell.leftLabel.text = transaction.attributes.description
            transactionCell.leftSubtitle.text = transaction.attributes.creationDate
            
            if transaction.attributes.amount.valueInBaseUnits.signum() == -1 {
                transactionCell.rightLabel.textColor = .black
            } else {
                transactionCell.rightLabel.textColor = R.color.greenColour()
            }
            
            transactionCell.rightLabel.text = transaction.attributes.amount.valueShort
            
            return transactionCell
        } else {
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.text = "You are adding the tag \"\(tag!)\" to the transaction \"\(transaction.attributes.description)\", which was created \(transaction.attributes.creationDate)."
            
            return cell
        }
    }
}
