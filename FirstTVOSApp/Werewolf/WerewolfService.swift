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
    
    private var mpcService: MPCService?
    
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
        
        delegate?.didCreate(characters: characters)
        
//        let species = characters.map { $0.species }
        
//        synthesizer = AVSpeechSynthesizer()
//        synthesizer?.delegate = self
        
//        startNextFlow()
    }
    
    private func createCharactersRandomly(with mode: WerewolfGameMode) {
        let species = mode.getSpecies()
        var characters = [WerewolfCharacter]()
        
        species.forEach {
            let character = WerewolfCharacter(species: $0, group: $0.getGroup(), number: -1, superpower: $0.getSuperpowers())
            characters.append(character)
        }
        
        characters.shuffle()
        
        self.characters = characters
    }
    
    private func speech(for text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-TW")
        utterance.rate = 0.5
        
        synthesizer?.speak(utterance)
    }
    
    private func startNextFlow() {

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
