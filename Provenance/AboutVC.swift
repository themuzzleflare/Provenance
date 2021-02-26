import UIKit
import SwiftUI

class AboutVC: UIViewController {
    let vc = UIHostingController(rootView: AboutView())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let settingsButton = UIBarButtonItem(image: UIImage(systemName: "gear"), style: .plain, target: self, action: #selector(openSettings))
        let diagnosticsButton = UIBarButtonItem(image: UIImage(systemName: "chevron.left.slash.chevron.right"), style: .plain, target: self, action: #selector(openDiagnostics))
        
        title = "About"
        navigationItem.title = "About"
        navigationItem.leftBarButtonItem = diagnosticsButton
        navigationItem.rightBarButtonItem = settingsButton
        
        view.backgroundColor = .systemBackground
        
        super.addChild(vc)
        view.addSubview(vc.view)
        
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        vc.view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        vc.view.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        vc.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        vc.view.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
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
