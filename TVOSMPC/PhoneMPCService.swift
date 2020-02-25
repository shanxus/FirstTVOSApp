//
//  MPCService.swift
//  TVOSMPC
//
//  Created by ShanOvO on 2020/2/18.
//  Copyright © 2020 ShanOvO. All rights reserved.
//

import Foundation
import MultipeerConnectivity

protocol PhoneMPCServiceDelegate: class {
    func didReceiveCharacterInformation(character: WerewolfCharacter)
    func didReceiveWerewolfShouldKill(victimNumbers: [Int])
    func didReceiveWitchSavesOrNot(victimNumber: Int)
    func didReceiveWitchKillsOrNot(victimNumbers: [Int])
}

class PhoneMPCService: NSObject {
    
    var peerID: MCPeerID!
    var mcSession: MCSession!
    var advertiser: MCNearbyServiceAdvertiser!
    
    weak var delegate: PhoneMPCServiceDelegate?
    
    private var lastPeerID: MCPeerID?
    
    override init() {
        super.init()
        
        peerID = MCPeerID(displayName: UIDevice.current.name)
                
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .none)
        mcSession.delegate = self
        advertise()
    }
    
    private func advertise() {
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: "ssh-wg")
        advertiser.delegate = self
        advertiser.startAdvertisingPeer()
    
    }
    
    private func showLocalNotification(title: String, subtitle: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.subtitle = subtitle
        content.body = body
        content.sound = .default
        
//        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(identifier: "notification", content: content, trigger: nil)
        
        UNUserNotificationCenter.current().add(request, withCompletionHandler: {error in
            print("成功建立通知...")
        })
    }
    
    private func unwrapReceivedData(_ data: Data) {
        guard let dictionary = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String : Any], let firstKey = dictionary.keys.first else {
            print("failed to unwrap received data")
            return
        }
        
        if firstKey == TVMPCService.characterInfoKey {
            handleReceivingCharacterInfo(with: dictionary)
            sendHandShakeMessage()
        } else if firstKey ==  TVMPCService.werewolfShouldKillKey {
            handleReceivingWerewolfShouldKill(with: dictionary)
        } else if firstKey == TVMPCService.witchSavesOrNotKey {
            showLocalNotification(title: "Got witchSavesOrNotKey", subtitle: "", body: "")
            handleReceivingWitchSavesOrNot(with: dictionary)
        } else if firstKey == TVMPCService.witchKillsOrNotKey {
            showLocalNotification(title: "Got witchKillsOrNotKey", subtitle: "", body: "")
            handleReceivingWitchKillsOrNot(with: dictionary)
        }
    }
    
    private func handleReceivingCharacterInfo(with dictionary: [String : Any]) {
        guard let peersDictionary = dictionary[TVMPCService.characterInfoKey] as? [String : Any] else { return }
        guard let propertyDictionary = peersDictionary[peerID.displayName] as? [String : Any] else { return }
        guard let number = propertyDictionary[TVMPCService.characterNumberKey] as? Int else { return }
        
        guard let speciesRawValueFirst = propertyDictionary[TVMPCService.characterSpeciesRawValueFirstKey] as? Int else { return }
        
        let speciesRawValueSecond = propertyDictionary[TVMPCService.characterSpeciesRawValueSecondKey] as? Int
        
        if let species = WerewolfSpecies(rawValue: (speciesRawValueFirst, speciesRawValueSecond)) {
            
            let werewolfCharacter = WerewolfCharacter(species: species, number: number)
            delegate?.didReceiveCharacterInformation(character: werewolfCharacter)
        } else {
            showLocalNotification(title: "failed to get species", subtitle: "", body: "failed body")
        }
    }
    
    private func handleReceivingWerewolfShouldKill(with dictionary: [String : Any]) {
        print("[handleReceivingWerewolfShouldKill]")
        guard let victimNumbers = dictionary[TVMPCService.werewolfShouldKillKey] as? String else { return }
        
        let victims = victimNumbers.components(separatedBy: ",").compactMap { Int($0) }
        
        delegate?.didReceiveWerewolfShouldKill(victimNumbers: victims)
    }
    
    private func handleReceivingWitchSavesOrNot(with dictionary: [String : Any]) {
        guard let victimNumber = dictionary[TVMPCService.witchSavesOrNotKey] as? Int else { return }
        
        delegate?.didReceiveWitchSavesOrNot(victimNumber: victimNumber)
    }
    
    private func handleReceivingWitchKillsOrNot(with dictionary: [String : Any]) {
        
        guard let victimNumbers = dictionary[TVMPCService.witchKillsOrNotKey] as? String else { return }
        
        let victims = victimNumbers.components(separatedBy: ",").compactMap { Int($0) }
        
        delegate?.didReceiveWitchKillsOrNot(victimNumbers: victims)
    }
    
    private func sendHandShakeMessage() {
        let message = [ TVMPCService.MPCHandshakeKey : peerID.displayName]
        
        guard let encodedMessage = try? JSONSerialization.data(withJSONObject: message, options: .prettyPrinted) else {
            showLocalNotification(title: "fail to encode hand shake message 1", subtitle: "", body: "")
            return
        }
        
        guard let lastPeer = lastPeerID else {
            showLocalNotification(title: "fail to encode hand shake message 2", subtitle: "", body: "")
            return
        }
        
        send(data: encodedMessage, to: [lastPeer])
    }
    
    func sendKilledTarget(targetNumber: Int) {
        let message = [TVMPCService.werewolfKillTargetKey : targetNumber]
        
        guard let data = try? JSONSerialization.data(withJSONObject: message, options: .prettyPrinted) else { return }
        
        guard let lastPeer = lastPeerID else { return }
        
        send(data: data, to: [lastPeer])
            
        showLocalNotification(title: "Send killed target", subtitle: "", body: "")
    }
    
    func sendWitchSavesResult(witchSaves: Bool) {
        let message = [TVMPCService.witchSavesResultKey : witchSaves]
        
        guard let data = try? JSONSerialization.data(withJSONObject: message, options: .prettyPrinted) else { return }

        guard let lastPeer = lastPeerID else { return }
        
        send(data: data, to: [lastPeer])
    }
    
    func sendWitchKilledTarget(targetNumber: Int) {
        let message = [TVMPCService.witchKillTargetKey : targetNumber]
        
        guard let data = try? JSONSerialization.data(withJSONObject: message, options: .prettyPrinted) else { return }

        guard let lastPeer = lastPeerID else { return }
        
        send(data: data, to: [lastPeer])
    }
    
    func send(data: Data, to peers: [MCPeerID]) {
        do {
            try mcSession.send(data, toPeers: peers, with: .reliable)
        } catch {
            print("failed to send data in the phone MPC service")
        }
    }
}

extension PhoneMPCService: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connecting:
            print("state for session in phone: connecting")
        case .connected:
            print("state for session in phone: connected")
        case .notConnected:
            print("state for session in phone: not connected")
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        print("[didReceive data on the phone MPC session]")
        lastPeerID = peerID
        unwrapReceivedData(data)
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        print("3")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        print("4")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        print("5")
    }
}

extension PhoneMPCService: MCNearbyServiceAdvertiserDelegate {
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        
        print("didReceiveInvitationFromPeer")
        showLocalNotification(title: "didReceiveInvitationFromPeer", subtitle: "", body: "")
        invitationHandler(true, mcSession)
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("didNotStartAdvertisingPeer")
    }
    
}
