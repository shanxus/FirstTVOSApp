//
//  MPCPhoneViewModel.swift
//  TVOSMPC
//
//  Created by Shan on 2020/2/19.
//  Copyright © 2020 ShanOvO. All rights reserved.
//

import Foundation

protocol MPCPhoneViewModelDelegate: class {
    func didUpdateCharacter(as title: String)
    
    func shouldDisableNumbers(range: MPCPhoneViewModel.effectNumberRange)
    
    func shouldShowWitchSaveAlert(number: Int)
    
    func shouldShowWitchKillsOrNotAlert()
}

class MPCPhoneViewModel: NSObject {
    
    private var mpcService: PhoneMPCService?
    
    weak var delegate: MPCPhoneViewModelDelegate?
    
    private var character: WerewolfCharacter? {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.didUpdateCharacter(as: self?.character?.species.getTitle() ?? "--")
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
    
    func didSelectNumber(number: Int) {
                
        guard let character = character else { return }
        if character.isWerewolf() {
            
            mpcService?.sendKilledTarget(targetNumber: number + 1)
            
        } else if character.isWitch() {
            // remove superpower
            self.character?.superpower.removeAll {
                $0 == .killPeople
            }
            
            // notify tv.
            mpcService?.sendWitchKilledTarget(targetNumber: number + 1)
        }
    }
    
    func witchSavesVictimAction(witchSaves: Bool) {
        guard let character = character else { return }
        if character.isWitch() {
            // Remove superpower.
            self.character?.superpower.removeAll { (superpower: WerewolfSuperpower) -> Bool in
                superpower == .savePeople
            }
            
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
    func didReceiveCharacterInformation(character: WerewolfCharacter) {
        self.character = character
    }
    
    func didReceiveWerewolfShouldKill(victimNumbers: [Int]) {
        
        guard let character = character else { return }
        
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
    
    func didReceiveWitchSavesOrNot(victimNumber: Int) {
        guard let character = character, character.isWitch() else { return }
        
        if character.superpower.contains(.savePeople) {
            DispatchQueue.main.async {
                self.delegate?.shouldShowWitchSaveAlert(number: victimNumber)
            }
        } else {
            print("witch had saved one character !")
        }
    }
    
    func didReceiveWitchKillsOrNot(victimNumbers: [Int]) {
        
        guard let character = character, character.isWitch() else { return }
        
        self.victimNumbers = victimNumbers
        DispatchQueue.main.async {
            self.delegate?.shouldShowWitchKillsOrNotAlert()
        }
    }
}
