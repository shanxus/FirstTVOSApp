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
    
    func didGetVoteResult(result: TVMPCService.voteResult)
}

protocol TVMPCServiceDataSource: class {
    func aliveMemberCount() -> Int
    
    func connectedAliveMemberCount(connectedPeerIDs: [String]) -> Int
}

class TVMPCService: NSObject {
    
    var peerID: MCPeerID!
    var mcSession: MCSession!
    var mcBrowser: MCNearbyServiceBrowser!
    
    weak var delegate: TVMPCServiceDelegate?
    weak var dataSource: TVMPCServiceDataSource?
    
    private(set) var connectedPeerIDs: [MCPeerID] = [] {
        didSet {
            DispatchQueue.main.async {
                self.delegate?.connectedPeersDidChange()
            }
        }
    }
    
    private var handshakeMessages: [String] = []
    private var voteResults: [Int] = []
    
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
            print("append: \(displayName) to handshake messages")
            handshakeMessages.append(displayName)
        }
        
        if handshakeMessages.count == connectedPeerIDs.count {
            handshakeMessages.removeAll()
            
            print("Post for handshake")
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
    
    private func handleWitchKills(targetNumber: Int?) {
        
        let userInfo = [TVMPCService.didGetWitchVictimKey : targetNumber]
        NotificationCenter.default.post(name: NSNotification.Name.didGetWitchVictim, object: nil, userInfo: userInfo)
    }
    
    private func handleForecasterDidCheck(number: Int) {
        
        let userInfo = [TVMPCService.didGetForecasterCheckedTargetKey : number]
        NotificationCenter.default.post(name: NSNotification.Name.didGetForecasterCheckedTarget, object: nil, userInfo: userInfo)
    }
    
    private func handleVoteResults() {
        print("[handleVoteResults]")
        // target : count
        var voteDictionary: [Int : Int] = [:]
        
        voteResults.forEach {
            if let currentCount = voteDictionary[$0] {
                voteDictionary[$0] = (currentCount + 1)
            } else {
                voteDictionary[$0] = 1
            }
        }
        
        // Clear to make it can be counted again.
        voteResults.removeAll()
        
        let sortedDictionary = voteDictionary.sorted {
            return $0.1 > $1.1
        }
        
        guard let firstElement = sortedDictionary.first else { return }
        
        let filterElements = sortedDictionary.filter {
            $0.1 == firstElement.1
        }
        
        if filterElements.count == 1 {  // Got vote result.
            let result = TVMPCService.voteResult.divorce(winner: firstElement)
            
            delegate?.didGetVoteResult(result: result)
         
            // Notify werewolf service by notification.
            let userInfo = [TVMPCService.voteResultKey : result]
            
            NotificationCenter.default.post(name: NSNotification.Name.didGetVoteResult, object: nil, userInfo: userInfo)
            
        } else if filterElements.count > 1 {    // It's a tie. Need to vote again.
            let result = TVMPCService.voteResult.tie(candidates: filterElements)
            
            delegate?.didGetVoteResult(result: result)
            
            // Notify werewolf service by notification.
            let userInfo = [TVMPCService.voteResultKey : result]
            
            NotificationCenter.default.post(name: NSNotification.Name.didGetVoteResult, object: nil, userInfo: userInfo)
        }
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
            
            let targetNumber = dictionary[TVMPCService.witchKillTargetKey] as? Int
            
            handleWitchKills(targetNumber: targetNumber)
            
        } else if firstKey == TVMPCService.forecasterDidCheckTargetKey {
            print("got forecasterDidCheckTargetKey")
            
            guard let targetNumber = dictionary[TVMPCService.forecasterDidCheckTargetKey] as? Int else {
                print("Failed to unwrap checked target")
                return
            }
            
            handleForecasterDidCheck(number: targetNumber)
        } else if firstKey == TVMPCService.playerDidVoteKey {
            
            print("got playerDidVoteKey")
            
            guard let targetNumber = dictionary[firstKey] as? Int else {
                print("Failed to get vote target.")
                return
            }
            
            voteResults.append(targetNumber)
            
            let peerIDs = connectedPeerIDs.map { $0.displayName }
            
            guard let aliveMemberCount = dataSource?.connectedAliveMemberCount(connectedPeerIDs: peerIDs) else {
                fatalError("There is no data source in unwrapReceivedData")
            }
            
            if voteResults.count == aliveMemberCount {
                handleVoteResults()
            }
        }
    }
    
    func notifyWerewolfToKill() {
        print("[notifyWerewolfToKill]")
                
        let message = [TVMPCService.werewolfShouldKillKey : TVMPCService.werewolfShouldKillKey]
            
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
    
    func notifyForecasterToCheck() {
        let message = [TVMPCService.forecasterCanCheckKey : TVMPCService.forecasterCanCheckKey]
        
        guard let data = try? JSONSerialization.data(withJSONObject: message, options: .prettyPrinted) else {
            return
        }
        
        send(data: data, to: connectedPeerIDs)
    }
    
    func notifyDaybreak() {
        let message = [TVMPCService.dayDidBreakKey : TVMPCService.dayDidBreakKey]
        
        guard let data = try? JSONSerialization.data(withJSONObject: message, options: .prettyPrinted) else {
            return
        }
        
        send(data: data, to: connectedPeerIDs)
    }
    
    func notifyToVote() {
        let message = [TVMPCService.playersCanVoteKey : TVMPCService.playersCanVoteKey]
        
        guard let data = try? JSONSerialization.data(withJSONObject: message, options: .prettyPrinted) else {
            return
        }
        
        send(data: data, to: connectedPeerIDs)
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
    
    enum voteResult {
        case divorce(winner: (Int, Int))
        case tie(candidates: [(Int, Int)])
    }
    
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
    
    static let dayDidBreakKey = "dayDidBreakKey"
    
    static let playersCanVoteKey = "playersCanVoteKey"
    
    static let playerDidVoteKey = "playerDidVoteKey"
    
    static let voteResultKey = "voteResultKey"
}

extension Notification.Name {
    static let MPCHandshake = Notification.Name(TVMPCService.MPCHandshakeKey)
    
    static let didGetWerewolfVictim = Notification.Name(TVMPCService.didGetWerewolfVictimKey)
    
    static let didGetWitchSaveResult = Notification.Name(TVMPCService.didGetWitchSaveResultKey)
    
    static let witchDidSave = Notification.Name(TVMPCService.witchDidSaveKey)
    
    static let didGetWitchVictim = Notification.Name(TVMPCService.didGetWitchVictimKey)
    
    static let didGetForecasterCheckedTarget = Notification.Name(TVMPCService.didGetForecasterCheckedTargetKey)
    
    static let didGetVoteResult = Notification.Name(TVMPCService.voteResultKey)
}
