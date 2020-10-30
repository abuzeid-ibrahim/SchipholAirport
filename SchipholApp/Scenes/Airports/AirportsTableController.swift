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
        super.init(nibName: nil, bundle: Bundle(for: AirportsTableController.self))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Unsupported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(AirportTableCell.self)
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
}

// MARK: - Private

private extension AirportsTableController {
    func bindToViewModel() {
        viewModel.reloadData.subscribe { [weak self] reload in
            DispatchQueue.main.async { if reload { self?.tableView.reloadData() } }
        }
        viewModel.isLoading.subscribe { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
//                    let size: CGSize = isLoading ? self.collectionView.bounds.size : .zero
//                    self.collectionView.updateFooter(size: size)
            }
        }
        viewModel.error.subscribe { [weak self] error in
            guard let self = self, let msg = error else { return }
            DispatchQueue.main.async { self.show(error: msg) }
        }
    }
}
