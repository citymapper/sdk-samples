//
//  ApiSelectionViewController.swift
//  DemoMapper
//
//  Created by Tom Humphrey on 10/03/2021.
//

import UIKit

class ApiSelectionViewController: UIViewController {
    private let viewModel: ApiSelectionViewModel

    private lazy var apiPicker: UIPickerView = {
        let picker = UIPickerView()
        picker.dataSource = self.viewModel
        picker.delegate = self.viewModel
        return picker
    }()

    private func dismissButtonTitle() -> String {
        NSLocalizedString("Dismiss_And_Save_Modal_Screen_Button_Title", comment: "The title of the button used to save and dismiss the api selection screen")
    }

    private lazy var doneButton: UIButton = {
        let button = UIButton(primaryAction: UIAction { [weak self] _ in
            self?.doneButtonTapped()
        })
        button.titleLabel?.font = .boldSystemFont(ofSize: 22)
        button.setTitle(self.dismissButtonTitle(), for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor.systemBlue
        button.layer.cornerRadius = 10
        return button
    }()

    init(viewModel: ApiSelectionViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        view.addSubview(apiPicker)
        apiPicker.selectRow(viewModel.selectedRowIndex,
                            inComponent: 0,
                            animated: false)
        view.addSubview(doneButton)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let horizontalMargin: CGFloat = 15
        let buttonWidth = view.bounds.width - (horizontalMargin + horizontalMargin)
        let buttonHeight = doneButton.sizeThatFits(CGSize(width: buttonWidth,
                                                          height: .greatestFiniteMagnitude)).height

        doneButton.frame.size = CGSize(width: buttonWidth,
                                       height: buttonHeight)
        doneButton.center = CGPoint(x: view.bounds.midX,
                                    y: view.bounds.height - (view.safeAreaInsets.bottom + buttonHeight))

        let pickerHeight: CGFloat = 400
        apiPicker.frame = CGRect(x: 0,
                                 y: doneButton.frame.minY - (20 + pickerHeight),
                                 width: view.bounds.width,
                                 height: pickerHeight)
    }

    private func doneButtonTapped() {
        viewModel.selectApi(atRow: apiPicker.selectedRow(inComponent: 0))
        dismiss(animated: true, completion: nil)
    }
}
