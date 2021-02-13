import UIKit

class DateStylePickerCell: UITableViewCell {
    @IBOutlet var leftLabel: UILabel!
    @IBOutlet var datePicker: UISegmentedControl!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
