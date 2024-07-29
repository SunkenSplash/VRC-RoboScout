//
//  WatchSessionW.swift
//  VRC RoboScout W Watch App
//
//  Created by William Castro on 7/26/24.
//

import Foundation

import WatchConnectivity

class WatchSessionW: NSObject, ObservableObject {
    
    var wcSession: WCSession
    
    override init() {
        wcSession = WCSession.default
        super.init()
        wcSession.delegate = self
        wcSession.activate()
    }
    
}

extension WatchSessionW: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print(message)
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        print("Application context recieved")
        DispatchQueue.main.async {
            if let data = applicationContext["favorite_teams"] as? [String] {
                defaults.set(data, forKey: "favorite_teams")
            }
            if let data = applicationContext["favorite_events"] as? [String] {
                defaults.set(data, forKey: "favorite_events")
            }
        }
    }
}
