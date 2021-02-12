import UIKit

class TransactionAttributeDetailViewController: UIViewController {
    var attributeKey: String!
    var attributeValue: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let closeButton = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeWorkflow))
        
        navigationItem.title = attributeKey
        navigationItem.setRightBarButton(closeButton, animated: true)
        
        let textView = UITextView()
        view.addSubview(textView)
        
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        textView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        textView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        textView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        
        textView.font = .preferredFont(forTextStyle: .body)
        textView.text = attributeValue
        textView.isScrollEnabled = true
        textView.isEditable = false
        textView.isSelectable = true
        
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    }
    
    @objc private func closeWorkflow() {
        dismiss(animated: true)
    }
}
