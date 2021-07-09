import UIKit
import SwiftyBeaver
import Rswift

final class AboutVC: UIViewController {
    // MARK: - Properties

    private let tableView = UITableView(frame: .zero, style: .grouped)

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        log.debug("viewDidLoad")
        view.addSubview(tableView)

        configure()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        log.debug("viewDidLayoutSubviews")
        tableView.frame = view.bounds
    }
}

// MARK: - Configuration

private extension AboutVC {
    private func configure() {
        log.verbose("configure")

        title = "About"

        navigationItem.title = "About"
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.backBarButtonItem = UIBarButtonItem(image: R.image.infoCircle())
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: R.image.chevronLeftForwardslashChevronRight(), style: .plain, target: self, action: #selector(openDiagnostics))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: R.image.gear(), style: .plain, target: self, action: #selector(openSettings))

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(AboutTopTableViewCell.self, forCellReuseIdentifier: AboutTopTableViewCell.reuseIdentifier)
        tableView.register(AttributeTableViewCell.self, forCellReuseIdentifier: AttributeTableViewCell.reuseIdentifier)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "basicCell")
        tableView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
}

// MARK: - Actions

private extension AboutVC {
    @objc private func openSettings() {
        log.verbose("openSettings")

        present(NavigationController(rootViewController: SettingsVC()), animated: true)
    }

    @objc private func openDiagnostics() {
        log.verbose("openDiagnostics")

        present(NavigationController(rootViewController: DiagnosticTableVC()), animated: true)
    }
}

// MARK: - UITableViewDataSource

extension AboutVC: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
            case 0:
                return 3
            case 1:
                return 2
            case 2:
                return 2
            default:
                fatalError("Unknown section")
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = indexPath.section
        let row = indexPath.row

        let topCell = tableView.dequeueReusableCell(withIdentifier: AboutTopTableViewCell.reuseIdentifier, for: indexPath) as! AboutTopTableViewCell
        let sectionOneAttributeCell = tableView.dequeueReusableCell(withIdentifier: AttributeTableViewCell.reuseIdentifier, for: indexPath) as! AttributeTableViewCell
        let basicCell = tableView.dequeueReusableCell(withIdentifier: "basicCell", for: indexPath)

        basicCell.selectedBackgroundView = selectedBackgroundCellView
        basicCell.imageView?.tintColor = .label
        basicCell.textLabel?.font = R.font.circularStdBook(size: UIFont.labelFontSize)

        switch section {
            case 0:
                switch row {
                    case 0:
                        return topCell
                    case 1:
                        sectionOneAttributeCell.leftLabel.text = "Version"
                        sectionOneAttributeCell.rightLabel.text = appDefaults.appVersion

                        return sectionOneAttributeCell
                    case 2:
                        sectionOneAttributeCell.leftLabel.text = "Build"
                        sectionOneAttributeCell.rightLabel.text = appDefaults.appBuild

                        return sectionOneAttributeCell
                    default:
                        fatalError("Unknown row")
                }
            case 1:
                basicCell.accessoryType = .disclosureIndicator
                basicCell.imageView?.image = nil

                switch row {
                    case 0:
                        basicCell.textLabel?.text = "Widgets"

                        return basicCell
                    case 1:
                        basicCell.textLabel?.text = "Stickers"

                        return basicCell
                    default:
                        fatalError("Unknown row")
                }
            case 2:
                basicCell.accessoryType = .none

                switch row {
                    case 0:
                        basicCell.imageView?.image = R.image.envelope()
                        basicCell.textLabel?.text = "Contact Developer"

                        return basicCell
                    case 1:
                        basicCell.imageView?.image = R.image.linkCircle()
                        basicCell.textLabel?.text = "GitHub"

                        return basicCell
                    default:
                        fatalError("Unknown row")
                }
            default:
                fatalError("Unknown section")
        }
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
            case 2:
                return appCopyright
            default:
                return nil
        }
    }
}

// MARK: - UITableViewDelegate

extension AboutVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        log.debug("tableView(didSelectRowAt indexPath: \(indexPath))")

        let section = indexPath.section
        let row = indexPath.row

        switch section {
            case 1:
                tableView.deselectRow(at: indexPath, animated: true)

                switch row {
                    case 0:
                        navigationController?.pushViewController(WidgetsVC(), animated: true)
                    case 1:
                        navigationController?.pushViewController(StickersVC(), animated: true)
                    default:
                        break
                }
            case 2:
                tableView.deselectRow(at: indexPath, animated: true)

                switch row {
                    case 0:
                        UIApplication.shared.open(URL(string: "mailto:feedback@tavitian.cloud?subject=Feedback%20for%20Provenance")!)
                    case 1:
                        UIApplication.shared.open(URL(string: "https://github.com/themuzzleflare/Provenance")!)
                    default:
                        break
                }
            default:
                break
        }
    }

    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let section = indexPath.section
        let row = indexPath.row

        switch section {
            case 0:
                switch row {
                    case 1:
                        switch appDefaults.appVersion {
                            case "Unknown":
                                return nil
                            default:
                                return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
                                    UIMenu(children: [
                                        UIAction(title: "Copy Version", image: R.image.docOnClipboard()) { _ in
                                            UIPasteboard.general.string = appDefaults.appVersion
                                        }
                                    ])
                                }
                        }
                    case 2:
                        switch appDefaults.appBuild {
                            case "Unknown":
                                return nil
                            default:
                                return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
                                    UIMenu(children: [
                                        UIAction(title: "Copy Build", image: R.image.docOnClipboard()) { _ in
                                            UIPasteboard.general.string = appDefaults.appBuild
                                        }
                                    ])
                                }
                        }
                    default:
                        return nil
                }
            case 2:
                switch row {
                    case 0:
                        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
                            UIMenu(children: [
                                UIAction(title: "Copy Email", image: R.image.docOnClipboard()) { _ in
                                    UIPasteboard.general.string = "feedback@tavitian.cloud"
                                }
                            ])
                        }
                    case 1:
                        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
                            UIMenu(children: [
                                UIAction(title: "Copy Link", image: R.image.docOnClipboard()) { _ in
                                    UIPasteboard.general.string = "https://github.com/themuzzleflare/Provenance"
                                }
                            ])
                        }
                    default:
                        return nil
                }
            default:
                return nil
        }
    }
}
