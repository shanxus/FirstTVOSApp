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
}

class MPCPhoneViewModel: NSObject {
    
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
    
    private(set) var victimNumbers: [Int] = []
    
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
                
        guard let character = findSelfCharacter() else { return }
        if character.isWerewolf() {
            
            mpcService?.sendKilledTarget(targetNumber: number + 1)
            
        } else if character.isWitch() {
            // remove superpower
            removeSuperpower(.killPeople)
            
            // notify tv.
            mpcService?.sendWitchKilledTarget(targetNumber: number + 1)
        } else if character.isForecaster() {
            
            mpcService?.sendForecastedTarget(targetNumber: number + 1)
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
        
    }
}

extension MPCPhoneViewModel {
    enum effectNumberRange {
        case all
        case part(numbers: [Int])
    }
}

extension MPCPhoneViewModel: PhoneMPCServiceDelegate {
    
    func didUpdateCharacters(_ characters: [WerewolfCharacter]) {
        self.characters = characters
    }
    
    func didReceiveWerewolfShouldKill(victimNumbers: [Int]) {
        
        guard let character = findSelfCharacter() else { return }
        
        if character.isWerewolf() {
            DispatchQueue.main.async {
                self.delegate?.shouldDisableNumbers(range: .part(numbers: victimNumbers))
            }
        } else {
            DispatchQueue.main.async {
                self.delegate?.shouldDisableNumbers(range: .all)
            }
        }
    }
    
    func didReceiveWitchSavesOrNot() {
        guard let character = findSelfCharacter(), character.isWitch() else { return }
        
        let firstCharacterThatCanBeSaved = characters.filter { $0.canBeSavedByWitch() }.first
        
        guard let characterThatCanBeSaved = firstCharacterThatCanBeSaved else { return }
        
        let victimNumber = characterThatCanBeSaved.number
        
        DispatchQueue.main.async {
            self.delegate?.shouldShowWitchSaveAlert(number: victimNumber)
        }
    }
    
    func didReceiveWitchKillsOrNot() {
        
        guard let character = findSelfCharacter(), character.isWitch() else { return }
        
        let charactersThatCanNotBeKilledByWitch = characters.filter { !$0.canBeKilledByWitch() }.map { $0.number - 1 }
        
        DispatchQueue.main.async {
            self.delegate?.shouldDisableNumbers(range: .part(numbers: charactersThatCanNotBeKilledByWitch))
            self.delegate?.shouldShowWitchKillsOrNotAlert()
        }
    }
    
    func didReceiveForecasterCanCheck() {
        
        guard let character = findSelfCharacter(), character.isForecaster() else { return }
        
        let charactersThatCanNotBeForecasted = characters.filter { !$0.canBeForecasted() }.map { $0.number - 1 }
        
        DispatchQueue.main.async {
            self.delegate?.shouldDisableNumbers(range: .part(numbers: charactersThatCanNotBeForecasted))
            self.delegate?.shouldShowForecasterCanCheckAlert()
        }
    }
}
