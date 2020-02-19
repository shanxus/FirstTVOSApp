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
}

class WerewolfService: NSObject {
            
    private var characters: [WerewolfCharacter] = []
    
    private var synthesizer: AVSpeechSynthesizer?
    
    private var currentStage: Int = -1
    
    private(set) var gameMode: WerewolfGameMode
    
    weak var delegate: WerewolfServiceDelegate?
    
    init(mode: WerewolfGameMode) {
        self.gameMode = mode
        super.init()
    }
    
    func startGame() {
        
        createCharactersRandomly(with: gameMode)
        
        synthesizer = AVSpeechSynthesizer()
        synthesizer?.delegate = self
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

        guard (currentStage + 1) < WerewolfScript.allCases.count else { return }
        
        if currentStage == -1 {
            let stageScript = WerewolfScript.allCases[0].getScript()
            speech(for: stageScript)
        } else {
            let stageScript = WerewolfScript.allCases[currentStage + 1].getScript()
            speech(for: stageScript)
        }
        
    }
}

extension WerewolfService: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        currentStage += 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [unowned self] in
            self.startNextFlow()
        }
    }
}
