//
//  EventDivisionMatchesView.swift
//  VRC RoboScout
//
//  Created by William Castro on 5/19/25.
//

import SwiftUI

struct EventDivisionMatchesView: View {
    
    @EnvironmentObject var settings: UserSettings
    
    @Binding var teams_map: [String: String]
    
    @State var event: Event
    @State var division: Division
    @State private var matches = [Match]()
    @State private var matches_list = [String]()
    @State private var showLoading = true
    
    func fetch_info() {
        DispatchQueue.global(qos: .userInteractive).async { [self] in

            var matches = [Match]()

            do {
                self.event.fetch_matches(division: division)
                try self.event.calculate_team_performance_ratings(division: division, forceRealCalculation: true)
                matches = self.event.matches[division] ?? [Match]()
            }
            catch {
                matches = self.event.matches[division] ?? [Match]()
            }
            
            // Time should be in the format of "HH:mm" AM/PM
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"

            DispatchQueue.main.async {
                self.matches = matches
                self.matches_list.removeAll()
                var count = 0
                for match in matches {
                    var name = match.name
                    name.replace("Qualifier", with: "Q")
                    name.replace("Practice", with: "P")
                    name.replace("Final", with: "F")
                    name.replace("#", with: "")
                    
                    // If match.started is not nil, then use it
                    // Otherwise use match.scheduled
                    // If both are nil, then use ""
                    let date: String = {
                        if let started = match.started {
                            return formatter.string(from: started)
                        }
                        else if let scheduled = match.scheduled {
                            return formatter.string(from: scheduled)
                        }
                        else {
                            return " "
                        }
                    }()
                    
                    // count, name, red1, red2, blue1, blue2, red_score, blue_score, scheduled time
                    self.matches_list.append("\(count)&&\(name)&&\(match.red_alliance[0].id)&&\(match.red_alliance[1].id)&&\(match.blue_alliance[0].id)&&\(match.blue_alliance[1].id)&&\(match.red_score)&&\(match.blue_score)&&\(date)")
                    count += 1
                }
                self.showLoading = false
            }
        }
    }
        
    var body: some View {
        VStack {
            if showLoading {
                ProgressView().padding()
                Spacer()
            }
            else if matches.isEmpty {
                NoData()
            }
            else {
                List($matches_list, id: \.self) { matchString in
                    MatchRowView(event: $event, matches: $matches, teams_map: $teams_map, predictions: .constant(false), matchString: matchString, team: .constant(Team()))
                }
            }
        }.task{
            fetch_info()
        }
    }
}

struct EventDivisionMatches_Previews: PreviewProvider {
    static var previews: some View {
        EventDivisionMatchesView(teams_map: .constant([String: String]()), event: Event(), division: Division())
    }
}
