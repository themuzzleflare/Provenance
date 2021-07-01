import UIKit
import WidgetKit
import NotificationBannerSwift
import Rswift

final class SettingsVC: UIViewController {
    // MARK: - Properties

    var displayBanner: NotificationBanner?

    private weak var submitActionProxy: UIAlertAction?

    private let tableView = UITableView(frame: .zero, style: .grouped)

    private var apiKeyObserver: NSKeyValueObservation?
    private var textDidChangeObserver: NSObjectProtocol!

    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)

        configureProperties()
        configureNavigation()
        configureTableView()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        tableView.frame = view.bounds
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let displayBanner = displayBanner {
            displayBanner.show()
        }
    }
}

// MARK: - Configuration

private extension SettingsVC {
    private func configureProperties() {
        title = "Settings"

        apiKeyObserver = appDefaults.observe(\.apiKey, options: .new) { [self] object, change in
            if let alert = presentedViewController as? UIAlertController {
                alert.textFields?[0].text = change.newValue
                alert.dismiss(animated: true)
            }
        }
    }
    
    private func configureNavigation() {
        navigationItem.title = "Settings"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeWorkflow))
    }
    
    private func configureTableView() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(APIKeyTableViewCell.self, forCellReuseIdentifier: APIKeyTableViewCell.reuseIdentifier)
        tableView.register(DateStyleTableViewCell.self, forCellReuseIdentifier: DateStyleTableViewCell.reuseIdentifier)
        tableView.register(BasicTableViewCell.self, forCellReuseIdentifier: "settingsCell")
        tableView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
}

// MARK: - Actions

private extension SettingsVC {
    @objc private func closeWorkflow() {
        navigationController?.dismiss(animated: true)
    }
}

// MARK: - UITableViewDataSource

extension SettingsVC: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let apiKeyCell = tableView.dequeueReusableCell(withIdentifier: APIKeyTableViewCell.reuseIdentifier, for: indexPath) as! APIKeyTableViewCell
        let dateStyleCell = tableView.dequeueReusableCell(withIdentifier: DateStyleTableViewCell.reuseIdentifier, for: indexPath) as! DateStyleTableViewCell
        let settingsCell = tableView.dequeueReusableCell(withIdentifier: "settingsCell", for: indexPath) as! BasicTableViewCell

        settingsCell.accessoryType = .disclosureIndicator
        settingsCell.selectedBackgroundView = selectedBackgroundCellView
        settingsCell.imageView?.tintColor = .label
        settingsCell.imageView?.image = R.image.gearshape()
        settingsCell.textLabel?.font = R.font.circularStdBook(size: UIFont.labelFontSize)
        settingsCell.textLabel?.text = "Settings"

        switch indexPath.section {
            case 0:
                return apiKeyCell
            case 1:
                return dateStyleCell
            case 2:
                return settingsCell
            default:
                fatalError("Unknown section")
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
            case 0:
                return "API Key"
            default:
                return nil
        }
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
            case 0:
                return "The personal access token used to communicate with the Up Banking Developer API."
            case 1:
                return "The styling of dates displayed thoughout the application."
            case 2:
                return "Open the Settings application."
            default:
                return nil
        }
    }
}

// MARK: - UITableViewDelegate

extension SettingsVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch section {
            case 2:
                return UIView()
            default:
                return nil
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
            case 2:
                return 80
            default:
                return UITableView.automaticDimension
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
            case 0:
                tableView.deselectRow(at: indexPath, animated: true)

                let ac = UIAlertController(title: "API Key", message: "Enter a new API Key.", preferredStyle: .alert)
                
                ac.addTextField { [self] textField in
                    textField.autocapitalizationType = .none
                    textField.autocorrectionType = .no
                    textField.tintColor = R.color.accentColour()
                    textField.text = appDefaults.apiKey

                    textDidChangeObserver = NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: textField, queue: OperationQueue.main) { notification in
                        if let textField = notification.object as? UITextField {
                            if let text = textField.text {
                                submitActionProxy!.isEnabled = text.count >= 1 && text != appDefaults.apiKey
                            } else {
                                submitActionProxy!.isEnabled = false
                            }
                        }
                    }
                }

                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

                cancelAction.setValue(R.color.accentColour(), forKey: "titleTextColor")

                let submitAction = UIAlertAction(title: "Save", style: .default) { _ in
                    let answer = ac.textFields![0]

                    if !answer.text!.isEmpty && answer.text != appDefaults.apiKey {
                        upApi.ping(with: answer.text!) { error in
                            switch error {
                                case .none:
                                    DispatchQueue.main.async {
                                        let notificationBanner = NotificationBanner(title: "Success", subtitle: "The API Key was verified and saved.", style: .success)

                                        notificationBanner.duration = 2

                                        notificationBanner.show()
                                        appDefaults.apiKey = answer.text!
                                        WidgetCenter.shared.reloadAllTimelines()
                                    }
                                default:
                                    DispatchQueue.main.async {
                                        let notificationBanner = NotificationBanner(title: "Failed", subtitle: errorString(for: error!), style: .danger)

                                        notificationBanner.duration = 2

                                        notificationBanner.show()
                                    }
                            }
                        }
                    } else {
                        let notificationBanner = NotificationBanner(title: "Failed", subtitle: "The provided API Key was the same as the current one.", style: .danger)

                        notificationBanner.duration = 2

                        notificationBanner.show()
                    }
                }

                submitAction.setValue(R.color.accentColour(), forKey: "titleTextColor")
                submitAction.isEnabled = false
                submitActionProxy = submitAction

                ac.addAction(cancelAction)
                ac.addAction(submitAction)

                present(ac, animated: true)
            case 2:
                tableView.deselectRow(at: indexPath, animated: true)
                
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            default:
                break
        }
    }

    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
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
