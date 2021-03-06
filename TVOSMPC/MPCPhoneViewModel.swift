//
//  MPCPhoneViewModel.swift
//  TVOSMPC
//
//  Created by Shan on 2020/2/19.
//  Copyright © 2020 ShanOvO. All rights reserved.
//

import Foundation
import UIKit

protocol MPCPhoneViewModelDelegate: class {
    func didUpdateCharacter(as title: String)
    
    func shouldDisableNumbers(range: MPCPhoneViewModel.effectNumberRange)
    
    func shouldShowWitchSaveAlert(number: Int)
    
    func shouldShowWitchKillsOrNotAlert()
    
    func shouldShowForecasterCanCheckAlert()
    
    func didGetForecastedResult(with title: String)
    
    func dayDidBreak(victims: MPCPhoneViewModel.VictimsAtRoundEnded)
    
    func didWaitForVote()
}

class MPCPhoneViewModel: NSObject {
    
    enum SelectionMode {
        case normalFlow
        case vote
    }
    
    private var mpcService: PhoneMPCService?
    
    weak var delegate: MPCPhoneViewModelDelegate?
    
    private var characters: [WerewolfCharacter] = [] {
        didSet {
            if let speciesTitle = findSelfCharacter()?.species.getTitle() {
                DispatchQueue.main.async {
                    self.delegate?.didUpdateCharacter(as: speciesTitle)
                }
            }
        }
    }
    
    private(set) var numberOfPlayers: Int? = 6
    
    private var lastExposedIdentityNumber: Int?
    
    private var mode: SelectionMode = .normalFlow
    
    override init() {
        super.init()
        
        mpcService = PhoneMPCService()
        mpcService?.delegate = self
        
    }
    
    private func findSelfCharacter() -> WerewolfCharacter? {
        let deviceName = UIDevice.current.name
        let filteredCharacter = characters.filter { $0.deviceName == deviceName }
        return filteredCharacter.first
    }
    
    private func removeSuperpower(_ superpower: WerewolfSuperpower) {
        let deviceName = UIDevice.current.name
        for (index, character) in characters.enumerated() {
            if character.deviceName == deviceName {
                characters[index].remove(superpower: superpower)
                break
            }
        }
    }
    
    func didSelectNumber(number: Int) {
                
        if mode == .normalFlow {
            guard let character = findSelfCharacter() else { return }
            if character.isWerewolf() {
                
                mpcService?.sendKilledTarget(targetNumber: number + 1)
                
            } else if character.isWitch() {
                // remove superpower
                removeSuperpower(.killPeople)
                
                // notify tv.
                mpcService?.sendWitchKilledTarget(targetNumber: number + 1)
            } else if character.isForecaster() {
                
                let targetNumber = number + 1
                
                lastExposedIdentityNumber = targetNumber
                
                let firstTarget = characters.filter { $0.number == targetNumber }.first
                
                guard let title = firstTarget?.species.getTitle() else { return }
                
                delegate?.didGetForecastedResult(with: title)
            }
        } else if mode == .vote {
            // Send selected target.
            mpcService?.sendVoteTarget(targetNumber: number + 1)
            // Change mode back.
            mode = .normalFlow
        }
    }
                
    func witchSavesVictimAction(witchSaves: Bool) {
        guard let character = findSelfCharacter() else { return }
        if character.isWitch() {
            // Remove superpower.
            removeSuperpower(.savePeople)
            
            mpcService?.sendWitchSavesResult(witchSaves: witchSaves)
        }
    }
    
    func witchNotKill() {
        mpcService?.sendWitchKilledTarget(targetNumber: nil)
    }
    
    func forecasterDoneAction() {
        guard let lastExposedIdentityNumber = lastExposedIdentityNumber else { return }
        
        mpcService?.sendForecastedTarget(targetNumber: lastExposedIdentityNumber)
    }
    
    func daybreakDoneAction() {
        mpcService?.sendHandShakeMessage()
    }
    
    func beginVoting() {
        mode = .vote
    }
}

extension MPCPhoneViewModel {
    enum effectNumberRange {
        case all
        case part(numbers: [Int])
    }
    
    enum VictimsAtRoundEnded {
        case none
        case others(content: String)
        case me(content: String)
    }
}

extension MPCPhoneViewModel: PhoneMPCServiceDelegate {
    
    func didUpdateCharacters(_ characters: [WerewolfCharacter]) {
        self.characters = characters
    }
    
    func didReceiveWerewolfShouldKill() {
        
        guard let character = findSelfCharacter() else { return }
        
        if character.isWerewolf() {
            let numbersThatCanBeKilledByWerewolf = characters.filter { !$0.canBeKilledByWerewolf() }.map { $0.getIndexFromNumber() }
            
            DispatchQueue.main.async {
                self.delegate?.shouldDisableNumbers(range: .part(numbers: numbersThatCanBeKilledByWerewolf))
            }
        } else {
            DispatchQueue.main.async {
                self.delegate?.shouldDisableNumbers(range: .all)
            }
        }
    }
    
    func didReceiveWitchSavesOrNot() {
        guard let character = findSelfCharacter() else { return }
        
        if character.isWitch() {
            let firstCharacterThatCanBeSaved = characters.filter { $0.canBeSavedByWitch() }.first
            
            guard let characterThatCanBeSaved = firstCharacterThatCanBeSaved else { return }
            
            let victimNumber = characterThatCanBeSaved.number
            
            DispatchQueue.main.async {
                self.delegate?.shouldShowWitchSaveAlert(number: victimNumber)
            }
        } else {
            DispatchQueue.main.async {
                self.delegate?.shouldDisableNumbers(range: .all)
            }
        }
    }
    
    func didReceiveWitchKillsOrNot() {
        
        guard let character = findSelfCharacter() else { return }
        
        if character.isWitch() {
            let charactersThatCanNotBeKilledByWitch = characters.filter { !$0.canBeKilledByWitch() }.map { $0.number - 1 }
            
            DispatchQueue.main.async {
                self.delegate?.shouldDisableNumbers(range: .part(numbers: charactersThatCanNotBeKilledByWitch))
                self.delegate?.shouldShowWitchKillsOrNotAlert()
            }
        } else {
            DispatchQueue.main.async {
                self.delegate?.shouldDisableNumbers(range: .all)
            }
        }
    }
    
    func didReceiveForecasterCanCheck() {
        
        guard let character = findSelfCharacter() else { return }
        
        if character.isForecaster() {
            let charactersThatCanNotBeForecasted = characters.filter { !$0.canBeForecasted() }.map { $0.number - 1 }
            
            DispatchQueue.main.async {
                self.delegate?.shouldDisableNumbers(range: .part(numbers: charactersThatCanNotBeForecasted))
                self.delegate?.shouldShowForecasterCanCheckAlert()
            }
        } else {
            DispatchQueue.main.async {
                self.delegate?.shouldDisableNumbers(range: .all)
            }
        }
    }
    
    func didReceiveDayDidBreak() {
        
        let isMeAbleToVote = ( characters.filter { $0.isMe() && $0.isAbleToVote() }.count != 0 )
        
        if isMeAbleToVote {
            
            guard let currentRound = characters.first?.currentRound else { return }
            
            let victims = characters.filter {
                guard let killedRound = $0.killedRound else { return false }
                return killedRound == currentRound
            }
            
            let victimTitles = victims.map { "\($0.number)號(\($0.species.getGroup()))" }
            
            let content = "受害者是：" + victimTitles.joined(separator: "、")
            
            let deadContent = (victims.count == 0 ) ? VictimsAtRoundEnded.none : VictimsAtRoundEnded.others(content: content)

            let deadCharacterNumbers = characters.filter { !$0.isAlive }.map { $0.number - 1 }

            DispatchQueue.main.async {
                self.delegate?.shouldDisableNumbers(range: .part(numbers: deadCharacterNumbers))
                self.delegate?.dayDidBreak(victims: deadContent)
            }
            
        } else { // The player was killed in this round so show a message to let the player know.
            
            // If that player was not killed in this round, should not show the killed message.
            let me = characters.filter { $0.isMe() }.first!
            
            guard let killRound = me.killedRound else { fatalError("Error in didReceiveDayDidBreak") }
            
            if killRound == me.currentRound {
                
                let deadContent = "你被殺了🥰🥰"
                DispatchQueue.main.async {
                    self.delegate?.shouldDisableNumbers(range: .all)
                    self.delegate?.dayDidBreak(victims: .me(content: deadContent))
                }
                
            } else {
                // Do nothing.
                mpcService?.sendHandShakeMessage()
            }
        }
    }
    
    func didWaitForPlayerToVote() {
        let isMeAbleToVote = ( characters.filter { $0.isMe() && $0.isAbleToVote() }.count != 0 )
        
        if isMeAbleToVote {
            
            let deadCharacterNumbers = characters.filter { !$0.isAlive }.map { $0.number - 1 }
            
            DispatchQueue.main.async {
                self.delegate?.shouldDisableNumbers(range: .part(numbers: deadCharacterNumbers))
                self.delegate?.didWaitForVote()
            }
            
        } else {    // Dead players can not vote.
            
            // do nothing.
            
        }
    }
}
