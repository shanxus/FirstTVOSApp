//
//  MPCService.swift
//  TVOSMPC
//
//  Created by ShanOvO on 2020/2/18.
//  Copyright © 2020 ShanOvO. All rights reserved.
//

import Foundation
import MultipeerConnectivity

class MPCService: NSObject {
    
    var peerID: MCPeerID!
    var mcSession: MCSession!
    var advertiser: MCNearbyServiceAdvertiser!
    
    override init() {
        super.init()
        
        peerID = MCPeerID(displayName: UIDevice.current.name)
                
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .none)
        advertise()
    }
    
    private func advertise() {
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: "ssh-wg")
        advertiser.delegate = self
        advertiser.startAdvertisingPeer()
    
    }
    
    private func showLocalNotification(with title: String, content: String) {
        
    }
}

extension MPCService: MCSessionDelegate {
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
        print("2")
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

extension MPCService: MCNearbyServiceAdvertiserDelegate {
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        
        print("didReceiveInvitationFromPeer")
        invitationHandler(true, mcSession)
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("didNotStartAdvertisingPeer")
    }
    
}
