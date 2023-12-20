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
    
    @ViewBuilder
    func centerDisplay(matchString: String) -> some View {
        let split = matchString.split(separator: "&&")
        let match = matches[Int(split[0]) ?? 0]
        
        if match.completed() || (match.predicted && predictions) {
            HStack {
                Text(String(describing: (match.predicted && predictions) ? match.predicted_red_score : match.red_score)).foregroundColor(.red).font(.system(size: 18)).frame(alignment: .leading).opacity((match.predicted && predictions) ? 0.6 : 1).bold()
                Spacer()
                Text(String(describing: (match.predicted && predictions) ? match.predicted_blue_score : match.blue_score)).foregroundColor(.blue).font(.system(size: 18)).frame(alignment: .trailing).opacity((match.predicted && predictions) ? 0.6 : 1).bold()
            }
        }
        else {
            Spacer()
            Text(match.field).font(.system(size: 15)).foregroundColor(.secondary)
            Spacer()
        }
    }
    
    func isPredicted(match: String) -> Bool {
        let split = match.split(separator: "&&")
        let match = matches[Int(split[0]) ?? 0]
        
        return match.predicted && predictions
    }
    
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
                List($matches_list) { name in
                    NavigationLink(destination: MatchNotes(event: event, match: matches[Int(name.wrappedValue.split(separator: "&&")[0])!]).environmentObject(settings).environmentObject(dataController)) {
                        HStack {
                            VStack {
                                Text(name.wrappedValue.split(separator: "&&")[1]).font(.system(size: 15)).frame(width: 60, alignment: .leading).opacity(isPredicted(match: name.wrappedValue) ? 0.6 : 1).bold()
                                Spacer().frame(maxHeight: 4)
                                Text(name.wrappedValue.split(separator: "&&")[8]).font(.system(size: 12)).frame(width: 60, alignment: .leading)
                            }.frame(width: 40)
                            VStack {
                                if String(teams_map[String(name.wrappedValue.split(separator: "&&")[3])] ?? "") != "" {
                                    Text(String(teams_map[String(name.wrappedValue.split(separator: "&&")[2])] ?? "")).foregroundColor(.red).font(.system(size: 15))
                                    Text(String(teams_map[String(name.wrappedValue.split(separator: "&&")[3])] ?? "")).foregroundColor(.red).font(.system(size: 15))
                                }
                                else {
                                    Text(String(teams_map[String(name.wrappedValue.split(separator: "&&")[2])] ?? "")).foregroundColor(.red).font(.system(size: 15))
                                }
                            }.frame(width: 70)
                            centerDisplay(matchString: name.wrappedValue)
                            VStack {
                                if String(teams_map[String(name.wrappedValue.split(separator: "&&")[5])] ?? "") != "" {
                                    Text(String(teams_map[String(name.wrappedValue.split(separator: "&&")[4])] ?? "")).foregroundColor(.blue).font(.system(size: 15))
                                    Text(String(teams_map[String(name.wrappedValue.split(separator: "&&")[5])] ?? "")).foregroundColor(.blue).font(.system(size: 15))
                                }
                                else {
                                    Text(String(teams_map[String(name.wrappedValue.split(separator: "&&")[4])] ?? "")).foregroundColor(.blue).font(.system(size: 15))
                                }
                            }.frame(width: 70)
                        }.frame(maxHeight: 30)
                    }
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
