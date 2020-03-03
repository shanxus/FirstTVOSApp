//
//  WerewolfModel.swift
//  FirstTVOSApp
//
//  Created by ShanOvO on 2020/2/16.
//  Copyright © 2020 ShanOvO. All rights reserved.
//

import Foundation
import UIKit

enum WerewolfStage: Int, CaseIterable {
    case preparingStage         = -1
    case everyoneClosesEyes     = 0
    
    case werewolfOpensEyes      = 1
    case werewolfDecidesVictim  = 2
    case werewolfClosesEyes     = 3
    
    case witchOpenEyes          = 4
    case witchWillSave          = 5
    case showWitchVictimMessage = 6
    case witchWillKill          = 7
    case witchKillsOrNot        = 8
    case witchClosesEyes        = 9
    
    case forecasterOpensEyes    = 10
    case forecasterWillCheck    = 11
    case forecasterChecks       = 12
    case forecasterClosesEyes   = 13
    
    // Show an alert about the victim.
    case everyoneWillOpenEyes   = 14
    case everyoneOpensEyes      = 15
    
    // Countdown for voting.
    case countdownForVoting     = 16
    
    // Wait everyone to vote.
    case vote                   = 17
    case checkGameOver          = 18
    case roundEnded             = 19
    
    func getScript() -> String {
        switch self {
        case .everyoneClosesEyes:
            return "天黑了，請閉眼"
        case .werewolfOpensEyes:
            return "狼人請睜眼，互相確認身份"
        case .werewolfDecidesVictim:
            return "請輸入狼人要殺的號碼"
        case .werewolfClosesEyes:
            return "狼人請閉眼"
        case .witchOpenEyes:
            return "女巫請睜眼"
        case .witchWillSave:
            return "傳送狼人殺害的號碼給女巫"
        case .showWitchVictimMessage:
            return "女巫要救嗎"
        case .witchWillKill:
            return ""
        case .witchKillsOrNot:
            return "要使用毒藥嗎"
        case .witchClosesEyes:
            return "女巫請閉眼"
        case .forecasterOpensEyes:
            return "預言家請睜眼"
        case .forecasterWillCheck:
            return ""
        case .forecasterChecks:
            return "預言家請選擇查驗對象"
        case .forecasterClosesEyes:
            return "預言家請閉眼"
        case .everyoneWillOpenEyes:
            return ""
        case .everyoneOpensEyes:
            return "天亮了"
        case .countdownForVoting:
            return "討論一分鐘"
        case .vote:
            return "請在手機投票兇手"
        case .checkGameOver:
            return "確認獲勝條件中"
        case .roundEnded:
            return "回合結束"
        default:
            return ""
        }
    }
}

enum WerewolfGameMode {
    case people6
    
    func getPeopleCount() -> Int {
        switch self {
        case .people6:
            return 6
        }
    }
    
    func getSpecies() -> [WerewolfSpecies] {
        switch self {
        case .people6:
            var characters = [WerewolfSpecies]()
            for i in 0..<2 {
                characters.append(.werewolf(count: i))
                characters.append(.villager(count: i))
            }
            characters.append(.witch)
            characters.append(.forecaster)
            
            return characters
        }
    }
}

enum WerewolfSuperpower: String, Codable {
    case none                           // for villager.
    case killPeople                     // for werewolf.
    case poisonPeople                   // for witch.
    case savePeople                     // for witch.
    case checkTitleWithoutSideEffect    // for forecaster.
    case oneShot                        // for hunter.
    case checkTitleWithSideEffect       // for knight.
}

enum WerewolfSpecies {
    case villager(count: Int)
    case witch
    case forecaster
    case hunter
    case knight
    case werewolf(count: Int)
    
    func getTitle() -> String {
        switch self {
        case .villager(let count):
            return "村民 \(count)"
        case .witch:
            return "女巫"
        case .forecaster:
            return "預言家"
        case .hunter:
            return "獵人"
        case .knight:
            return "騎士"
        case .werewolf(let count):
            return "狼人 \(count)"
        }
    }
    
    func getGroup() -> WerewolfGroup {
        switch self {
        case .werewolf(_):
            return .bad
        default:
            return .good
        }
    }
    
    func getSuperpowers() -> [WerewolfSuperpower] {
        switch self {
        case .villager(_):
            return [.none]
        case .witch:
            return [.savePeople, .poisonPeople]
        case .forecaster:
            return [.checkTitleWithoutSideEffect]
        case .hunter:
            return [.oneShot]
        case .knight:
            return [.checkTitleWithSideEffect]
        case .werewolf(_):
            return [.killPeople]
        }
    }
}

extension WerewolfSpecies: RawRepresentable {
        
    typealias RawValue = (Int, Int?)
    
    init?(rawValue: RawValue) {
        switch rawValue.0 {
        case 0:
            if let number = rawValue.1 {
                self = .villager(count: number)
            } else {
                return nil
            }
        case 1:
            self = .witch
        case 2:
            self = .forecaster
        case 3:
            self = .hunter
        case 4:
            self = .knight
        case 5:
            if let number = rawValue.1 {
                self = .werewolf(count: number)
            } else {
                return nil
            }
        default:
            return nil
        }
    }
    
    var rawValue: RawValue {
        switch self {
        case .villager(let count):
            return (0, count)
        case .witch:
            return (1, nil)
        case .forecaster:
            return (2, nil)
        case .hunter:
            return (3, nil)
        case .knight:
            return (4, nil)
        case .werewolf(let count):
            return (5, count)
        }
    }
}

extension WerewolfSpecies: Codable {
    
    private
    enum CodingKeys: String, CodingKey {
        case villager
        case witch
        case forecaster
        case hunter
        case knight
        case werewolf
    }
    
    enum WerewolfSpeciesCodingError: Error {
        case decoding(error: String)
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        if let value = try? values.decode(Int.self, forKey: .villager) {
            self = .villager(count: value)
            return
        }
        
        if let value = try? values.decode(Int.self, forKey: .werewolf) {
            self = .werewolf(count: value)
            return
        }
        
        if let _ = try? values.decodeNil(forKey: .forecaster) {
            self = .forecaster
            return
        }
        
        if let _ = try? values.decodeNil(forKey: .hunter) {
            self = .hunter
            return
        }
        
        if let _ = try? values.decodeNil(forKey: .knight) {
            self = .knight
            return
        }
        
        if let _ = try? values.decodeNil(forKey: .witch) {
            self = .witch
            return
        }
        
        throw WerewolfSpeciesCodingError.decoding(error: "Decoding error of WerewolfSpecies")
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .villager(let count):
            try container.encode(count, forKey: .villager)
        case .witch:
            try container.encodeNil(forKey: .witch)
        case .forecaster:
            try container.encodeNil(forKey: .forecaster)
        case .hunter:
            try container.encodeNil(forKey: .hunter)
        case .knight:
            try container.encodeNil(forKey: .knight)
        case .werewolf(let count):
            try container.encode(count, forKey: .werewolf)
        }
    }
}

enum WerewolfGroup: String, Codable {
    case good
    case bad
}

struct WerewolfCharacter: Codable {
    var species: WerewolfSpecies
    var group: WerewolfGroup
    var number: Int
    var superpowers: [WerewolfSuperpower] = []
    var isAlive: Bool = true
    var killedRound: Int?
    var deviceName: String = ""
    var currentRound: Int
    var isIdentityExposed: Bool = false
    
    init(species: WerewolfSpecies, number: Int) {
        self.species = species
        self.group = species.getGroup()
        self.number = number
        self.superpowers = species.getSuperpowers()
        self.isAlive = true
        self.killedRound = nil
        self.currentRound = 1
    }
    
    func isVillager() -> Bool {
        return species.rawValue.0 == 0
    }
    
    func isWitch() -> Bool {
        return species.rawValue.0 == 1
    }
    
    func isForecaster() -> Bool {
        return species.rawValue.0 == 2
    }
    
    func isHunter() -> Bool {
        return species.rawValue.0 == 3
    }
    
    func isKnight() -> Bool {
        return species.rawValue.0 == 4
    }
    
    func isWerewolf() -> Bool {
        return species.rawValue.0 == 5
    }
    
    // For witch.
    func isAbleToSave() -> Bool {
        if isWitch() && superpowers.contains(.savePeople) {
            
            if isAlive {
                return true
            } else {
                guard let killedRound = killedRound else { fatalError("Error in isAbleToSave") }
                return killedRound == currentRound
            }
            
        } else {
            return false
        }
    }
    
    // For witch.
    func isAbleToPoison() -> Bool {
        if isWitch() && superpowers.contains(.poisonPeople) {
            
            if isAlive {
                return true
            } else {
                guard let killedRound = killedRound else { fatalError("Error in isAbleToSave") }
                return killedRound == currentRound
            }
            
        } else {
            return false
        }
    }
    
    // For forecaster.
    func isAbleToForecast() -> Bool {
        if isForecaster() {
            
            if isAlive {
                return true
            } else {
                guard let killedRound = killedRound else { fatalError("Error in isAbleToForecast") }
                return killedRound == currentRound
            }
            
        } else {
            return false
        }
    }
    
    func isMe() -> Bool {
        return deviceName == UIDevice.current.name
    }
    
    func isAbleToVote() -> Bool {
        return isAlive
    }
    
    func canBeKilledByWerewolf() -> Bool {
        return isAlive
    }
    
    func canBeSavedByWitch() -> Bool {
        if isAlive {
            return false
        } else {
            guard let killedRound = killedRound else { return false }
            return killedRound == currentRound
        }
    }
    
    func canBeKilledByWitch() -> Bool {
        return isAlive
    }
    
    func canBeForecasted() -> Bool {
        if isAlive {
            return true
        } else {
            guard let killedRound = killedRound else { return true }
            return !(killedRound < currentRound)
        }
    }
    
    func getIndexFromNumber() -> Int {
        return number - 1
    }
    
    mutating func setKilled(at round: Int) {
        self.isAlive = false
        self.killedRound = round
    }
    
    mutating func setSaved() {
        self.isAlive = true
        self.killedRound = nil
    }
    
    mutating func remove(superpower: WerewolfSuperpower) {
        if self.superpowers.contains(superpower) {
            self.superpowers.removeAll {
                $0 == superpower
            }
        }
    }
}

extension WerewolfCharacter: CustomStringConvertible {
    var description: String {
        return
        """
        =====
        species: \(species.getTitle())
        number: \(number)
        superpower: \(superpowers)
        isAlive: \(isAlive)
        killedRound: \(killedRound)
        currentRound: \(currentRound)
        isExposed: \(isIdentityExposed)
        =====
        """
    }
}
