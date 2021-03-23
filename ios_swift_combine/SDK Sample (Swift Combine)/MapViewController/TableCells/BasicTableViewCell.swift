//
//  BasicTableViewCell.swift
//  DemoMapper
//
//  Created by Tom Humphrey on 19/03/2021.
//

import UIKit

struct BasicTableViewCellSpec: TableCellSpec {
    var type: TableCellSpecType = .basic
    let numberOfLines: Int
    let attributedText: NSAttributedString?
    let backgroundColor: UIColor

    func isEqual(to other: TableCellSpec) -> Bool {
        guard let otherBasicCellSpec = other as? BasicTableViewCellSpec else {
            return false
        }

        return (type == otherBasicCellSpec.type &&
            attributedText == otherBasicCellSpec.attributedText &&
            backgroundColor == otherBasicCellSpec.backgroundColor &&
            numberOfLines == otherBasicCellSpec.numberOfLines)
    }
}

class BasicTableViewCell: UITableViewCell, DemoMapperTableCell {
    static var kReuseId = "kBasicTableViewCell"

    func update(with spec: TableCellSpec) {
        guard let validSpec = spec as? BasicTableViewCellSpec else {
            return
        }

        textLabel?.numberOfLines = validSpec.numberOfLines
        textLabel?.attributedText = validSpec.attributedText
        backgroundColor = validSpec.backgroundColor
    }
}
