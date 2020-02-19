//
//  MPCPhoneViewModel.swift
//  TVOSMPC
//
//  Created by Shan on 2020/2/19.
//  Copyright © 2020 ShanOvO. All rights reserved.
//

import Foundation

protocol MPCPhoneViewModelDelegate: class {
    func didUpdateCharacter(as title: String)
}

class MPCPhoneViewModel: NSObject {
    
    private var mpcService: PhoneMPCService?
    
    weak var delegate: MPCPhoneViewModelDelegate?
    
    private var character: WerewolfCharacter? {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.didUpdateCharacter(as: self?.character?.species.getTitle() ?? "--")
            }
        }
    }
    
    override init() {
        super.init()
        
        mpcService = PhoneMPCService()
        mpcService?.delegate = self
        
    }
}

extension MPCPhoneViewModel: PhoneMPCServiceDelegate {
    func didReceiveCharacterInformation(character: WerewolfCharacter) {
        self.character = character
    }
}
