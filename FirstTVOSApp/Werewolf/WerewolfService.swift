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
    func didWaitForWerewolfToDecideVictim()
}

class WerewolfService: NSObject {
            
    private var characters: [WerewolfCharacter] = []
    
    private var synthesizer: AVSpeechSynthesizer?
    
    private var currentStage: Int = -1
    
    private(set) var gameMode: WerewolfGameMode
    
    weak var delegate: WerewolfServiceDelegate?
    
    init(mode: WerewolfGameMode) {
        self.gameMode = mode
        synthesizer = AVSpeechSynthesizer()
        super.init()
        
        synthesizer?.delegate = self
    }
    
    func startGame() {
        
        createCharactersRandomly(with: gameMode)
    }
    
    private func createCharactersRandomly(with mode: WerewolfGameMode) {
        var species = mode.getSpecies()
        var characters = [WerewolfCharacter]()
        
        species.shuffle()
        
        for (index, certainSpecies) in species.enumerated() {
            let character = WerewolfCharacter(species: certainSpecies, number: index)
            characters.append(character)
        }
        
        self.characters = characters
        
        delegate?.didCreate(characters: characters)
    }
    
    private func speech(for text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-TW")
        utterance.rate = 0.5
                
        synthesizer?.speak(utterance)
    }
    
    func startNextFlow() {
        print("startNextFlow - current stage: \(currentStage)")
        
        if currentStage == WerewolfStage.preparingStage.rawValue {
            
            let stageScript = WerewolfStage.everyoneClosesEyes.getScript()
            speech(for: stageScript)
            
        } else if currentStage == WerewolfStage.everyoneClosesEyes.rawValue {
            
            let stageScript = WerewolfStage.werewolfOpensEyes.getScript()
            speech(for: stageScript)
            
        } else if currentStage == WerewolfStage.werewolfOpensEyes.rawValue {
            
            let stageScript = WerewolfStage.werewolfDecidesVictim.getScript()
            speech(for: stageScript)
            
        } else if currentStage == WerewolfStage.werewolfDecidesVictim.rawValue {
            
            let stageScript = WerewolfStage.werewolfClosesEyes.getScript()
            speech(for: stageScript)
            
        }
    }
}

extension WerewolfService: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {

        print("did finish utterance - current stage: \(currentStage)")
        
        if currentStage == WerewolfStage.preparingStage.rawValue {
            
            currentStage += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.startNextFlow()
            }
            
        } else if currentStage == WerewolfStage.everyoneClosesEyes.rawValue {
            
            currentStage += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.startNextFlow()
            }
            
        } else if currentStage == WerewolfStage.werewolfOpensEyes.rawValue {
            
            currentStage += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.startNextFlow()
            }
            
        } else if currentStage == WerewolfStage.werewolfDecidesVictim.rawValue {
            
            currentStage += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.startNextFlow()
            }
            
        }
    }
}
