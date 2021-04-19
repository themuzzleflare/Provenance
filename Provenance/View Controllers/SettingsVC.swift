import UIKit
import WidgetKit
import Rswift

class SettingsVC: TableViewController {
    weak var submitActionProxy: UIAlertAction?
    
    private var textDidChangeObserver: NSObjectProtocol!
    private var apiKeyObserver: NSKeyValueObservation?
    private var dateStyleObserver: NSKeyValueObservation?
    private var apiKeyDisplay: String {
        switch appDefaults.apiKey {
            case nil, "":
                return "None"
            default:
                return appDefaults.apiKey
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setProperties()
        setupNavigation()
        setupTableView()
    }
}

extension SettingsVC {
    @objc private func appMovedToForeground() {
        tableView.reloadData()
    }

    @objc private func switchDateStyle(segment: UISegmentedControl) {
        if segment.selectedSegmentIndex == 0 {
            appDefaults.setValue("Absolute", forKey: "dateStyle")
        } else {
            appDefaults.setValue("Relative", forKey: "dateStyle")
        }
    }
    
    @objc private func closeWorkflow() {
        dismiss(animated: true)
    }
    
    private func setProperties() {
        title = "Settings"
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        apiKeyObserver = appDefaults.observe(\.apiKey, options: [.new, .old]) { (object, change) in
            self.tableView.reloadData()
            WidgetCenter.shared.reloadAllTimelines()
        }
        dateStyleObserver = appDefaults.observe(\.dateStyle, options: [.new, .old]) { (object, change) in
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    private func setupNavigation() {
        navigationItem.title = "Settings"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeWorkflow))
    }
    
    private func setupTableView() {
        tableView.register(APIKeyTableViewCell.self, forCellReuseIdentifier: APIKeyTableViewCell.reuseIdentifier)
        tableView.register(DateStyleTableViewCell.self, forCellReuseIdentifier: DateStyleTableViewCell.reuseIdentifier)
    }
}

extension SettingsVC {
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let apiKeyCell = tableView.dequeueReusableCell(withIdentifier: APIKeyTableViewCell.reuseIdentifier, for: indexPath) as! APIKeyTableViewCell
        let datePickerCell = tableView.dequeueReusableCell(withIdentifier: DateStyleTableViewCell.reuseIdentifier, for: indexPath) as! DateStyleTableViewCell
        
        apiKeyCell.apiKeyLabel.text = apiKeyDisplay
        
        if appDefaults.dateStyle == "Absolute" {
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
                textField.isSecureTextEntry = false
                textField.tintColor = R.color.accentColor()
                textField.text = appDefaults.apiKey
                
                self.textDidChangeObserver = NotificationCenter.default.addObserver(
                    forName: UITextField.textDidChangeNotification,
                    object: textField,
                    queue: OperationQueue.main) { (notification) in
                    if let textField = notification.object as? UITextField {
                        if let text = textField.text {
                            self.submitActionProxy!.isEnabled = text.count >= 1 && text != appDefaults.apiKey
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
                
                if (answer.text != "" && answer.text != nil) && answer.text != appDefaults.apiKey {
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
                                    appDefaults.setValue(answer.text!, forKey: "apiKey")
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
        if indexPath.section == 0 {
            if !appDefaults.apiKey.isEmpty {
                return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
                    UIMenu(children: [
                        UIAction(title: "Copy API Key", image: R.image.docOnClipboard()) { _ in
                            UIPasteboard.general.string = appDefaults.apiKey
                        }
                    ])
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
            headerView.textLabel?.font = R.font.circularStdBook(size: 13)
            headerView.textLabel?.textAlignment = .center
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        if let footerView = view as? UITableViewHeaderFooterView {
            footerView.textLabel?.font = R.font.circularStdBook(size: UIFont.smallSystemFontSize)
            footerView.textLabel?.textAlignment = .center
        }
    }
}
