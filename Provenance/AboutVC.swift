import UIKit

class AboutVC: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let settingsButton = UIBarButtonItem(image: UIImage(systemName: "gear"), style: .plain, target: self, action: #selector(openSettings))
        let diagnosticsButton = UIBarButtonItem(image: UIImage(systemName: "chevron.left.slash.chevron.right"), style: .plain, target: self, action: #selector(openDiagnostics))
        
        title = "About"
        navigationItem.title = "About"
        navigationItem.setLeftBarButton(diagnosticsButton, animated: true)
        navigationItem.setRightBarButton(settingsButton, animated: true)
        
        view.backgroundColor = .systemBackground
        
        let scrollView = UIScrollView()
        view.addSubview(scrollView)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        scrollView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        scrollView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        
        scrollView.contentInset = .init(top: 20, left: 0, bottom: 0, right: 0)
        
        scrollView.alwaysBounceVertical = true
        
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
        
        let subtitle = UILabel()
        subtitle.translatesAutoresizingMaskIntoConstraints = false
        subtitle.textColor = .secondaryLabel
        subtitle.text = "Provenance is a lightweight application that interacts with the Up Banking Developer API to display information about your bank accounts, transactions, categories, tags, and more."
        subtitle.font = .preferredFont(forTextStyle: .body)
        subtitle.numberOfLines = 0
        subtitle.textAlignment = .left
        
        let stackView = UIStackView(arrangedSubviews: [imageView, label, subtitle])
        scrollView.addSubview(stackView)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.topAnchor.constraint(equalTo: scrollView.topAnchor).isActive = true
        stackView.leftAnchor.constraint(equalTo: scrollView.leftAnchor).isActive = true
        stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true
        stackView.rightAnchor.constraint(equalTo: scrollView.rightAnchor).isActive = true
        
        stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor).isActive = true
        
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 15
    }
    
    @objc private func openSettings() {
        let vc = UINavigationController(rootViewController: SettingsVC(style: .grouped))
        present(vc, animated: true)
    }
    
    @objc private func openDiagnostics() {
        let vc = UINavigationController(rootViewController: DiagnosticTableVC(style: .grouped))
        present(vc, animated: true)
    }
}
