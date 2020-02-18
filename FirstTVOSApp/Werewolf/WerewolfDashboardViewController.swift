//
//  WerewolfDashboardViewController.swift
//  FirstTVOSApp
//
//  Created by ShanOvO on 2020/2/18.
//  Copyright © 2020 ShanOvO. All rights reserved.
//

import UIKit

class WerewolfDashboardViewController: UIViewController {

    /// Competitor list.
    @IBOutlet weak var competitorListTitleLabel: UILabel!
    @IBOutlet weak var werewolfCompetitorListTableView: UITableView!
    
    private var viewModel: WerewolfDashboardViewModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationController?.setNavigationBarHidden(true, animated: false)
        
        werewolfCompetitorListTableView.dataSource = self
        werewolfCompetitorListTableView.tableFooterView = UIView()
        
        viewModel = WerewolfDashboardViewModel()
        viewModel?.delegate = self
        viewModel?.StartBrowsingPeers()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        askForGameMode()
    }
    
    private func askForGameMode() {
        let alertController = UIAlertController(title: "遊戲模式", message: "請選擇狼人殺遊戲模式", preferredStyle: .actionSheet)
        
        let modeOne = UIAlertAction(title: "6 人", style: .default) { [weak self] (_) in
            self?.viewModel?.setGameMode(as: .people6)
        }
        
        let modeTwo = UIAlertAction(title: "9 人", style: .default) { [weak self] (_) in
            self?.viewModel?.setGameMode(as: .people6)
        }
        
        alertController.addAction(modeOne)
        alertController.addAction(modeTwo)
        
        navigationController?.present(alertController, animated: true, completion: nil)
    }
    
    private func updateCompetitorListTitle() {
        let currentCompetitorCount = viewModel?.numberOfCurrentCompetitor() ?? -1
        let totalCompetitorCount = viewModel?.targetCompetitorNumber() ?? -1
        
        let title = String(format: "參賽名單（%d/%d）", currentCompetitorCount, totalCompetitorCount)
        competitorListTitleLabel.text = title
    }

}

extension WerewolfDashboardViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel?.numberOfCurrentCompetitor() ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "WerewolfCompetitorTableViewCell", for: indexPath) as! WerewolfCompetitorTableViewCell
        
        cell.competitorNameLabel.text = viewModel?.competitorName(for: indexPath.row) ?? "--"
        
        return cell
    }
}

extension WerewolfDashboardViewController: WerewolfDashboardViewModelDelegate {
    func dataSourceDidUpdate() {
        werewolfCompetitorListTableView.reloadData()
        updateCompetitorListTitle()
    }
    
    func targetCompetitorNumberDidChange() {
        updateCompetitorListTitle()
    }
}

class WerewolfCompetitorTableViewCell: UITableViewCell {
    @IBOutlet weak var competitorNameLabel: UILabel!
}
