//
//  AirportsTableController.swift
//  SchipholApp
//
//  Created by abuzeid on 30.10.20.
//  Copyright © 2020 abuzeid. All rights reserved.
//

import UIKit

final class AirportsTableController: UITableViewController {
    private let viewModel: AirportsViewModelType
    private var dataList: [Airport] { viewModel.dataList }

    init(with viewModel: AirportsViewModelType = AirportsViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Unsupported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = ActivityIndicatorFooterView()
        tableView.register(AirportTableCell.self, forCellReuseIdentifier: AirportTableCell.identifier)
        bindToViewModel()
        viewModel.loadData()
    }
}

// MARK: - Table view data source

extension AirportsTableController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataList.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(cell: AirportTableCell.self, for: indexPath)
        cell.setData(for: dataList[indexPath.row])
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        AppNavigator.shared.push(.airportDetails(dataList[indexPath.row]))
    }
}

// MARK: - Private

private extension AirportsTableController {
    var indicator: ActivityIndicatorFooterView? {
        return tableView.tableFooterView as? ActivityIndicatorFooterView
    }

    func bindToViewModel() {
        viewModel.reloadData.subscribe { [weak self] reload in
            if reload { self?.tableView.reloadData() }
        }
        viewModel.isLoading.subscribe { [weak self] isLoading in
            guard let self = self else { return }
            self.tableView.sectionFooterHeight = isLoading ? 80 : 0
            self.indicator?.set(isLoading: isLoading)
        }
        viewModel.error.subscribe { [weak self] error in
            guard let self = self, let msg = error else { return }
            self.show(error: msg)
        }
    }
}
