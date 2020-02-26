//
//  MPCService.swift
//  FirstTVOSApp
//
//  Created by ShanOvO on 2020/2/17.
//  Copyright © 2020 ShanOvO. All rights reserved.
//

import Foundation
import MultipeerConnectivity

protocol TVMPCServiceDelegate: class {
    func connectedPeersDidChange()
}

class TVMPCService: NSObject {
    
    var peerID: MCPeerID!
    var mcSession: MCSession!
    var mcBrowser: MCNearbyServiceBrowser!
    
    weak var delegate: TVMPCServiceDelegate?
    
    private(set) var connectedPeerIDs: [MCPeerID] = [] {
        didSet {
            DispatchQueue.main.async {
                self.delegate?.connectedPeersDidChange()
            }
        }
    }
    
    private var handshakeMessages: [String] = []
    
    override init() {
        super.init()
        
        peerID = MCPeerID(displayName: UIDevice.current.name)
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .none)
        mcSession.delegate = self
    }
    
    func browse() {
        mcBrowser = MCNearbyServiceBrowser(peer: peerID, serviceType: "ssh-wg") // SSH_werewolf game.
        mcBrowser.delegate = self
        mcBrowser.startBrowsingForPeers()
    }
    
    func sendCharacterInfoToClients(_ characters: [WerewolfCharacter]) {
        
        if let data = try? JSONEncoder().encode(characters) {
            print("[sendCharacterInfoToClients]")
            send(data: data, to: connectedPeerIDs)
        }
    }
    
    private func handleHandShake(for displayName: String) {
        if !handshakeMessages.contains(displayName) {
            handshakeMessages.append(displayName)
        }
        
        if handshakeMessages.count == connectedPeerIDs.count {
            handshakeMessages.removeAll()
            
            NotificationCenter.default.post(name: NSNotification.Name.MPCHandshake, object: nil, userInfo: nil)
        }
    }
    
    private func handleGotVictimFromWerewolf(targetNumber: Int) {
        
        let userInfo = [TVMPCService.didGetWerewolfVictimKey : targetNumber]
        
        NotificationCenter.default.post(name: NSNotification.Name.didGetWerewolfVictim, object: nil, userInfo: userInfo)
    }
    
    private func handleWitchSavesResult(witchSaves: Bool) {
        print("handleWitchSavesResult: \(witchSaves)")
        if witchSaves {
            
            // Send notification to remove the superpower.
            let userInfo = [TVMPCService.witchDidSaveKey : witchSaves]
            NotificationCenter.default.post(name: NSNotification.Name.witchDidSave, object: nil, userInfo: userInfo)
        }
        
        // Send notification to make the stage continue.
        NotificationCenter.default.post(name: NSNotification.Name.didGetWitchSaveResult, object: nil, userInfo: nil)
    }
    
    private func handleWitchKills(targetNumber: Int) {
        
        let userInfo = [TVMPCService.didGetWitchVictimKey : targetNumber]
        NotificationCenter.default.post(name: NSNotification.Name.didGetWitchVictim, object: nil, userInfo: userInfo)
    }
    
    private func handleForecasterDidCheck(number: Int) {
        
        let userInfo = [TVMPCService.didGetForecasterCheckedTargetKey : number]
        NotificationCenter.default.post(name: NSNotification.Name.didGetForecasterCheckedTarget, object: nil, userInfo: userInfo)
    }
    
    private func unwrapReceivedData(_ data: Data) {
        guard let dictionary = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String : Any], let firstKey = dictionary.keys.first else {
            print("failed to unwrap received data")
            return
        }
        
        if firstKey == TVMPCService.MPCHandshakeKey {
            print("got hand shake message from peer")
            guard let displayName = dictionary[TVMPCService.MPCHandshakeKey] as? String else {
                print("failed to unwrap hand shake message")
                return
            }
            handleHandShake(for: displayName)
            
        } else if firstKey == TVMPCService.werewolfKillTargetKey {
            print("got killed target")
            guard let targetNumber = dictionary[TVMPCService.werewolfKillTargetKey] as? Int else {
                print("failed to unwrap killed target")
                return
            }
            
            handleGotVictimFromWerewolf(targetNumber: targetNumber)
            
        } else if firstKey == TVMPCService.witchSavesResultKey {
            print("got witch saves result")
            
            guard let savesResult = dictionary[TVMPCService.witchSavesResultKey] as? Bool else {
                print("failed to unwrap saves result")
                return
            }
            
            handleWitchSavesResult(witchSaves: savesResult)
            
        } else if firstKey == TVMPCService.witchKillTargetKey {
            print("got witchKillTargetKey")
            
            guard let targetNumber = dictionary[TVMPCService.witchKillTargetKey] as? Int else {
                print("Failed to unwrap killed target")
                return
            }
            
            handleWitchKills(targetNumber: targetNumber)
            
        } else if firstKey == TVMPCService.forecasterDidCheckTargetKey {
            print("got forecasterDidCheckTargetKey")
            
            guard let targetNumber = dictionary[TVMPCService.forecasterDidCheckTargetKey] as? Int else {
                print("Failed to unwrap checked target")
                return
            }
            
            handleForecasterDidCheck(number: targetNumber)
        }
    }
    
    func notifyWerewolfToKill(currentVictimNumbers: [Int]) {
        print("[notifyWerewolfToKill]")
        let victimsString = currentVictimNumbers.map { String($0) }.joined(separator: ",")
        
        let message = [TVMPCService.werewolfShouldKillKey : victimsString]
            
        guard let data = try? JSONSerialization.data(withJSONObject: message, options: .prettyPrinted) else {
            print("failed to encode message as data.")
            return
        }
        
        send(data: data, to: connectedPeerIDs)
    }
    
    func notifyWitchToSave() {
        print("[notifyWitchToSave]")
        
        let message = [TVMPCService.witchSavesOrNotKey : TVMPCService.witchSavesOrNotKey]
        
        guard let data = try? JSONSerialization.data(withJSONObject: message, options: .prettyPrinted) else {
            return
        }
        
        send(data: data, to: connectedPeerIDs)
    }
    
    func notifyWitchToKill() {
        
        let message = [TVMPCService.witchKillsOrNotKey : TVMPCService.witchKillsOrNotKey]
        
        guard let data = try? JSONSerialization.data(withJSONObject: message, options: .prettyPrinted) else {
            return
        }
        
        send(data: data, to: connectedPeerIDs)
    }
    
    func notifyForecasterBeReadyToCheck() {
        
        let message = [TVMPCService.forecasterCanCheckKey : TVMPCService.forecasterCanCheckKey]
        guard let data = try? JSONSerialization.data(withJSONObject: message, options: .prettyPrinted) else {
            print("Failed to get data for forecasterWillCheckKey")
            return
        }
        
        send(data: data, to: connectedPeerIDs)
    }
    
    func notifyForecasterToCheck() {
        
    }
    
    func send(data: Data, to peers: [MCPeerID]) {
        do {
            try mcSession.send(data, toPeers: peers, with: .reliable)
        } catch {
            print("failed to send data")
        }
    }
}

extension TVMPCService: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected:
            print("state of tv session: connected")
            
            connectedPeerIDs.append(peerID)
            
        case .connecting:
            print("state of tv session: connecting")
        case .notConnected:
            print("state of tv session: not connected")
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        unwrapReceivedData(data)
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }
}

extension TVMPCService: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        print("[foundPeer: \(peerID) with info: \(info)]")
        
        mcBrowser.invitePeer(peerID, to: mcSession, withContext: nil, timeout: 20)

    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        connectedPeerIDs.removeAll {
            $0 == peerID
        }
    }
    
    
}

extension TVMPCService {
    static let characterInfoKey = "characterInfoKey"
    
    static let characterNumberKey = "characterNumberKey"
    
    static let characterSpeciesRawValueFirstKey = "speciesRawValueFirstKey"
    
    static let characterSpeciesRawValueSecondKey = "speciesRawValueSecondKey"
    
    static let MPCHandshakeKey = "MPCHandshakeKey"
    
    static let werewolfShouldKillKey = "werewolfShouldKillKey"
    
    static let werewolfKillTargetKey = "werewolfKillTargetKey"
    
    static let didGetWerewolfVictimKey = "didGetWerewolfVictimKey"
    
    static let witchSavesOrNotKey = "witchSavesOrNotKey"
    
    static let witchSavesResultKey = "witchSavesResultKey"
    
    static let witchDidSaveKey = "witchDidSaveKey"
    
    static let didGetWitchSaveResultKey = "didReceiveWitchSaveResultKey"
    
    static let witchKillsOrNotKey = "witchKillsOrNotKey"
    
    static let witchKillTargetKey = "witchKillTargetKey"
    
    static let didGetWitchVictimKey = "didGetWitchVictimKey"
    
    static let forecasterCanCheckKey = "forecasterCanCheckKey"
    
    static let forecasterDidCheckTargetKey = "forecasterDidCheckTargetKey"
    
    static let didGetForecasterCheckedTargetKey = "didGetForecasterCheckedTargetKey"
}

extension Notification.Name {
    static let MPCHandshake = Notification.Name(TVMPCService.MPCHandshakeKey)
    
    static let didGetWerewolfVictim = Notification.Name(TVMPCService.didGetWerewolfVictimKey)
    
    static let didGetWitchSaveResult = Notification.Name(TVMPCService.didGetWitchSaveResultKey)
    
    static let witchDidSave = Notification.Name(TVMPCService.witchDidSaveKey)
    
    static let didGetWitchVictim = Notification.Name(TVMPCService.didGetWitchVictimKey)
    
    static let didGetForecasterCheckedTarget = Notification.Name(TVMPCService.didGetForecasterCheckedTargetKey)
}
