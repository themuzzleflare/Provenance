import CoreData

extension UpTransaction {
  static func fetchAll(viewContext: NSManagedObjectContext = AppDelegate.persistentContainer.viewContext) -> [UpTransaction] {
    let request: NSFetchRequest<UpTransaction> = UpTransaction.fetchRequest()
    
    request.sortDescriptors = [
      NSSortDescriptor(key: "creationDate", ascending: false)
    ]
    
    guard let tasks = try? viewContext.fetch(request) else { return [] }
    return tasks
  }
}
