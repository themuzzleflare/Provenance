import UIKit
import WidgetKit
import Rswift

class SettingsVC: TableViewController {
    weak var submitActionProxy: UIAlertAction?
    
    private var textDidChangeObserver: NSObjectProtocol!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setProperties()
        setupNavigation()
        setupTableView()
    }
}

extension SettingsVC {
    @objc private func switchDateStyle(segment: UISegmentedControl) {
        if segment.selectedSegmentIndex == 0 {
            appDefaults.setValue("Absolute", forKey: "dateStyle")
        } else {
            appDefaults.setValue("Relative", forKey: "dateStyle")
        }
        
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    @objc private func closeWorkflow() {
        dismiss(animated: true)
    }
    
    private func setProperties() {
        title = "Settings"
    }
    
    private func setupNavigation() {
        navigationItem.title = "Settings"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeWorkflow))
    }
    
    private func setupTableView() {
        tableView.register(APIKeyCell.self, forCellReuseIdentifier: APIKeyCell.reuseIdentifier)
        tableView.register(DateStylePickerCell.self, forCellReuseIdentifier: DateStylePickerCell.reuseIdentifier)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let apiKeyCell = tableView.dequeueReusableCell(withIdentifier: APIKeyCell.reuseIdentifier, for: indexPath) as! APIKeyCell
        let datePickerCell = tableView.dequeueReusableCell(withIdentifier: DateStylePickerCell.reuseIdentifier, for: indexPath) as! DateStylePickerCell
        
        apiKeyCell.apiKeyLabel.text = apiKeyDisplay
        
        if appDefaults.string(forKey: "dateStyle") == "Absolute" || appDefaults.string(forKey: "dateStyle") == nil {
            datePickerCell.segmentedControl.selectedSegmentIndex = 0
        } else {
            datePickerCell.segmentedControl.selectedSegmentIndex = 1
        }
        
        datePickerCell.segmentedControl.addTarget(self, action: #selector(switchDateStyle), for:.valueChanged)
        
        if indexPath.section == 0 {
            return apiKeyCell
        } else {
            return datePickerCell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            tableView.deselectRow(at: indexPath, animated: true)
            
            let ac = UIAlertController(title: "", message: "", preferredStyle: .alert)
            
            let titleFont = [NSAttributedString.Key.font: R.font.circularStdBold(size: 17)!]
            let messageFont = [NSAttributedString.Key.font: R.font.circularStdBook(size: 12)!]
            
            let titleAttrString = NSMutableAttributedString(string: "API Key", attributes: titleFont)
            let messageAttrString = NSMutableAttributedString(string: "Enter a new API Key.", attributes: messageFont)
            
            ac.setValue(titleAttrString, forKey: "attributedTitle")
            ac.setValue(messageAttrString, forKey: "attributedMessage")
            
            ac.addTextField(configurationHandler: { textField in
                textField.autocapitalizationType = .none
                textField.autocorrectionType = .no
                textField.tintColor = R.color.accentColor()
                textField.text = appDefaults.string(forKey: "apiKey") ?? nil
                
                self.textDidChangeObserver = NotificationCenter.default.addObserver(
                    forName: UITextField.textDidChangeNotification,
                    object: textField,
                    queue: OperationQueue.main) { (notification) in
                    if let textField = notification.object as? UITextField {
                        if let text = textField.text {
                            self.submitActionProxy!.isEnabled = text.count >= 1 && text != appDefaults.string(forKey: "apiKey")
                        } else {
                            self.submitActionProxy!.isEnabled = false
                        }
                    }
                }
            })
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            
            cancelAction.setValue(R.color.accentColor(), forKey: "titleTextColor")
            
            let submitAction = UIAlertAction(title: "Save", style: .default) { _ in
                let answer = ac.textFields![0]
                
                if (answer.text != "" && answer.text != nil) && answer.text != appDefaults.string(forKey: "apiKey") {
                    let url = URL(string: "https://api.up.com.au/api/v1/util/ping")!
                    
                    var request = URLRequest(url: url)
                    
                    request.httpMethod = "GET"
                    request.addValue("application/json", forHTTPHeaderField: "Accept")
                    request.addValue("Bearer \(answer.text!)", forHTTPHeaderField: "Authorization")
                    
                    URLSession.shared.dataTask(with: request) { data, response, error in
                        if error == nil {
                            let statusCode = (response as! HTTPURLResponse).statusCode
                            
                            if statusCode == 200 {
                                DispatchQueue.main.async {
                                    appDefaults.set(answer.text!, forKey: "apiKey")
                                    
                                    self.tableView.reloadData()
                                    
                                    WidgetCenter.shared.reloadAllTimelines()
                                }
                            } else {
                                DispatchQueue.main.async {
                                    let ac = UIAlertController(title: "", message: "", preferredStyle: .alert)
                                    
                                    let titleFont = [NSAttributedString.Key.font: R.font.circularStdBold(size: 17)!]
                                    let messageFont = [NSAttributedString.Key.font: R.font.circularStdBook(size: 12)!]
                                    
                                    let titleAttrString = NSMutableAttributedString(string: "Failed", attributes: titleFont)
                                    let messageAttrString = NSMutableAttributedString(string: "The API Key could not be verified.", attributes: messageFont)
                                    
                                    ac.setValue(titleAttrString, forKey: "attributedTitle")
                                    ac.setValue(messageAttrString, forKey: "attributedMessage")
                                    
                                    let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel)
                                    
                                    dismissAction.setValue(R.color.accentColor(), forKey: "titleTextColor")
                                    
                                    ac.addAction(dismissAction)
                                    
                                    self.present(ac, animated: true)
                                    
                                    WidgetCenter.shared.reloadAllTimelines()
                                }
                            }
                        } else {
                            DispatchQueue.main.async {
                                let ac = UIAlertController(title: "", message: "", preferredStyle: .alert)
                                
                                let titleFont = [NSAttributedString.Key.font: R.font.circularStdBold(size: 17)!]
                                let messageFont = [NSAttributedString.Key.font: R.font.circularStdBook(size: 12)!]
                                
                                let titleAttrString = NSMutableAttributedString(string: "Failed", attributes: titleFont)
                                let messageAttrString = NSMutableAttributedString(string: error?.localizedDescription ?? "The API Key could not be verified.", attributes: messageFont)
                                
                                ac.setValue(titleAttrString, forKey: "attributedTitle")
                                ac.setValue(messageAttrString, forKey: "attributedMessage")
                                
                                let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel)
                                
                                dismissAction.setValue(R.color.accentColor(), forKey: "titleTextColor")
                                
                                ac.addAction(dismissAction)
                                
                                self.present(ac, animated: true)
                                
                                WidgetCenter.shared.reloadAllTimelines()
                            }
                        }
                    }
                    .resume()
                } else {
                    let ac = UIAlertController(title: "", message: "", preferredStyle: .alert)
                    
                    let titleFont = [NSAttributedString.Key.font: R.font.circularStdBold(size: 17)!]
                    let messageFont = [NSAttributedString.Key.font: R.font.circularStdBook(size: 12)!]
                    
                    let titleAttrString = NSMutableAttributedString(string: "Failed", attributes: titleFont)
                    let messageAttrString = NSMutableAttributedString(string: "The provided API Key was the same as the current one.", attributes: messageFont)
                    
                    ac.setValue(titleAttrString, forKey: "attributedTitle")
                    ac.setValue(messageAttrString, forKey: "attributedMessage")
                    
                    let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel)
                    
                    dismissAction.setValue(R.color.accentColor(), forKey: "titleTextColor")
                    
                    ac.addAction(dismissAction)
                    
                    self.present(ac, animated: true)
                    
                    WidgetCenter.shared.reloadAllTimelines()
                }
            }
            submitAction.setValue(R.color.accentColor(), forKey: "titleTextColor")
            submitAction.isEnabled = false
            
            submitActionProxy = submitAction
            
            ac.addAction(cancelAction)
            ac.addAction(submitAction)
            
            self.present(ac, animated: true)
        }
    }
    
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let copy = UIAction(title: "Copy", image: R.image.docOnClipboard()) { _ in
            UIPasteboard.general.string = appDefaults.string(forKey: "apiKey")
        }
        
        if indexPath.section == 0 {
            if appDefaults.string(forKey: "apiKey") != nil {
                return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
                    UIMenu(children: [copy])
                }
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "API Key"
        } else {
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 0 {
            return "The personal access token used to communicate with the Up Banking Developer API."
        } else {
            return "The styling of dates displayed thoughout the application."
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
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}
