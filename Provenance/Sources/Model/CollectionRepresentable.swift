import Foundation
import UIKit
import AsyncDisplayKit

enum CollectionRepresentable {
  case tableNode(ASTableNode)
  case collectionNode(ASCollectionNode)
  case tableView(UITableView)
}
