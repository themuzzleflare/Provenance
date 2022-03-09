import Foundation
import UIKit
import AsyncDisplayKit
import IGListKit

enum UIUpdates {
  static func updateUI(state: UIState, contentType: ContentType, collection: CollectionRepresentable) {
    print("Updating UI")

    switch state {
    case .initialLoad:
      switch collection {
      case let .tableNode(tableNode):
        tableNode.view.backgroundView = .loading(frame: tableNode.bounds, contentType: contentType)
      case let .collectionNode(collectionNode):
        collectionNode.view.backgroundView = .loading(frame: collectionNode.bounds, contentType: contentType)
      case let .tableView(tableView):
        tableView.backgroundView = .loading(frame: tableView.bounds, contentType: contentType)
      }
    case let .error(error):
      switch collection {
      case let .tableNode(tableNode):
        tableNode.view.backgroundView = .error(frame: tableNode.bounds, text: error)
      case let .collectionNode(collectionNode):
        collectionNode.view.backgroundView = .error(frame: collectionNode.bounds, text: error)
      case let .tableView(tableView):
        tableView.backgroundView = .error(frame: tableView.bounds, text: error)
      }
    case .noContent:
      switch collection {
      case let .tableNode(tableNode):
        tableNode.view.backgroundView = .noContent(frame: tableNode.bounds, type: contentType)
      case let .collectionNode(collectionNode):
        collectionNode.view.backgroundView = .noContent(frame: collectionNode.bounds, type: contentType)
      case let .tableView(tableView):
        tableView.backgroundView = .noContent(frame: tableView.bounds, type: contentType)
      }
    case .ready:
      switch collection {
      case let .tableNode(tableNode):
        tableNode.view.backgroundView = nil
      case let .collectionNode(collectionNode):
        collectionNode.view.backgroundView = nil
      case let .tableView(tableView):
        tableView.backgroundView = nil
      }
    }
  }

  static func emptyView(state: UIState, contentType: ContentType, collectionNode: ASCollectionNode) -> UIView? {
    switch state {
    case .initialLoad:
      return .loading(frame: collectionNode.bounds, contentType: contentType)
    case let .error(error):
      return .error(frame: collectionNode.bounds, text: error)
    case .noContent:
      return .noContent(frame: collectionNode.bounds, type: contentType)
    case .ready:
      return nil
    }
  }

  static func applySnapshot(oldArray: inout [ListDiffable],
                            newArray: [ListDiffable],
                            override: Bool = false,
                            state: inout UIState,
                            contents: [Any],
                            filteredContents: [Any],
                            noContent: Bool,
                            error: String,
                            contentType: ContentType,
                            collection: CollectionRepresentable) {
    let result = ListDiffPaths(fromSection: 0,
                               toSection: 0,
                               oldArray: oldArray,
                               newArray: newArray,
                               option: .equality).forBatchUpdates()

    print(result.description)
    print("Has changes: \(result.hasChanges.description)")

    if override {
      UIUpdates.updateUI(state: state, contentType: contentType, collection: collection)
    } else {
      StateUpdates.updateState(state: &state,
                               contents: contents,
                               filteredContents: filteredContents,
                               noContent: noContent,
                               error: error)
    }

    batchUpdates(result: result,
                 oldArray: &oldArray,
                 newArray: newArray,
                 collection: collection)
  }

  private static func batchUpdates(result: ListIndexPathResult,
                                   oldArray: inout [ListDiffable],
                                   newArray: [ListDiffable],
                                   collection: CollectionRepresentable) {
    if result.hasChanges {
      switch collection {
      case let .tableNode(tableNode):
        tableNode.performBatchUpdates {
          tableNode.deleteRows(at: result.deletes, with: .fade)
          tableNode.insertRows(at: result.inserts, with: .fade)

          oldArray = newArray
        } completion: { (bool) in
          print("completion: \(bool.description)")
        }
      case let .collectionNode(collectionNode):
        collectionNode.performBatchUpdates {
          collectionNode.deleteItems(at: result.deletes)
          collectionNode.insertItems(at: result.inserts)

          oldArray = newArray
        } completion: { (bool) in
          print("completion: \(bool.description)")
        }
      default:
        break
      }
    }
  }
}
