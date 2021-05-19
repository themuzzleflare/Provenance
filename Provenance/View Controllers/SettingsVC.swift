import UIKit
import WidgetKit
import NotificationBannerSwift
import Rswift

class SettingsVC: TableViewController {
    var displayBanner: NotificationBanner?

    private weak var submitActionProxy: UIAlertAction?
    
    private var textDidChangeObserver: NSObjectProtocol!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureProperties()
        configureNavigation()
        configureTableView()
    }

    override func viewDidAppear(_ animated: Bool) {
        if let displayBanner = displayBanner {
            displayBanner.show()
        }
    }
}

private extension SettingsVC {
    @objc private func closeWorkflow() {
        navigationController?.dismiss(animated: true)
    }
    
    private func configureProperties() {
        title = "Settings"
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
        switch indexPath.section {
            case 0:
                return apiKeyCell
            case 1:
                return dateStyleCell
            default:
                fatalError("Unknown section")
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            tableView.deselectRow(at: indexPath, animated: true)
            let ac = UIAlertController(title: "API Key", message: "Enter a new API Key.", preferredStyle: .alert)
            ac.addTextField { textField in
                textField.autocapitalizationType = .none
                textField.autocorrectionType = .no
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
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            cancelAction.setValue(R.color.accentColour(), forKey: "titleTextColor")
            let submitAction = UIAlertAction(title: "Save", style: .default) { _ in
                let answer = ac.textFields![0]
                if !answer.text!.isEmpty && answer.text != appDefaults.apiKey {
                    let url = URL(string: "https://api.up.com.au/api/v1/util/ping")!
                    var request = URLRequest(url: url)
                    request.httpMethod = "GET"
                    request.allHTTPHeaderFields = [
                        "Accept": "application/json",
                        "Authorization": "Bearer \(answer.text!)"
                    ]
                    URLSession.shared.dataTask(with: request) { data, response, error in
                        if error == nil {
                            let statusCode = (response as! HTTPURLResponse).statusCode
                            if statusCode == 200 {
                                DispatchQueue.main.async {
                                    let notificationBanner = NotificationBanner(title: "Success", subtitle: "The API Key was verified and saved.", style: .success)
                                    notificationBanner.duration = 2
                                    notificationBanner.show()
                                    appDefaults.apiKey = answer.text!
                                }
                            } else {
                                DispatchQueue.main.async {
                                    let notificationBanner = NotificationBanner(title: "Failed", subtitle: "The API Key could not be verified.", style: .danger)
                                    notificationBanner.duration = 2
                                    notificationBanner.show()
                                    WidgetCenter.shared.reloadAllTimelines()
                                }
                            }
                        } else {
                            DispatchQueue.main.async {
                                let notificationBanner = NotificationBanner(title: "Failed", subtitle: error?.localizedDescription ?? "The API Key could not be verified.", style: .danger)
                                notificationBanner.duration = 2
                                notificationBanner.show()
                                WidgetCenter.shared.reloadAllTimelines()
                            }
                        }
                    }
                    .resume()
                } else {
                    let notificationBanner = NotificationBanner(title: "Failed", subtitle: "The provided API Key was the same as the current one.", style: .danger)
                    notificationBanner.duration = 2
                    notificationBanner.show()
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

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
            case 0:
                return "API Key"
            default:
                return nil
        }
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
            case 0:
                return "The personal access token used to communicate with the Up Banking Developer API."
            case 1:
                return "The styling of dates displayed thoughout the application."
            default:
                return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        switch indexPath.section {
            case 0:
                switch appDefaults.apiKey {
                    case "":
                        return nil
                    default:
                        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
                            UIMenu(children: [
                                UIAction(title: "Copy API Key", image: R.image.docOnClipboard()) { _ in
                                    UIPasteboard.general.string = appDefaults.apiKey
                                }
                            ])
                        }
                }
            default:
                return nil
        }
    }
}
