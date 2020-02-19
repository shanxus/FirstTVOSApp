//
//  WerewolfModel.swift
//  FirstTVOSApp
//
//  Created by ShanOvO on 2020/2/16.
//  Copyright © 2020 ShanOvO. All rights reserved.
//

import Foundation

enum WerewolfScript: CaseIterable {
    case everyoneClosesEyes
    case werewolfOpensEyes
    case werewolfDecidesVictim
    case werewolfClosesEyes
    
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
                characters.append(.villager(count: i))
                characters.append(.werewolf(count: i))
            }
            characters.append(.witch)
            characters.append(.forecaster)
            
            return characters
        }
    }
}

enum WerewolfSuperpower {
    case none   // for villager.
    case killPeople // for werewolf and witch.
    case savePeople // for witch.
    case checkTitleWithoutSideEffect // for forecaster.
    case oneShot    // for hunter.
    case checkTitleWithSideEffect   // for knight.
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
            return [.savePeople, .killPeople]
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

enum WerewolfGroup {
    case good
    case bad
}

protocol WerewolfCharacteristic {
    var species: WerewolfSpecies { get set }
    var group: WerewolfGroup { get set }
    var number: Int { get set }
    var superpower: [WerewolfSuperpower] { get set }
}

struct WerewolfCharacter: WerewolfCharacteristic {
    var species: WerewolfSpecies
    var group: WerewolfGroup
    var number: Int
    var superpower: [WerewolfSuperpower]
    
    init(species: WerewolfSpecies, number: Int) {
        self.species = species
        self.group = species.getGroup()
        self.number = number
        self.superpower = species.getSuperpowers()
    }
}
