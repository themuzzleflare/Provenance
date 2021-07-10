import UIKit
import NotificationBannerSwift
import SwiftyBeaver
import Rswift

final class SettingsVC: UIViewController {
    // MARK: - Properties

    private var displayBanner: GrowingNotificationBanner?

    private var submitActionProxy: UIAlertAction?
    private var apiKeyObserver: NSKeyValueObservation?
    private var textDidChangeObserver: NSObjectProtocol!

    private let tableView = UITableView(frame: .zero, style: .grouped)

    // MARK: - Life Cycle

    init(displayBanner: GrowingNotificationBanner? = nil) {
        self.displayBanner = displayBanner
        super.init(nibName: nil, bundle: nil)
        log.debug("init(displayBanner: \(displayBanner?.titleLabel?.text ?? "nil"))")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        log.debug("deinit")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        log.debug("viewDidLoad")
        view.addSubview(tableView)
        configureProperties()
        configureNavigation()
        configureTableView()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        log.debug("viewDidLayoutSubviews")
        tableView.frame = view.bounds
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        log.debug("viewDidAppear(animated: \(animated.description))")
        if let displayBanner = displayBanner {
            displayBanner.show()
        }
    }
}

// MARK: - Configuration

private extension SettingsVC {
    private func configureProperties() {
        log.verbose("configureProperties")

        title = "Settings"

        apiKeyObserver = appDefaults.observe(\.apiKey, options: .new) { [self] object, change in
            DispatchQueue.main.async {
                if let alert = presentedViewController as? UIAlertController {
                    alert.dismiss(animated: true)
                }
            }
        }
    }
    
    private func configureNavigation() {
        log.verbose("configureNavigation")

        navigationItem.title = "Settings"
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeWorkflow))
    }
    
    private func configureTableView() {
        log.verbose("configureTableView")
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(APIKeyTableViewCell.self, forCellReuseIdentifier: APIKeyTableViewCell.reuseIdentifier)
        tableView.register(DateStyleTableViewCell.self, forCellReuseIdentifier: DateStyleTableViewCell.reuseIdentifier)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "settingsCell")
        tableView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        tableView.showsVerticalScrollIndicator = false
    }
}

// MARK: - Actions

private extension SettingsVC {
    @objc private func closeWorkflow() {
        log.verbose("closeWorkflow")
        navigationController?.dismiss(animated: true)
    }
}

// MARK: - UITableViewDataSource

extension SettingsVC: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let apiKeyCell = tableView.dequeueReusableCell(withIdentifier: APIKeyTableViewCell.reuseIdentifier, for: indexPath) as! APIKeyTableViewCell
        let dateStyleCell = tableView.dequeueReusableCell(withIdentifier: DateStyleTableViewCell.reuseIdentifier, for: indexPath) as! DateStyleTableViewCell
        let settingsCell = tableView.dequeueReusableCell(withIdentifier: "settingsCell", for: indexPath)

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
                return "Open in the Settings application."
            default:
                return nil
        }
    }
}

// MARK: - UITableViewDelegate

extension SettingsVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
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
        log.debug("tableView(didSelectRowAt indexPath: \(indexPath))")

        tableView.deselectRow(at: indexPath, animated: true)

        switch indexPath.section {
            case 0:
                let ac = UIAlertController(title: "API Key", message: "Enter a new API Key.", preferredStyle: .alert)
                
                ac.addTextField { [self] textField in
                    textField.autocapitalizationType = .none
                    textField.autocorrectionType = .no
                    textField.tintColor = R.color.accentColor()
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

                cancelAction.setValue(R.color.accentColor(), forKey: "titleTextColor")

                let submitAction = UIAlertAction(title: "Save", style: .default) { _ in
                    let answer = ac.textFields![0]

                    if !answer.text!.isEmpty && answer.text != appDefaults.apiKey {
                        Up.ping(with: answer.text!) { error in
                            DispatchQueue.main.async {
                                switch error {
                                    case .none:
                                        let nb = GrowingNotificationBanner(title: "Success", subtitle: "The API Key was verified and saved.", style: .success)

                                        nb.duration = 2

                                        nb.show()
                                        appDefaults.apiKey = answer.text!
                                    default:
                                        let nb = GrowingNotificationBanner(title: "Failed", subtitle: errorString(for: error!), style: .danger)

                                        nb.duration = 2

                                        nb.show()
                                }
                            }
                        }
                    } else {
                        let nb = GrowingNotificationBanner(title: "Failed", subtitle: "The provided API Key was the same as the current one.", style: .danger)

                        nb.duration = 2

                        nb.show()
                    }
                }

                submitAction.setValue(R.color.accentColor(), forKey: "titleTextColor")
                submitAction.isEnabled = false
                submitActionProxy = submitAction

                ac.addAction(cancelAction)
                ac.addAction(submitAction)

                present(ac, animated: true)
            case 2:
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
