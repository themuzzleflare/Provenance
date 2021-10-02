import UIKit
import CoreData

final class CoreDataVC: UITableViewController {
  private lazy var fetchedResultsController: NSFetchedResultsController<UpTransaction> = {
    let fetchRequest: NSFetchRequest<UpTransaction> = UpTransaction.fetchRequest()
    
    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
    
    let controller = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                managedObjectContext: AppDelegate.persistentContainer.viewContext,
                                                sectionNameKeyPath: nil, cacheName: nil)
    controller.delegate = self
    
    do {
      try controller.performFetch()
    } catch {
      fatalError("###\(#function): Failed to performFetch: \(error)")
    }
    return controller
  }()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    navigationItem.title = "CoreData"
    tableView.register(TransactionCDCell.self, forCellReuseIdentifier: TransactionCDCell.reuseIdentifier)
  }
}

  // MARK: - UITableViewDataSource and UITableViewDelegate
  //
extension CoreDataVC {
  override func numberOfSections(in tableView: UITableView) -> Int {
    return fetchedResultsController.sections?.count ?? 1
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return fetchedResultsController.sections?[section].numberOfObjects ?? 0
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: TransactionCDCell.reuseIdentifier, for: indexPath) as? TransactionCDCell else {
      fatalError("###\(#function): Failed to dequeue a TransactionCDCell")
    }
    let transaction = fetchedResultsController.object(at: indexPath)
    cell.transaction = transaction
    return cell
  }
}

  // MARK: - NSFetchedResultsControllerDelegate
extension CoreDataVC: NSFetchedResultsControllerDelegate {
  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    tableView.reloadData()
  }
}
