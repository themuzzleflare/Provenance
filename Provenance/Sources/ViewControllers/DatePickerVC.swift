import UIKit
import SnapKit

final class DatePickerVC: ViewController {
  private enum DateType: Int {
    case since, until
  }

  private let datePicker = UIDatePicker()

  private weak var controller: TransactionsVC?

  private lazy var dateType: DateType = .since {
    didSet {
      updateDatePicker()
    }
  }

  private lazy var clearBarButtonItem = UIBarButtonItem(title: "Clear", style: .plain, target: self, action: #selector(clear))

  private lazy var segmentedControl: UISegmentedControl = {
    let control = UISegmentedControl(items: ["Since", "Until"])
    control.setWidth(100, forSegmentAt: 0)
    control.setWidth(100, forSegmentAt: 1)
    control.selectedSegmentIndex = dateType.rawValue
    control.addTarget(self, action: #selector(selectionChanged(_:)), for: .valueChanged)
    return control
  }()

  init(controller: TransactionsVC) {
    self.controller = controller
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
    guard previousTraitCollection?.verticalSizeClass != traitCollection.verticalSizeClass else { return }
    datePicker.preferredDatePickerStyle = traitCollection.verticalSizeClass == .compact ? .compact : .inline
    datePicker.snp.remakeConstraints { (make) in
      if traitCollection.verticalSizeClass == .regular {
        make.edges.equalToSuperview()
      }
      make.center.equalToSuperview()
    }
  }

  private func configureNavigation() {
    navigationItem.title = "Date Filters"
    navigationItem.titleView = segmentedControl
    navigationItem.leftBarButtonItem = .close(self, action: #selector(closeWorkflow))
    navigationItem.largeTitleDisplayMode = .never
  }

  private func configureDatePicker() {
    updateDatePicker()
    datePicker.preferredDatePickerStyle = traitCollection.verticalSizeClass == .compact ? .compact : .inline
    datePicker.maximumDate = Date()
    datePicker.addTarget(self, action: #selector(setDate), for: .valueChanged)
    datePicker.snp.makeConstraints { (make) in
      if traitCollection.verticalSizeClass == .regular {
        make.edges.equalToSuperview()
      }
      make.center.equalToSuperview()
    }
  }

  private func updateDatePicker() {
    switch dateType {
    case .since:
      if let date = controller?.sinceDate {
        datePicker.setDate(date, animated: true)
      } else {
        datePicker.setDate(Date(), animated: true)
      }
    case .until:
      if let date = controller?.untilDate {
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
      if controller?.sinceDate != nil {
        if navigationItem.rightBarButtonItem != clearBarButtonItem {
          navigationItem.setRightBarButton(clearBarButtonItem, animated: true)
        }
      } else {
        if navigationItem.rightBarButtonItem != nil {
          navigationItem.setRightBarButton(nil, animated: true)
        }
      }
    case .until:
      if controller?.untilDate != nil {
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
  private func setDate() {
    switch dateType {
    case .since:
      controller?.sinceDate = datePicker.date
    case .until:
      controller?.untilDate = datePicker.date
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
      controller?.sinceDate = nil
    case .until:
      controller?.untilDate = nil
    }
    updateDatePicker()
  }
}
