//
//  WatchSession.swift
//  VRC RoboScout
//
//  Created by William Castro on 7/26/24.
//

import Foundation

import WatchConnectivity

final class WatchSession: NSObject, ObservableObject {
    
    private let wcSession: WCSession
    
    override init() {
        //guard WCSession.isSupported() else { fatalError("Watch Connectivity Unsupported") }
        self.wcSession = WCSession.default
        super.init()
        self.wcSession.delegate = self
        self.wcSession.activate()
    }
    
    public func updateFavorites() {
        let payload = [
            "favorite_teams": defaults.object(forKey: "favorite_teams") as? [String] ?? [String](),
            "favorite_events": defaults.object(forKey: "favorite_events") as? [String] ?? [String]()
        ]
        print(payload)
        self.updateApplicationContext(with: payload)
    }
    
    public func updateApplicationContext(with context: [String: Any]) {
        guard wcSession.isPaired && wcSession.isWatchAppInstalled else {
            print("No watch with app installed, not updating application context")
            return
        }
        do {
            print("Updating with empty context")
            try self.wcSession.updateApplicationContext([String: Any]())
            print("Sending real context")
            try self.wcSession.updateApplicationContext(context)
            print("Application context updated")
        } catch {
            print("Updating of application context failed \(error)")
        }
    }
    
    public func sendMessage(
        _ message: [String: Any],
        replyHandler: (([String: Any]) -> Void)? = nil,
        errorHandler: ((Error) -> Void)? = nil
    ) {
        // Send message with reply handler
        wcSession.sendMessage(message, replyHandler: replyHandler, errorHandler: errorHandler)
    }
}

extension WatchSession: WCSessionDelegate {
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
        // Todo
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        wcSession.activate()
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        wcSession.activate()
    }
}
