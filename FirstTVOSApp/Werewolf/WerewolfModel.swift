//
//  WerewolfModel.swift
//  FirstTVOSApp
//
//  Created by ShanOvO on 2020/2/16.
//  Copyright © 2020 ShanOvO. All rights reserved.
//

import Foundation

enum WerewolfGameMode {
    case people6
    
    func getPeopleCount() -> Int {
        switch self {
        case .people6:
            return 6
        }
    }
    
    func getCharacters() -> [WerewolfTitle] {
        switch self {
        case .people6:
            var characters = [WerewolfTitle]()
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

enum WerewolfTitle {
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
    
    func getSuperpower() -> [WerewolfSuperpower] {
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

enum WerewolfGroup {
    case good
    case bad
}

protocol WerewolfCharacteristic {
    var title: WerewolfTitle { get set }
    var group: WerewolfGroup { get set }
    var number: Int { get set }
    var superpower: WerewolfSuperpower { get set }
}

struct WerewolfCharacter: WerewolfCharacteristic {
    var title: WerewolfTitle
    var group: WerewolfGroup
    var number: Int
    var superpower: WerewolfSuperpower
}
