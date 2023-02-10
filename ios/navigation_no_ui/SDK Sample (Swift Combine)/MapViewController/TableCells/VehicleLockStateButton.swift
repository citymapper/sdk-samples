//
//  VehicleLockStateButton.swift
//  DemoMapper
//
//  Created by Tom Humphrey on 19/03/2021.
//

import UIKit

struct VehicleLockStateButtonCellSpec: TableCellSpec {
    var type: TableCellSpecType = .vehicleLockStateButton

    var contentInsets: UIEdgeInsets?

    let attributedText: NSAttributedString
    let backgroundColor: UIColor

    var borderWidth: CGFloat = 0
    var borderColor: UIColor = .clear

    let action: (() -> Void)?

    func isEqual(to other: TableCellSpec) -> Bool {
        guard let otherButtonCellSpec = other as? VehicleLockStateButtonCellSpec else {
            return false
        }

        return (type == otherButtonCellSpec.type &&
            attributedText == otherButtonCellSpec.attributedText &&
            backgroundColor == otherButtonCellSpec.backgroundColor &&
            contentInsets == otherButtonCellSpec.contentInsets &&
            borderWidth == otherButtonCellSpec.borderWidth &&
            borderColor == otherButtonCellSpec.borderColor)
    }
}

class VehicleLockStateButtonCell: UITableViewCell, DemoMapperTableCell {
    var originalText: NSAttributedString?

    static var kReuseId = "VehicleLockStateButtonCell"

    private static let iconSize = CGSize(width: 25, height: 25)

    private var spec: VehicleLockStateButtonCellSpec?

    private var mainLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.isUserInteractionEnabled = false
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(mainLabel)
        self.backgroundColor = .systemBackground
        contentView.layer.cornerRadius = 10
        self.selectionStyle = .none
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        spec = nil

        mainLabel.text = nil
        mainLabel.attributedText = nil

        contentView.layer.borderWidth = 0
        contentView.layer.borderColor = UIColor.clear.cgColor
        contentView.backgroundColor = .clear
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        var availableWidth = bounds.size.width

        if let insets = spec?.contentInsets {
            availableWidth -= (insets.left + insets.right)
        }

        let contentHeight = heightAndLayout(withWidth: availableWidth)

        contentView.frame = CGRect(x: spec?.contentInsets?.left ?? 0,
                                   y: spec?.contentInsets?.top ?? 0,
                                   width: availableWidth,
                                   height: contentHeight)
    }

    private func heightAndLayout(withWidth width: CGFloat) -> CGFloat {
        let verticalMargin: CGFloat = 15
        var maxY: CGFloat = verticalMargin

        let minXOrigin: CGFloat = 15
        let maxWidth: CGFloat = width - (minXOrigin + minXOrigin)

        let labelHeight = mainLabel.attributedTextHeight(withWidth: maxWidth)
        let labelSize = CGSize(width: maxWidth, height: labelHeight)
        let labelXOrigin: CGFloat = (width - labelSize.width) / 2
        mainLabel.frame = CGRect(x: labelXOrigin,
                                 y: maxY,
                                 width: labelSize.width,
                                 height: labelSize.height)

        maxY = max(maxY, mainLabel.frame.maxY + verticalMargin)

        return maxY
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)

        let hasAction = (spec?.action != nil)

        guard hasAction else { return }

        let backgroundColor = spec?.backgroundColor ?? .systemBackground

        if highlighted {
            contentView.backgroundColor = backgroundColor.withAlphaComponent(0.7)
        } else {
            contentView.backgroundColor = backgroundColor
        }
    }

    @objc
    private func runAction() {
        if let action = spec?.action {
            action()
        }
    }

    func update(with spec: TableCellSpec) {
        guard let validSpec = spec as? VehicleLockStateButtonCellSpec else {
            return
        }

        self.spec = validSpec
        mainLabel.attributedText = validSpec.attributedText

        contentView.backgroundColor = validSpec.backgroundColor

        if validSpec.borderWidth > 0 {
            contentView.layer.borderWidth = validSpec.borderWidth
            contentView.layer.borderColor = validSpec.borderColor.cgColor
        }

        if validSpec.action != nil {
            let tapGestureRecogniser = UITapGestureRecognizer(target: self, action: #selector(runAction))
            contentView.addGestureRecognizer(tapGestureRecogniser)
            contentView.isUserInteractionEnabled = true
        }

        setNeedsLayout()
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var availableWidth = bounds.size.width

        var additionalHeightRequired: CGFloat = 0

        if let insets = spec?.contentInsets {
            availableWidth -= (insets.left + insets.right)
            additionalHeightRequired = (insets.top + insets.bottom)
        }

        return CGSize(width: availableWidth, height: heightAndLayout(withWidth: availableWidth) + additionalHeightRequired)
    }
}
