//
//  RoboScoutActivityController.swift
//  VRC RoboScout
//
//  Created by William Castro on 11/8/23.
//

import Foundation
import SwiftUI
import ActivityKit
import UserNotifications

enum RoboScoutActivityControllerError: Error {
    case failedToGetID
    case activityNotFound
    case insufficientMatchData
}

class RoboScoutActivityController {
    
    @Published var deviceToken: String?
    
    private var activities = [String: String]() // ["eventID-teamID": "activityID"]
    
    func registerForNotifications() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized:
                print("Already authorized for notifications")
            case .denied:
                print("Notifications denied. Please enable in Settings.")
            case .notDetermined:
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    if let error = error {
                        print("Error requesting notification authorization: \(error)")
                    } else if granted {
                        DispatchQueue.main.async {
                            UIApplication.shared.registerForRemoteNotifications()
                        }
                    }
                }
            default:
                break
            }
        }
    }
    
    private func matchesToStrings(matches: [Match], event: Event) -> [[String]] {
        
        func displayTime(match: Match) -> String {
            // Time should be in the format of "HH:mm" AM/PM
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            
            if let started = match.started {
                return formatter.string(from: started)
            }
            else if let scheduled = match.scheduled {
                return formatter.string(from: scheduled)
            }
            else {
                return " "
            }
        }
        
        func formatName(name: String) -> String {
            var name = name
            name.replace("Qualifier", with: "Q")
            name.replace("Practice", with: "P")
            name.replace("Final", with: "F")
            name.replace("#", with: "")
            return name
        }
        
        return matches.map{ [
            formatName(name: $0.name),
            String(displayTime(match: $0)),
            String($0.red_score),
            String($0.blue_score),
            event.get_team(id: $0.red_alliance[0].id)!.number,
            event.get_team(id: $0.red_alliance[1].id)!.number,
            event.get_team(id: $0.blue_alliance[0].id)!.number,
            event.get_team(id: $0.blue_alliance[1].id)!.number
        ] }
        
    }
    
    @available(iOS 16.2, *)
    func startMatchUpdatesActivity(event: Event, team: Team, matches: [Match]) async throws {
        let attributes = MatchUpdatesAttributes(
            teamNumber: team.number,
            eventName: event.name
        )
        
        let lastCompletedMatch = matches.last{ $0.completed() } ?? Match()
        let upcomingMatchIndex = matches.firstIndex{ $0.id == lastCompletedMatch.id } ?? 1
        if matches.count < 2 {
            throw RoboScoutActivityControllerError.insufficientMatchData
        }
        
        let initialContentState = MatchUpdatesAttributes.ContentState(
            matches: matchesToStrings(matches: Array(matches[0...upcomingMatchIndex]), event: event)
        )
        do {
            self.registerForNotifications()
            let activity = try Activity.request(attributes: attributes, content: .init(state: initialContentState, staleDate: nil), pushType: .token)
            let id = activity.id
            self.activities["\(event.id)-\(team.id)"] = id
            for await pushToken in activity.pushTokenUpdates {
                let pushTokenString = pushToken.reduce("") {
                      $0 + String(format: "%02x", $1)
                }
                
                print("New push token: \(pushTokenString)")
                // try await self.sendPushToken(event: event, team: team, pushTokenString: pushTokenString)
            }
        } catch {
            throw error
        }
    }
    
    @available(iOS 16.2, *)
    func matchUpdatesActive(event: Event, team: Team) -> Bool {
        return self.activities.keys.contains("\(event.id)-\(team.id)")
    }
    
    @available(iOS 16.2, *)
    func updateMatchUpdatesActivity(event: Event, team: Team, matches: [Match]) async throws {
        guard let id = self.activities["\(event.id)-\(team.id)"] else { throw RoboScoutActivityControllerError.activityNotFound }
        
        let lastCompletedMatch = matches.last{ $0.completed() } ?? Match()
        let upcomingMatchIndex = matches.firstIndex{ $0.id == lastCompletedMatch.id } ?? 1
        if matches.count < 2 {
            throw RoboScoutActivityControllerError.insufficientMatchData
        }
        
        let updatedContentState = MatchUpdatesAttributes.ContentState(
            matches: matchesToStrings(matches: Array(matches[0...upcomingMatchIndex]), event: event)
        )
        let activity = Activity<MatchUpdatesAttributes>.activities.first(where: { $0.id == id })
        await activity?.update(using: updatedContentState)
    }
    
    @available(iOS 16.2, *)
    func endMatchUpdatesActivity(event: Event, team: Team) async {
        await Activity<MatchUpdatesAttributes>.activities.first(where: { $0.id == self.activities["\(event.id)-\(team.id)"] })?.end(dismissalPolicy: .immediate)
        activities.removeValue(forKey: "\(event.id)-\(team.id)")
    }
    
    @available(iOS 16.2, *)
    func endAllMatchUpdatesActivities() async {
        for activity in Activity<MatchUpdatesAttributes>.activities {
            await activity.end(dismissalPolicy: .immediate)
        }
        self.activities = [String: String]()
    }

}
