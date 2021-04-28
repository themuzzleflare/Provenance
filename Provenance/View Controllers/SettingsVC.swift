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
        configureProperties()
        configureNavigation()
        configureTableView()
    }
}

private extension SettingsVC {
    @objc private func appMovedToForeground() {
        tableView.reloadData()
    }

    @objc private func switchDateStyle(segment: UISegmentedControl) {
        appDefaults.setValue(segment.titleForSegment(at: segment.selectedSegmentIndex), forKey: "dateStyle")
    }
    
    @objc private func closeWorkflow() {
        navigationController?.dismiss(animated: true)
    }
    
    private func configureProperties() {
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
    
    private func configureNavigation() {
        navigationItem.title = "Settings"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeWorkflow))
    }
    
    private func configureTableView() {
        tableView.register(APIKeyTableViewCell.self, forCellReuseIdentifier: APIKeyTableViewCell.reuseIdentifier)
        tableView.register(DateStyleTableViewCell.self, forCellReuseIdentifier: DateStyleTableViewCell.reuseIdentifier)
    }
}

extension SettingsVC {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let apiKeyCell = tableView.dequeueReusableCell(withIdentifier: APIKeyTableViewCell.reuseIdentifier, for: indexPath) as! APIKeyTableViewCell
        let dateStyleCell = tableView.dequeueReusableCell(withIdentifier: DateStyleTableViewCell.reuseIdentifier, for: indexPath) as! DateStyleTableViewCell
        
        apiKeyCell.apiKeyLabel.text = apiKeyDisplay
        
        if appDefaults.dateStyle == "Absolute" {
            dateStyleCell.segmentedControl.selectedSegmentIndex = 0
        } else if appDefaults.dateStyle == "Relative" {
            dateStyleCell.segmentedControl.selectedSegmentIndex = 1
        }
        
        dateStyleCell.segmentedControl.addTarget(self, action: #selector(switchDateStyle), for: .valueChanged)
        
        if indexPath.section == 0 {
            return apiKeyCell
        } else {
            return dateStyleCell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            tableView.deselectRow(at: indexPath, animated: true)
            
            let ac = UIAlertController(title: "API Key", message: "Enter a new API Key.", preferredStyle: .alert)
            ac.addTextField(configurationHandler: { textField in
                textField.autocapitalizationType = .none
                textField.autocorrectionType = .no
                textField.isSecureTextEntry = false
                textField.tintColor = R.color.accentColour()
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
            cancelAction.setValue(R.color.accentColour(), forKey: "titleTextColor")
            let submitAction = UIAlertAction(title: "Save", style: .default) { _ in
                let answer = ac.textFields![0]
                if !answer.text!.isEmpty && answer.text != appDefaults.apiKey {
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
                                    let ac = UIAlertController(title: "Failed", message: "The API Key could not be verified.", preferredStyle: .alert)
                                    let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel)
                                    dismissAction.setValue(R.color.accentColour(), forKey: "titleTextColor")
                                    ac.addAction(dismissAction)
                                    self.present(ac, animated: true)
                                    WidgetCenter.shared.reloadAllTimelines()
                                }
                            }
                        } else {
                            DispatchQueue.main.async {
                                let ac = UIAlertController(title: "Failed", message: error?.localizedDescription ?? "The API Key could not be verified.", preferredStyle: .alert)
                                let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel)
                                dismissAction.setValue(R.color.accentColour(), forKey: "titleTextColor")
                                ac.addAction(dismissAction)
                                self.present(ac, animated: true)
                                WidgetCenter.shared.reloadAllTimelines()
                            }
                        }
                    }
                    .resume()
                } else {
                    let ac = UIAlertController(title: "Failed", message: "The provided API Key was the same as the current one.", preferredStyle: .alert)
                    let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel)
                    dismissAction.setValue(R.color.accentColour(), forKey: "titleTextColor")
                    ac.addAction(dismissAction)
                    self.present(ac, animated: true)
                    WidgetCenter.shared.reloadAllTimelines()
                }
            }
            submitAction.setValue(R.color.accentColour(), forKey: "titleTextColor")
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
            headerView.textLabel?.textAlignment = .center
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        if let footerView = view as? UITableViewHeaderFooterView {
            footerView.textLabel?.textAlignment = .center
        }
    }
}
