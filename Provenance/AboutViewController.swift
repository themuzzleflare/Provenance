import UIKit

class AboutViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let settingsButton = UIBarButtonItem(image: UIImage(systemName: "gear"), style: .plain, target: self, action: #selector(openSettings))
        let diagnosticsButton = UIBarButtonItem(image: UIImage(systemName: "chevron.left.slash.chevron.right"), style: .plain, target: self, action: #selector(openDiagnostics))
        
        title = "About"
        navigationItem.title = "About"
        navigationItem.setLeftBarButton(diagnosticsButton, animated: true)
        navigationItem.setRightBarButton(settingsButton, animated: true)
        
        view.backgroundColor = .systemBackground
        
        let imageView = UIImageView(image: UIImage(named: "Up_Logo"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 25
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .label
        label.text = "Provenance"
        label.font = .boldSystemFont(ofSize: 32)
        label.numberOfLines = 0
        label.textAlignment = .center
        
        let stackView = UIStackView(arrangedSubviews: [imageView, label])
        view.addSubview(stackView)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.centerYAnchor.constraint(equalTo: super.view.centerYAnchor).isActive = true
        stackView.centerXAnchor.constraint(equalTo: super.view.centerXAnchor).isActive = true
        
        stackView.axis = .vertical
        stackView.spacing = 15
    }
    
    @objc private func openSettings() {
        let vc = UINavigationController(rootViewController: SettingsViewController(style: .grouped))
        present(vc, animated: true)
    }
    
    @objc private func openDiagnostics() {
        let vc = UINavigationController(rootViewController: DiagnosticTableViewController(style: .grouped))
        present(vc, animated: true)
    }
}
