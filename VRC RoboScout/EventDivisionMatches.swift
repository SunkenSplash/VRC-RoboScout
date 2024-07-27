//
//  EventDivisionMatches.swift
//  VRC RoboScout
//
//  Created by William Castro on 6/19/23.
//

import SwiftUI

struct EventDivisionMatches: View {
    
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var navigation_bar_manager: NavigationBarManager
    @EnvironmentObject var prediction_manager: PredictionManager
    @EnvironmentObject var dataController: RoboScoutDataController
    
    @Binding var teams_map: [String: String]
    
    @State var event: Event
    @State var division: Division
    @State private var predictions = false
    @State private var matches = [Match]()
    @State private var matches_list = [String]()
    @State private var showLoading = true
    
    func fetch_info(predict: Bool = false) {
        DispatchQueue.global(qos: .userInteractive).async { [self] in

            var matches = [Match]()

            do {
                self.event.fetch_matches(division: division)
                try self.event.calculate_team_performance_ratings(division: division)
                matches = self.event.matches[division] ?? [Match]()
            }
            catch {
                matches = self.event.matches[division] ?? [Match]()
                DispatchQueue.main.async {
                    self.predictions = false
                    self.prediction_manager.state = PredictionState.off
                }
            }
            
            if matches.isEmpty {
                DispatchQueue.main.async {
                    self.prediction_manager.state = PredictionState.disabled
                }
            }
            
            if predict {
                do {
                    try self.event.predict_matches(division: division)
                    DispatchQueue.main.async {
                        self.predictions = true
                        self.prediction_manager.state = PredictionState.on
                    }
                }
                catch {}
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
                List($matches_list) { matchString in
                    MatchRowView(event: $event, matches: $matches, teams_map: $teams_map, predictions: $predictions, matchString: matchString, team: .constant(Team()))
                }.onChange(of: prediction_manager.state) { new_state in
                    if new_state == PredictionState.calculating {
                        fetch_info(predict: true)
                    }
                    else if new_state == PredictionState.off {
                        predictions = false
                    }
                }
            }
        }.task{
            fetch_info()
        }.onAppear{
            navigation_bar_manager.title = "\(division.name) Match List"
        }
            .background(.clear)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(settings.tabColor(), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
    }
}

struct EventDivisionMatches_Previews: PreviewProvider {
    static var previews: some View {
        EventDivisionMatches(teams_map: .constant([String: String]()), event: Event(), division: Division())
    }
}
