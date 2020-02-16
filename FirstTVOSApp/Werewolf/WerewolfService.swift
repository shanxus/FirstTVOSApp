//
//  WerewolfService.swift
//  FirstTVOSApp
//
//  Created by ShanOvO on 2020/2/16.
//  Copyright © 2020 ShanOvO. All rights reserved.
//

import Foundation

class WerewolfService: NSObject {
    
    static let shared = WerewolfService()
    
    
    
    private override init() {
        super.init()
    }
    
    func startGame(with mode: WerewolfGameMode) {
        let characterTitles = mode.getCharacters()
        
        var characters = [WerewolfCharacter]()
        
        for title in characterTitles {
            let character = WerewolfCharacter(title: title, group: title.getGroup(), number: <#T##Int#>, superpower: <#T##WerewolfSuperpower#>)
            
        }
    }
    
}
