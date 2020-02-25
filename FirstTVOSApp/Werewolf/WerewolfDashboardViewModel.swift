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
    private var tvMPCService: TVMPCService?
    
    private var werewolfService: WerewolfService?
    
    override init() {
        super.init()
        
        tvMPCService = TVMPCService()
        tvMPCService?.delegate = self
    }
    
    func setGameMode(as mode: WerewolfGameMode) {
        werewolfService = WerewolfService(mode: mode)
        werewolfService?.delegate = self
        
        DispatchQueue.main.async {
            self.delegate?.targetCompetitorNumberDidChange()
        }
    }
    
    func StartBrowsingPeers() {
        tvMPCService?.browse()
    }
    
    private func startGameFlowIfNeeded() {
        
        #if DEBUG
        
        if (tvMPCService?.connectedPeerIDs.count ?? 0) > 1 {
            print("[start game]")
            werewolfService?.startGame()
        }
        
        #else
        
        guard let requiredPeople = werewolfService?.gameMode.getPeopleCount() else { return }
        
        #endif
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
        DispatchQueue.main.async {
            self.delegate?.dataSourceDidUpdate()
        }
        
        startGameFlowIfNeeded()
    }
}

extension WerewolfDashboardViewModel: WerewolfServiceDelegate {
    func didCreate(characters: [WerewolfCharacter]) {
        
        tvMPCService?.sendCharacterInfoToClients(characters)
    }
    
    func didWaitForWerewolfToDecideNextVictim(currentVictimNumbers: [Int]) {
        tvMPCService?.notifyWerewolfToKill(currentVictimNumbers: currentVictimNumbers)
    }
    
    func didWaitForWitchToSave(number: Int) {
        tvMPCService?.notifyWitchToSave(number: number)
    }
    
    func didWaitForWitchToKill(currentVictimNumbers: [Int]) {
        tvMPCService?.notifyWitchToKill(currentVictimNumbers: currentVictimNumbers)
    }
}
