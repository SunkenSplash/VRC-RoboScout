//
//  MatchRowView.swift
//  VRC RoboScout
//
//  Created by William Castro on 7/27/24.
//

import Foundation
import SwiftUI

struct MatchRowView: View {
    
    @EnvironmentObject var dataController: RoboScoutDataController
    @EnvironmentObject var settings: UserSettings
    
    @Binding var event: Event
    @Binding var matches: [Match]
    @Binding var teams_map: [String: String]
    @Binding var predictions: Bool
    @Binding var matchString: String
    @Binding var team: Team
    
    func conditionalUnderline(matchString: String, index: Int) -> Bool {
        let split = matchString.split(separator: "&&")
        
        guard team.id != 0 else {
            return false
        }
        
        if Int(split[index]) == self.team.id {
            return true
        }
        
        let match = matches[Int(split[0]) ?? 0]
        let alliance = match.alliance_for(team: self.team)
        
        if alliance == nil {
            return false
        }
        
        if (alliance! == Alliance.red && index == 6) || (alliance! == Alliance.blue && index == 7) {
            return true
        }
        
        return false
    }
    
    func conditionalColor(matchString: String) -> Color {
        let split = matchString.split(separator: "&&")
        let match = matches[Int(split[0]) ?? 0]
        
        guard team.id != 0 && (match.completed() || (match.predicted && predictions)) else {
            return .primary
        }
        
        do {
            let victor = match.completed() ? match.winning_alliance() : try match.predicted_winning_alliance()
            
            if victor == nil {
                return .yellow
            }
            else if victor! == match.alliance_for(team: self.team) {
                return .green
            }
            else {
                return .red
            }
        }
        catch {
            return .primary
        }
    }
    
    func isPredicted(matchString: String) -> Bool {
        let split = matchString.split(separator: "&&")
        let match = matches[Int(split[0]) ?? 0]
        
        return match.predicted && predictions
    }
    
    @ViewBuilder
    func centerDisplay(matchString: String) -> some View {
        let split = matchString.split(separator: "&&")
        let match = matches[Int(split[0]) ?? 0]
        
        if match.completed() || (match.predicted && predictions) {
            HStack {
                Text(String(describing: (match.predicted && predictions) ? match.predicted_red_score : match.red_score)).foregroundColor(.red).font(.system(size: 18)).frame(alignment: .leading).underline(conditionalUnderline(matchString: matchString, index: 6)).opacity((match.predicted && predictions) ? 0.6 : 1).bold()
                Spacer()
                Text(String(describing: (match.predicted && predictions) ? match.predicted_blue_score : match.blue_score)).foregroundColor(.blue).font(.system(size: 18)).frame(alignment: .trailing).underline(conditionalUnderline(matchString: matchString, index: 7)).opacity((match.predicted && predictions) ? 0.6 : 1).bold()
            }
        }
        else {
            Spacer()
            Text(match.field).font(.system(size: 15)).foregroundColor(.secondary)
            Spacer()
        }
    }
    
    var body: some View {
        NavigationLink(destination: MatchNotes(event: event, match: matches[Int($matchString.wrappedValue.split(separator: "&&")[0])!]).environmentObject(settings).environmentObject(dataController)) {
            HStack {
                VStack {
                    Text($matchString.wrappedValue.split(separator: "&&")[1]).font(.system(size: 15)).frame(width: 60, alignment: .leading).foregroundColor(conditionalColor(matchString: $matchString.wrappedValue)).opacity(isPredicted(matchString: $matchString.wrappedValue) ? 0.6 : 1).bold()
                    Spacer().frame(maxHeight: 4)
                    Text($matchString.wrappedValue.split(separator: "&&")[8]).font(.system(size: 12)).frame(width: 60, alignment: .leading)
                }.frame(width: 40)
                VStack {
                    if String(teams_map[String($matchString.wrappedValue.split(separator: "&&")[3])] ?? "") != "" {
                        Text(String(teams_map[String($matchString.wrappedValue.split(separator: "&&")[2])] ?? "")).foregroundColor(.red).font(.system(size: 15)).underline(conditionalUnderline(matchString: $matchString.wrappedValue, index: 2))
                        Text(String(teams_map[String($matchString.wrappedValue.split(separator: "&&")[3])] ?? "")).foregroundColor(.red).font(.system(size: 15)).underline(conditionalUnderline(matchString: $matchString.wrappedValue, index: 3))
                    }
                    else {
                        Text(String(teams_map[String($matchString.wrappedValue.split(separator: "&&")[2])] ?? "")).foregroundColor(.red).font(.system(size: 15)).underline(conditionalUnderline(matchString: $matchString.wrappedValue, index: 2))
                    }
                }.frame(width: 70)
                centerDisplay(matchString: $matchString.wrappedValue)
                VStack {
                    if String(teams_map[String($matchString.wrappedValue.split(separator: "&&")[5])] ?? "") != "" {
                        Text(String(teams_map[String($matchString.wrappedValue.split(separator: "&&")[4])] ?? "")).foregroundColor(.blue).font(.system(size: 15)).underline(conditionalUnderline(matchString: $matchString.wrappedValue, index: 4))
                        Text(String(teams_map[String($matchString.wrappedValue.split(separator: "&&")[5])] ?? "")).foregroundColor(.blue).font(.system(size: 15)).underline(conditionalUnderline(matchString: $matchString.wrappedValue, index: 5))
                    }
                    else {
                        Text(String(teams_map[String($matchString.wrappedValue.split(separator: "&&")[4])] ?? "")).foregroundColor(.blue).font(.system(size: 15)).underline(conditionalUnderline(matchString: $matchString.wrappedValue, index: 4))
                    }
                }.frame(width: 70)
            }.frame(maxHeight: 30)
        }
    }
}
