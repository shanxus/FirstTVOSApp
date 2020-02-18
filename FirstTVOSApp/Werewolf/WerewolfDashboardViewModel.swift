//
//  WerewolfDashboardViewModel.swift
//  FirstTVOSApp
//
//  Created by ShanOvO on 2020/2/18.
//  Copyright © 2020 ShanOvO. All rights reserved.
//

import Foundation

protocol WerewolfDashboardViewModelDelegate: class {
    func dataSourceDidUpdate()
    
    func targetCompetitorNumberDidChange()
}

class WerewolfDashboardViewModel: NSObject {
    
    weak var delegate: WerewolfDashboardViewModelDelegate?
    private var tvMPCService: MPCService?
    
    private var werewolfService: WerewolfService?
    
    override init() {
        super.init()
        
        tvMPCService = MPCService()
        tvMPCService?.delegate = self
    }
    
    func setGameMode(as mode: WerewolfGameMode) {
        werewolfService = WerewolfService(mode: mode)
        werewolfService?.delegate = self
        delegate?.targetCompetitorNumberDidChange()
    }
    
    func StartBrowsingPeers() {
        tvMPCService?.browse()
    }
    
    private func startGameFlowIfNeeded() {
        
        if true {
            werewolfService?.startGame()
        }
    }
    
    func numberOfCurrentCompetitor() -> Int {
        return tvMPCService?.connectedPeerIDs.count ?? 0
    }
    
    func competitorName(for index: Int) -> String {
        guard index < (tvMPCService?.connectedPeerIDs.count ?? 0) else { return "--" }
        return tvMPCService?.connectedPeerIDs[index].displayName ?? "--"
    }
    
    func targetCompetitorNumber() -> Int {
        return werewolfService?.gameMode.getPeopleCount() ?? -1
    }
}

extension WerewolfDashboardViewModel: TVMPCServiceDelegate {
    func connectedPeersDidChange() {
        delegate?.dataSourceDidUpdate()
    }
}

extension WerewolfDashboardViewModel: WerewolfServiceDelegate {
    func didCreate(characters: [WerewolfCharacter]) {
        
    }
}