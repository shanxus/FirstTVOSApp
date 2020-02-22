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
    func didReceiveAllHandShakeMessages()
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
    
    private var handShakeMessages: [String] = []
    
    private var peerCharacterMap: [String : WerewolfSpecies] = [:]
    
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
        
        var peersDictionary: [String : Any] = [:]
        
        for (index, peer) in connectedPeerIDs.enumerated() {
            var propertyDictionary: [String : Any] = [:]

            let character = characters[index]

            propertyDictionary[TVMPCService.characterNumberKey] = character.number
            propertyDictionary[TVMPCService.characterSpeciesRawValueFirstKey] = character.species.rawValue.0
            propertyDictionary[TVMPCService.characterSpeciesRawValueSecondKey] = character.species.rawValue.1

            peersDictionary[peer.displayName] = propertyDictionary
            
            // Keep the paired information.
            peerCharacterMap[peer.displayName] = character.species
        }
        
        let dictionary: [String : Any] = [TVMPCService.characterInfoKey : peersDictionary]
        
        guard let data = try? JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted) else {
            // TODO: Should show local notification.
            print("fail to serialize the object to data.")
            return
        }
        
        send(data: data, to: connectedPeerIDs)
    }
    
    private func handleHandShake(for displayName: String) {
        if !handShakeMessages.contains(displayName) {
            handShakeMessages.append(displayName)
        }
        
        if handShakeMessages.count == connectedPeerIDs.count {
            handShakeMessages.removeAll()
            delegate?.didReceiveAllHandShakeMessages()
        }
    }
    
    private func unwrapReceivedData(_ data: Data) {
        guard let dictionary = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String : Any], let firstKey = dictionary.keys.first else {
            print("failed to unwrap received data")
            return
        }
        
        if firstKey == TVMPCService.handleShakeKey {
            print("got hand shake message from peer")
            guard let displayName = dictionary[TVMPCService.handleShakeKey] as? String else {
                print("failed to unwrap hand shake message")
                return
            }
            handleHandShake(for: displayName)
        }
    }
    
    func notifyWerewolfToKill() {
            
        let message = [TVMPCService.werewolfShouldKillKey : "Kill one player"]
            
        guard let data = try? JSONSerialization.data(withJSONObject: message, options: .prettyPrinted) else {
            print("failed to encode message as data.")
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
    static let characterInfoKey = "characterInfoKey"
    
    static let characterNumberKey = "characterNumberKey"
    
    static let characterSpeciesRawValueFirstKey = "speciesRawValueFirstKey"
    
    static let characterSpeciesRawValueSecondKey = "speciesRawValueSecondKey"
    
    static let handleShakeKey = "MPCHandShakeKey"
    
    static let werewolfShouldKillKey = "werewolfShouldKillKey"
}
