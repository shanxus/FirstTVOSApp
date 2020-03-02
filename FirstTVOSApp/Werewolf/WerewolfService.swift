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
    func shouldUpdateCharacters(characters: [WerewolfCharacter])
    
    func didCreate(characters: inout [WerewolfCharacter])
    func didWaitForWerewolfToDecideNextVictim(currentVictimNumbers: [Int])
    
    func didWaitForWitchToSave()
    func didWaitForWitchToKill(characters: [WerewolfCharacter])
    
    func didWaitForecasterToCheck(characters: [WerewolfCharacter])
    
    func dayDidBreak()
}

class WerewolfService: NSObject {
            
    private(set) var characters: [WerewolfCharacter] = []
    private var victimNumbers: [Int] = []
    
    private var synthesizer: AVSpeechSynthesizer?
    
    private var round: Int = 1
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleGotWitchVictim(_:)), name: NSNotification.Name.didGetWitchVictim, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleGotForecasterCheckedTarget(_:)), name: NSNotification.Name.didGetForecasterCheckedTarget, object: nil)
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
        characters.append(forecaster)
        characters.append(werewolf2)        
        characters.append(villager1)
        characters.append(villager2)
        
        self.characters = characters
        
        delegate?.didCreate(characters: &self.characters)
        
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
        
        characters[index].setKilled(at: round)

        victimNumbers.append(characters[index].number)
        
        startNextFlow(forceToIncreaseStage: true)
    }
    
    @objc
    private func handleWitchDidSave() {
        let witchFirstIndex = characters.firstIndex {
            $0.isWitch()
        }
        
        guard let witchIndex = witchFirstIndex else { return }
    
        // Remove superpower.
        characters[witchIndex].superpowers.removeAll {
            $0 == .savePeople
        }
        
        let firstSavedIndex = characters.firstIndex {
            $0.killedRound == currentStage
        }
        
        guard let savedIndex = firstSavedIndex else { return }
        
        // Set character saved.
        characters[savedIndex].setSaved()
    }
    
    @objc
    private func handleGotWitchSaveResult() {
        startNextFlow(forceToIncreaseStage: true)
    }
    
    @objc
    private func handleGotWitchVictim(_ notification: NSNotification) {
        
        let witchFirstIndex = characters.firstIndex {
            $0.isWitch()
        }
        
        guard let witchIndex = witchFirstIndex else { return }
        
        // Remove superpower.
        characters[witchIndex].superpowers.removeAll {
            $0 == .killPeople
        }
        
        guard let userInfo = notification.userInfo as? [String : Any] else { return }
        
        guard let witchKilledNumber = userInfo[TVMPCService.didGetWitchVictimKey] as? Int else { return }
        
        let targetIndex = characters.firstIndex {
            $0.number == witchKilledNumber
        }
        
        guard let victimIndex = targetIndex else { return }
        
        print("victimIndex: \(victimIndex)")
        
        // Set character as killed.
        characters[victimIndex].setKilled(at: round)
        
        // Start next flow.
        startNextFlow(forceToIncreaseStage: false)
    }
    
    @objc
    private func handleGotForecasterCheckedTarget(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo as? [String : Any] else { return }
        guard let targetNumber = userInfo[TVMPCService.didGetForecasterCheckedTargetKey] as? Int else { return }
        
        let firstIndex = characters.firstIndex { $0.number == targetNumber }
        guard let index = firstIndex else { return }
        
        characters[index].isIdentityExposed = true
        
        startNextFlow(forceToIncreaseStage: false)
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
            
        } else if currentStage == WerewolfStage.witchWillSave.rawValue {
            
            let stageScript = WerewolfStage.witchWillSave.getScript()
            speech(for: stageScript)
            
        } else if currentStage == WerewolfStage.showWitchVictimMessage.rawValue {
            
            let stageScript = WerewolfStage.showWitchVictimMessage.getScript()
            speech(for: stageScript)
            
        } else if currentStage == WerewolfStage.witchWillKill.rawValue {
            
            let stageScript = WerewolfStage.witchWillKill.getScript()
            speech(for: stageScript)
            
        } else if currentStage == WerewolfStage.witchKillsOrNot.rawValue {
            
            let stageScript = WerewolfStage.witchKillsOrNot.getScript()
            speech(for: stageScript)
            
        } else if currentStage == WerewolfStage.witchClosesEyes.rawValue {
            
            let stageScript = WerewolfStage.witchClosesEyes.getScript()
            speech(for: stageScript)
            
        } else if currentStage == WerewolfStage.forecasterOpensEyes.rawValue {
            
            let stageScript = WerewolfStage.forecasterOpensEyes.getScript()
            speech(for: stageScript)
            
            // Should pass information of victims to TV side (especially for the last round).
        } else if currentStage == WerewolfStage.forecasterWillCheck.rawValue {
            
            currentStage += 1
            DispatchQueue.main.async {
                self.delegate?.shouldUpdateCharacters(characters: self.characters)
            }
            
        } else if currentStage == WerewolfStage.forecasterChecks.rawValue {
            
            let stageScript = WerewolfStage.forecasterChecks.getScript()
            speech(for: stageScript)
            
        } else if currentStage == WerewolfStage.forecasterClosesEyes.rawValue {
            
            let stageScript = WerewolfStage.forecasterClosesEyes.getScript()
            speech(for: stageScript)
            
        } else if currentStage == WerewolfStage.everyoneWillOpenEyes.rawValue {
            
            currentStage += 1
            DispatchQueue.main.async {
                self.delegate?.shouldUpdateCharacters(characters: self.characters)
            }
            
        } else if currentStage == WerewolfStage.everyoneOpensEyes.rawValue {
            
            let stageScript = WerewolfStage.everyoneOpensEyes.getScript()
            speech(for: stageScript)
            
        } else if currentStage == WerewolfStage.countdownForVoting.rawValue {
            print("[stage to WerewolfStage.countdownForVoting]")
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
            
            DispatchQueue.main.async {
                self.delegate?.didWaitForWerewolfToDecideNextVictim(currentVictimNumbers: self.victimNumbers)
            }
            
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
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.startNextFlow(forceToIncreaseStage: false)
            }
            
        } else if currentStage == WerewolfStage.witchWillSave.rawValue {
            
            currentStage += 1
            DispatchQueue.main.async {
                self.delegate?.shouldUpdateCharacters(characters: self.characters)
            }
            
        } else if currentStage == WerewolfStage.showWitchVictimMessage.rawValue {
            
            currentStage += 1
            DispatchQueue.main.async {
                self.delegate?.didWaitForWitchToSave()
            }
            
        } else if currentStage == WerewolfStage.witchWillKill.rawValue {
            
            currentStage += 1
            DispatchQueue.main.async {
                self.delegate?.shouldUpdateCharacters(characters: self.characters)
            }
            
        } else if currentStage == WerewolfStage.witchKillsOrNot.rawValue {
                        
            currentStage += 1
            DispatchQueue.main.async {
                self.delegate?.didWaitForWitchToKill(characters: self.characters)
            }
            
        } else if currentStage == WerewolfStage.witchClosesEyes.rawValue {
            
            currentStage += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.startNextFlow(forceToIncreaseStage: false)
            }
            
        } else if currentStage == WerewolfStage.forecasterOpensEyes.rawValue {
            
            currentStage += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.startNextFlow(forceToIncreaseStage: false)
            }
            
        } else if currentStage == WerewolfStage.forecasterWillCheck.rawValue {
            
        } else if currentStage == WerewolfStage.forecasterChecks.rawValue {
            
            currentStage += 1
            DispatchQueue.main.async {
                self.delegate?.didWaitForecasterToCheck(characters: self.characters)
            }
        } else if currentStage == WerewolfStage.forecasterClosesEyes.rawValue {
            
            currentStage += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.startNextFlow(forceToIncreaseStage: false)
            }
        } else if currentStage == WerewolfStage.everyoneWillOpenEyes.rawValue {
            
        } else if currentStage == WerewolfStage.everyoneOpensEyes.rawValue {
            
            currentStage += 1
            DispatchQueue.main.async {
                self.delegate?.dayDidBreak()
            }
        }
    }
}
