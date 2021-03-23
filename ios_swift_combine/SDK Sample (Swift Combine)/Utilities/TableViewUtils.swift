//
//  TableViewUtils.swift
//  DemoMapper
//
//  Created by Tom Humphrey on 19/03/2021.
//

import UIKit

enum TableCellSpecType {
    case basic
    case vehicleLockStateButton
}

protocol DemoMapperTableCell: UITableViewCell {
    static var kReuseId: String { get }
    func update(with spec: TableCellSpec)
}

protocol TableCellSpec {
    var type: TableCellSpecType { get set }

    func isEqual(to other: TableCellSpec) -> Bool
}

enum TableViewUtils {
    static func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath, specs: [TableCellSpec]) -> UITableViewCell {
        guard specs.count > indexPath.item else {
            return UITableViewCell()
        }

        let spec = specs[indexPath.row]

        switch spec.type {
        case .basic:
            guard let spec = spec as? BasicTableViewCellSpec else { return UITableViewCell() }

            guard let basicCell = tableView.dequeueReusableCell(withIdentifier: BasicTableViewCell.kReuseId,
                                                                for: indexPath) as? BasicTableViewCell
            else {
                return UITableViewCell()
            }

            basicCell.update(with: spec)
            return basicCell
        case .vehicleLockStateButton:
            guard let spec = spec as? VehicleLockStateButtonCellSpec else { return UITableViewCell() }

            guard let vehicleLockCell = tableView.dequeueReusableCell(withIdentifier: VehicleLockStateButtonCell.kReuseId,
                                                                      for: indexPath) as? VehicleLockStateButtonCell
            else {
                return UITableViewCell()
            }

            vehicleLockCell.update(with: spec)
            return vehicleLockCell
        }
    }
}
