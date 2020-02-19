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
        }
        
        let dictionary: [String : Any] = [TVMPCService.characterInfoKey : peersDictionary]
        
        guard let data = try? JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted) else {
            // TODO: Should show local notification.
            print("fail to serialize the object to data.")
            return
        }
        
        do {
            try mcSession.send(data, toPeers: connectedPeerIDs, with: .reliable)
        } catch {
            // TODO: Should show local notification.
            print("error for sending character to peers: \(error.localizedDescription)")
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
    
    static let characterNumberKey = "characterNumber"
    
    static let characterSpeciesRawValueFirstKey = "speciesRawValueFirst"
    
    static let characterSpeciesRawValueSecondKey = "speciesRawValueSecond"
}
