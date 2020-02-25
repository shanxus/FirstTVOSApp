//
//  WerewolfService.swift
//  FirstTVOSApp
//
//  Created by ShanOvO on 2020/2/16.
//  Copyright © 2020 ShanOvO. All rights reserved.
//

import Foundation
import AVFoundation

protocol WerewolfServiceDelegate: class {
    func didCreate(characters: [WerewolfCharacter])
    func didWaitForWerewolfToDecideNextVictim(currentVictimNumbers: [Int])
    
    func didWaitForWitchToSave(number: Int)
    func didWaitForWitchToKill(currentVictimNumbers: [Int])
}

class WerewolfService: NSObject {
            
    private var characters: [WerewolfCharacter] = []
    private var victimNumbers: [Int] = []
    
    private var synthesizer: AVSpeechSynthesizer?
    
    private var currentStage: Int = -1
    
    private(set) var gameMode: WerewolfGameMode
    
    weak var delegate: WerewolfServiceDelegate?
    
    init(mode: WerewolfGameMode) {
        self.gameMode = mode
        synthesizer = AVSpeechSynthesizer()
        super.init()
        
        synthesizer?.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleHandshake(_:)), name: NSNotification.Name.MPCHandshake, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleGotVictimFromWerewolf(_:)), name: NSNotification.Name.didGetWerewolfVictim, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleWitchDidSave), name: NSNotification.Name.witchDidSave, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleGotWitchSaveResult), name: NSNotification.Name.didGetWitchSaveResult, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleGotWitchVictim), name: NSNotification.Name.didGetWitchVictim, object: nil)
    }
    
    func startGame() {
        
        createCharactersRandomly(with: gameMode)
    }
    
    private func createCharactersRandomly(with mode: WerewolfGameMode) {
        var species = mode.getSpecies()
        var characters = [WerewolfCharacter]()
        
        /* Debug */
        
        let werewolf1 = WerewolfCharacter(species: .werewolf(count: 0), number: 0)
        let witch = WerewolfCharacter(species: .witch, number: 1)
        let werewolf2 = WerewolfCharacter(species: .werewolf(count: 1), number: 2)
        let forecaster = WerewolfCharacter(species: .forecaster, number: 3)
        let villager1 = WerewolfCharacter(species: .villager(count: 0), number: 4)
        let villager2 = WerewolfCharacter(species: .villager(count: 1), number: 5)
        
        characters.append(werewolf1)
        characters.append(witch)
        characters.append(werewolf2)
        characters.append(forecaster)
        characters.append(villager1)
        characters.append(villager2)
        
        self.characters = characters
        
        delegate?.didCreate(characters: characters)
        
        /* Release */
        
//        species.shuffle()
//
//        for (index, certainSpecies) in species.enumerated() {
//            let character = WerewolfCharacter(species: certainSpecies, number: index)
//            characters.append(character)
//        }
//
//        self.characters = characters
//
//        delegate?.didCreate(characters: characters)
    }
    
    private func speech(for text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-TW")
        utterance.rate = 0.5
                
        synthesizer?.speak(utterance)
    }
    
    @objc
    private func handleHandshake(_ notification: NSNotification) {
        startNextFlow(forceToIncreaseStage: false)
    }
    
    @objc
    private func handleGotVictimFromWerewolf(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo else { return }
        
        guard let targetNumber = userInfo[TVMPCService.didGetWerewolfVictimKey] as? Int else { return }

        let firstIndex = characters.firstIndex {
            $0.number == targetNumber
        }
        
        guard let index = firstIndex else { return }
        
        characters[index].isAlive = false

        victimNumbers.append(characters[index].number)
        
        startNextFlow(forceToIncreaseStage: true)
    }
    
    /// Remove superpower.
    @objc
    private func handleWitchDidSave() {
        let firstIndex = characters.firstIndex {
            $0.isWitch()
        }
        
        guard let index = firstIndex else { return }
        
        characters[index].superpower.removeAll {
            $0 == .savePeople
        }
    }
    
    @objc
    private func handleGotWitchSaveResult() {
        startNextFlow(forceToIncreaseStage: true)
    }
    
    @objc
    private func handleGotWitchVictim() {
        // Remove superpower.
        let firstIndex = characters.firstIndex {
            $0.isWitch()
        }
        
        guard let index = firstIndex else { return }
        
        characters[index].superpower.removeAll {
            $0 == .killPeople
        }
        
        // Start next flow.
        startNextFlow(forceToIncreaseStage: true)
    }
    
    func startNextFlow(forceToIncreaseStage: Bool) {
        
        if forceToIncreaseStage {
            print("[force to increase stage]")
            currentStage += 1
        }
        print("startNextFlow - current stage: \(currentStage)")
        
        if currentStage == WerewolfStage.preparingStage.rawValue {
            
            currentStage += 1
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.startNextFlow(forceToIncreaseStage: false)
            }
            
        } else if currentStage == WerewolfStage.everyoneClosesEyes.rawValue {
                        
            let stageScript = WerewolfStage.everyoneClosesEyes.getScript()
            speech(for: stageScript)
            
        } else if currentStage == WerewolfStage.werewolfOpensEyes.rawValue {
                        
            let stageScript = WerewolfStage.werewolfOpensEyes.getScript()
            speech(for: stageScript)
            
        } else if currentStage == WerewolfStage.werewolfDecidesVictim.rawValue {
                        
            let stageScript = WerewolfStage.werewolfDecidesVictim.getScript()
            speech(for: stageScript)
         
        } else if currentStage == WerewolfStage.werewolfClosesEyes.rawValue {
                        
            let stageScript = WerewolfStage.werewolfClosesEyes.getScript()
            speech(for: stageScript)
            
        } else if currentStage == WerewolfStage.witchOpenEyes.rawValue {
            
            let stageScript = WerewolfStage.witchOpenEyes.getScript()
            speech(for: stageScript)
            
        } else if currentStage == WerewolfStage.showWitchVictimMessage.rawValue {
            
            let stageScript = WerewolfStage.showWitchVictimMessage.getScript()
            speech(for: stageScript)
            
        } else if currentStage == WerewolfStage.witchKillsOrNot.rawValue {
            
            let stageScript = WerewolfStage.witchKillsOrNot.getScript()
            speech(for: stageScript)
            
        } else if currentStage == WerewolfStage.witchClosesEyes.rawValue {
            
            let stageScript = WerewolfStage.witchClosesEyes.getScript()
            speech(for: stageScript)
            
        }
    }
}

extension WerewolfService: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {

        print("did finish utterance - current stage: \(currentStage)")
        
        if currentStage == WerewolfStage.everyoneClosesEyes.rawValue {
            
            currentStage += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.startNextFlow(forceToIncreaseStage: false)
            }
            
        } else if currentStage == WerewolfStage.werewolfOpensEyes.rawValue {
            
            currentStage += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.startNextFlow(forceToIncreaseStage: false)
            }
            
        } else if currentStage == WerewolfStage.werewolfDecidesVictim.rawValue {
            
            delegate?.didWaitForWerewolfToDecideNextVictim(currentVictimNumbers: victimNumbers)
            
        } else if currentStage == WerewolfStage.werewolfClosesEyes.rawValue {
            
            currentStage += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.startNextFlow(forceToIncreaseStage: false)
            }
            
        } else if currentStage == WerewolfStage.witchOpenEyes.rawValue {
            
            guard let lastVictim = victimNumbers.last else {
                print("failed to get last victim")
                return
            }
                        
            currentStage += 1
            delegate?.didWaitForWitchToSave(number: lastVictim)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.startNextFlow(forceToIncreaseStage: false)
            }
            
        } else if currentStage == WerewolfStage.showWitchVictimMessage.rawValue {
            
            
            
        } else if currentStage == WerewolfStage.witchKillsOrNot.rawValue {
            
            delegate?.didWaitForWitchToKill(currentVictimNumbers: victimNumbers)
            
        } else if currentStage == WerewolfStage.witchClosesEyes.rawValue {
            
        }
    }
}
