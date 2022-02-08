import UIKit
import SnapKit

final class DatePickerVC: ViewController {
  private enum DateType: Int {
    case since
    case until
  }

  private let datePicker = UIDatePicker()
  private weak var transactionsController: TransactionsVC?

  private lazy var dateType: DateType = .since {
    didSet {
      updateDatePicker()
    }
  }

  private lazy var clearBarButtonItem = UIBarButtonItem(title: "Clear", style: .plain, target: self, action: #selector(clear))

  private lazy var segmentedControl: UISegmentedControl = {
    let control = UISegmentedControl(items: ["Since", "Until"])
    control.selectedSegmentIndex = 0
    control.addTarget(self, action: #selector(selectionChanged(_:)), for: .valueChanged)
    return control
  }()

  init(_ controller: TransactionsVC) {
    self.transactionsController = controller
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("Not implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.addSubview(datePicker)
    configureNavigation()
    configureDatePicker()
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    datePicker.preferredDatePickerStyle = traitCollection.verticalSizeClass == .compact ? .compact : .inline
  }

  private func configureNavigation() {
    navigationItem.titleView = segmentedControl
    navigationItem.leftBarButtonItem = .close(self, action: #selector(closeWorkflow))
  }

  private func configureDatePicker() {
    updateDatePicker()
    datePicker.preferredDatePickerStyle = traitCollection.verticalSizeClass == .compact ? .compact : .inline
    datePicker.maximumDate = Date()
    datePicker.addTarget(self, action: #selector(fetchTransactions), for: .valueChanged)
    datePicker.snp.makeConstraints { (make) in
      make.center.equalToSuperview()
    }
  }

  private func updateDatePicker() {
    switch dateType {
    case .since:
      if let date = transactionsController?.sinceDate {
        datePicker.setDate(date, animated: true)
      } else {
        datePicker.setDate(Date(), animated: true)
      }
    case .until:
      if let date = transactionsController?.untilDate {
        datePicker.setDate(date, animated: true)
      } else {
        datePicker.setDate(Date(), animated: true)
      }
    }
    updateNavigation()
  }

  private func updateNavigation() {
    switch dateType {
    case .since:
      if transactionsController?.sinceDate != nil {
        if navigationItem.rightBarButtonItem != clearBarButtonItem {
          navigationItem.setRightBarButton(clearBarButtonItem, animated: true)
        }
      } else {
        if navigationItem.rightBarButtonItem != nil {
          navigationItem.setRightBarButton(nil, animated: true)
        }
      }
    case .until:
      if transactionsController?.untilDate != nil {
        if navigationItem.rightBarButtonItem != clearBarButtonItem {
          navigationItem.setRightBarButton(clearBarButtonItem, animated: true)
        }
      } else {
        if navigationItem.rightBarButtonItem != nil {
          navigationItem.setRightBarButton(nil, animated: true)
        }
      }
    }
  }

  @objc
  private func closeWorkflow() {
    navigationController?.dismiss(animated: true)
  }

  @objc
  private func fetchTransactions() {
    switch dateType {
    case .since:
      transactionsController?.sinceDate = datePicker.date
    case .until:
      transactionsController?.untilDate = datePicker.date
    }
    updateNavigation()
  }

  @objc
  private func selectionChanged(_ sender: UISegmentedControl) {
    if let value = DateType(rawValue: sender.selectedSegmentIndex) {
      dateType = value
    }
  }

  @objc
  private func clear() {
    switch dateType {
    case .since:
      transactionsController?.sinceDate = nil
    case .until:
      transactionsController?.untilDate = nil
    }
    updateDatePicker()
  }
}
