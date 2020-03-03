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
    func didWaitForWerewolfToDecideNextVictim()
    
    func didWaitForWitchToSave()
    func didWaitForWitchToKill(characters: [WerewolfCharacter])
    
    func didWaitForecasterToCheck(characters: [WerewolfCharacter])
    
    func dayDidBreak()
    
    func shouldStartCountdownForVoting()
    func didWaitForVote()
    
    func gameDidOver(doesGoodSideWin: Bool)
}

class WerewolfService: NSObject {
            
    private(set) var characters: [WerewolfCharacter] = []
    
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleVoteResult(_:)), name: NSNotification.Name.didGetVoteResult, object: nil)
    }
    
    func startGame() {
        
        createCharactersRandomly(with: gameMode)
    }
    
    private func createCharactersRandomly(with mode: WerewolfGameMode) {
        var species = mode.getSpecies()
        var characters = [WerewolfCharacter]()
        
        /* Debug */
        
        let werewolf1 = WerewolfCharacter(species: .werewolf(count: 0), number: 1)
        let witch = WerewolfCharacter(species: .witch, number: 2)
        let werewolf2 = WerewolfCharacter(species: .werewolf(count: 1), number: 3)
        let forecaster = WerewolfCharacter(species: .forecaster, number: 4)
        let villager1 = WerewolfCharacter(species: .villager(count: 0), number: 5)
        let villager2 = WerewolfCharacter(species: .villager(count: 1), number: 6)
        
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
//            let character = WerewolfCharacter(species: certainSpecies, number: index + 1)
//            characters.append(character)
//        }
//
//        self.characters = characters
//
//        delegate?.didCreate(characters: characters)
    }
    
    private func speak(for text: String, shouldTraceAfterFinish: Bool) {
        if shouldTraceAfterFinish {
            
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = AVSpeechSynthesisVoice(language: "zh-TW")
            utterance.rate = 0.5
                    
            synthesizer?.speak(utterance)
            
        } else {
         
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = AVSpeechSynthesisVoice(language: "zh-TW")
            utterance.rate = 0.5
            
            let synthesizer = AVSpeechSynthesizer()
            synthesizer.speak(utterance)
            
        }
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
            $0.killedRound == round
        }
        
        guard let savedIndex = firstSavedIndex else { return }
        
        // Set character saved.
        characters[savedIndex].setSaved()
    }
    
    @objc
    private func handleGotWitchSaveResult() {
        startNextFlow(forceToIncreaseStage: false)
    }
    
    @objc
    private func handleGotWitchVictim(_ notification: NSNotification) {
        
        let witchFirstIndex = characters.firstIndex {
            $0.isWitch()
        }
        
        guard let witchIndex = witchFirstIndex else { return }
        
        // Remove superpower.
        characters[witchIndex].superpowers.removeAll {
            $0 == .poisonPeople
        }
        
        guard let userInfo = notification.userInfo as? [String : Any] else { return }
        
        if let witchKilledNumber = userInfo[TVMPCService.didGetWitchVictimKey] as? Int {
            
            let targetIndex = characters.firstIndex {
                $0.number == witchKilledNumber
            }
            
            guard let victimIndex = targetIndex else { return }
            
            // Set character as killed.
            characters[victimIndex].setKilled(at: round)
            
        }
                        
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
    
    @objc
    private func handleVoteResult(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo as? [String : Any], let result = userInfo[TVMPCService.voteResultKey] as? TVMPCService.voteResult else { return }
        
        print("user info: \(userInfo)")
        switch result {
        case .divorce(let winner):  // set killed for player.
            let number = winner.0
            
            let firstIndex = characters.firstIndex {
                $0.number == number
            }
            
            guard let killedIndex = firstIndex else { return }
            
            characters[killedIndex].setKilled(at: round)
            
            speak(for: "投票結果，\(number)號玩家出局", shouldTraceAfterFinish: false)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                self.startNextFlow(forceToIncreaseStage: true)
            }
            
        case .tie(_):  // revote.
            
            speak(for: "票數相同，請重新投票", shouldTraceAfterFinish: false)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                self.startNextFlow(forceToIncreaseStage: false)
            }
        }
    }
    
    func startNextFlow(forceToIncreaseStage: Bool) {
        
        if forceToIncreaseStage {
            currentStage += 1
            print("[force to increase stage, current stage: \(currentStage)]")
        }
        print("[current stage: \(currentStage)]")
        
        if currentStage == WerewolfStage.preparingStage.rawValue {
            
            currentStage += 1
            delegate?.shouldUpdateCharacters(characters: self.characters)
            
        } else if currentStage == WerewolfStage.everyoneClosesEyes.rawValue {
                        
            let stageScript = WerewolfStage.everyoneClosesEyes.getScript()
            speak(for: stageScript, shouldTraceAfterFinish: true)
            
        } else if currentStage == WerewolfStage.werewolfOpensEyes.rawValue {
                        
            let stageScript = WerewolfStage.werewolfOpensEyes.getScript()
            speak(for: stageScript, shouldTraceAfterFinish: true)
            
        } else if currentStage == WerewolfStage.werewolfDecidesVictim.rawValue {
                        
            let stageScript = WerewolfStage.werewolfDecidesVictim.getScript()
            speak(for: stageScript, shouldTraceAfterFinish: true)
         
        } else if currentStage == WerewolfStage.werewolfClosesEyes.rawValue {
                        
            let stageScript = WerewolfStage.werewolfClosesEyes.getScript()
            speak(for: stageScript, shouldTraceAfterFinish: true)
            
        } else if currentStage == WerewolfStage.witchOpenEyes.rawValue {
            
            let stageScript = WerewolfStage.witchOpenEyes.getScript()
            speak(for: stageScript, shouldTraceAfterFinish: true)
            
        } else if currentStage == WerewolfStage.witchWillSave.rawValue {
            
            let stageScript = WerewolfStage.witchWillSave.getScript()
            speak(for: stageScript, shouldTraceAfterFinish: true)
            
        } else if currentStage == WerewolfStage.showWitchVictimMessage.rawValue {
            
            let stageScript = WerewolfStage.showWitchVictimMessage.getScript()
            speak(for: stageScript, shouldTraceAfterFinish: true)
            
        } else if currentStage == WerewolfStage.witchWillKill.rawValue {
            
            let stageScript = WerewolfStage.witchWillKill.getScript()
            speak(for: stageScript, shouldTraceAfterFinish: true)
            
        } else if currentStage == WerewolfStage.witchKillsOrNot.rawValue {
            
            let stageScript = WerewolfStage.witchKillsOrNot.getScript()
            speak(for: stageScript, shouldTraceAfterFinish: true)
            
        } else if currentStage == WerewolfStage.witchClosesEyes.rawValue {
            
            let stageScript = WerewolfStage.witchClosesEyes.getScript()
            speak(for: stageScript, shouldTraceAfterFinish: true)
            
        } else if currentStage == WerewolfStage.forecasterOpensEyes.rawValue {
            
            let stageScript = WerewolfStage.forecasterOpensEyes.getScript()
            speak(for: stageScript, shouldTraceAfterFinish: true)
            
            // Should pass information of victims to TV side (especially for the last round).
        } else if currentStage == WerewolfStage.forecasterWillCheck.rawValue {
            
            currentStage += 1
            DispatchQueue.main.async {
                self.delegate?.shouldUpdateCharacters(characters: self.characters)
            }
            
        } else if currentStage == WerewolfStage.forecasterChecks.rawValue {
            
            let stageScript = WerewolfStage.forecasterChecks.getScript()
            speak(for: stageScript, shouldTraceAfterFinish: true)
            
        } else if currentStage == WerewolfStage.forecasterClosesEyes.rawValue {
            
            let stageScript = WerewolfStage.forecasterClosesEyes.getScript()
            speak(for: stageScript, shouldTraceAfterFinish: true)
            
        } else if currentStage == WerewolfStage.everyoneWillOpenEyes.rawValue {
            
            currentStage += 1
            DispatchQueue.main.async {
                self.delegate?.shouldUpdateCharacters(characters: self.characters)
            }
            
        } else if currentStage == WerewolfStage.everyoneOpensEyes.rawValue {
            
            let stageScript = WerewolfStage.everyoneOpensEyes.getScript()
            speak(for: stageScript, shouldTraceAfterFinish: true)
            
        } else if currentStage == WerewolfStage.countdownForVoting.rawValue {
            print("[stage to WerewolfStage.countdownForVoting]")
            
            let stageScript = WerewolfStage.countdownForVoting.getScript()
            speak(for: stageScript, shouldTraceAfterFinish: true)
            
        } else if currentStage == WerewolfStage.vote.rawValue {
            
            let stageScript = WerewolfStage.vote.getScript()
            speak(for: stageScript, shouldTraceAfterFinish: true)
            
        } else if currentStage == WerewolfStage.checkGameOver.rawValue {
        
            let stageScript = WerewolfStage.checkGameOver.getScript()
            speak(for: stageScript, shouldTraceAfterFinish: true)
            
        } else if currentStage == WerewolfStage.roundEnded.rawValue {
            
            let stageScript = WerewolfStage.roundEnded.getScript()
            speak(for: stageScript, shouldTraceAfterFinish: true)
            
        }
    }
    
    private func setRoundEnded(isGameOver: Bool) {
        print("[setRoundEnded with isGameOver: \(isGameOver)]")
        if isGameOver {
            
            speak(for: "遊戲結束", shouldTraceAfterFinish: false)
            
            // Prepare for rematch.
            
        } else {
            currentStage = WerewolfStage.roundEnded.rawValue
            round += 1
                
            for i in 0..<characters.count {
                characters[i].currentRound = round
            }
            
            startNextFlow(forceToIncreaseStage: false)
        }
    }
    
    private func checkVictoryCondition() {
        if hasBadSideWin() {
            delegate?.gameDidOver(doesGoodSideWin: false)
            speak(for: "壞人勝利", shouldTraceAfterFinish: false)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.setRoundEnded(isGameOver: true)
            }
            
        } else if doesGoodSideWin() {
            delegate?.gameDidOver(doesGoodSideWin: true)
            speak(for: "好人勝利", shouldTraceAfterFinish: false)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.setRoundEnded(isGameOver: true)
            }
            
        } else {
            setRoundEnded(isGameOver: false)
        }
    }
    
    private func doesGoodSideWin() -> Bool {
        let aliveBadMembers = characters.filter { (character: WerewolfCharacter) -> Bool in
            let group = character.species.getGroup()
            return (group == .bad && character.isAlive)
        }
        
        return aliveBadMembers.count == 0
    }
    
    private func hasBadSideWin() -> Bool {
        
        let aliveWerewolf = characters.filter { $0.isAlive && $0.isWerewolf() }
        let aliveMembers = characters.filter { $0.isAlive }
        
        if aliveWerewolf.count == 2 {   // Note: the number of werewolf should be decided depends on the count of players.
            
            if aliveMembers.count <= 4 {    // Condition: two alive werewolves, and the count for the alive members are four.
                return true
            } else {
                return false
            }
            
        } else if aliveWerewolf.count == 1 {
            
            return (aliveMembers.count == 2)
            
        } else if aliveWerewolf.count == 0 {
            return false
        } else {
            fatalError("Error in hasBadSideWin")
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
                self.delegate?.didWaitForWerewolfToDecideNextVictim()
            }
            
        } else if currentStage == WerewolfStage.werewolfClosesEyes.rawValue {
            
            currentStage += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.delegate?.shouldUpdateCharacters(characters: self.characters)
            }
            
        } else if currentStage == WerewolfStage.witchOpenEyes.rawValue {
            
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
            
            // See if there is an alive witch and able to save victim.
            let filteredWitch = characters.filter { $0.isWitch() && $0.isAbleToSave() }
            
            if filteredWitch.count == 0 {
                print("There is no alive witch")
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.startNextFlow(forceToIncreaseStage: true)
                }
            } else {
                
                let firstFilteredWitch = characters.filter { (character: WerewolfCharacter) -> Bool in
                    guard let killRound = character.killedRound else { return false }
                    return killRound == round && character.isWitch()
                }.first
                
                if firstFilteredWitch != nil {  // Witch is killed in this round so he/she can not save himself/herself.
                    print("Witch is killed in this round, he/she can not save himself/herself")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.startNextFlow(forceToIncreaseStage: true)
                    }
                } else {
                
                    currentStage += 1
                    DispatchQueue.main.async {
                        self.delegate?.didWaitForWitchToSave()
                    }
                }
            }
            
        } else if currentStage == WerewolfStage.witchWillKill.rawValue {
            
            currentStage += 1
            DispatchQueue.main.async {
                self.delegate?.shouldUpdateCharacters(characters: self.characters)
            }
            
        } else if currentStage == WerewolfStage.witchKillsOrNot.rawValue {
                        
            // See if there is an alive witch and able to poison people.
            let filteredWitch = characters.filter { $0.isWitch() && $0.isAbleToPoison() }
            
            if filteredWitch.count == 0 {
                print("There is no alive witch")
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.startNextFlow(forceToIncreaseStage: true)
                }
            } else {
                currentStage += 1
                DispatchQueue.main.async {
                    self.delegate?.didWaitForWitchToKill(characters: self.characters)
                }
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
            
            let filteredForecaster = characters.filter { $0.isForecaster() && $0.isAbleToForecast() }
            
            if filteredForecaster.count == 0 {
                print("There is no alive forecaster.")
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.startNextFlow(forceToIncreaseStage: true)
                }
            } else {
                currentStage += 1
                DispatchQueue.main.async {
                    self.delegate?.didWaitForecasterToCheck(characters: self.characters)
                }
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
            
        } else if currentStage == WerewolfStage.countdownForVoting.rawValue {
            
            currentStage += 1
            DispatchQueue.main.async {
                self.delegate?.shouldStartCountdownForVoting()
            }
        } else if currentStage == WerewolfStage.vote.rawValue {
            
            // Not increase the current stage here. It depends on the vote result to decide continuing to the next stage or not .
            
            delegate?.didWaitForVote()
            
        } else if currentStage == WerewolfStage.checkGameOver.rawValue {
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.checkVictoryCondition()
            }
            
        } else if currentStage == WerewolfStage.roundEnded.rawValue {
            
            currentStage = -1
            startNextFlow(forceToIncreaseStage: false)
            
        }
    }
}

extension WerewolfService: TVMPCServiceDataSource {
    func aliveMemberCount() -> Int {
        return characters.filter { $0.isAlive }.count
    }
    
    func connectedAliveMemberCount(connectedPeerIDs: [String]) -> Int {
        let filteredCharacters = characters.filter { connectedPeerIDs.contains($0.deviceName) && $0.isAlive }
        return filteredCharacters.count
    }
}
