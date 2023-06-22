//
//  EventTeamMatches.swift
//  VRC RoboScout
//
//  Created by William Castro on 3/28/23.
//

import SwiftUI

struct EventTeamMatches: View {
    
    @EnvironmentObject var settings: UserSettings
    
    @Binding var teams_map: [String: String]
    
    @State var event: Event
    @State var team: Team
    @State var division: Division?
    @State private var predictions = false
    @State private var calculating = false
    @State private var matches = [Match]()
    @State private var matches_list = [String]()
    @State private var showLoading = true
    
    func conditionalUnderline(match: String, index: Int) -> Bool {
        let split = match.split(separator: "&&")
        if Int(split[index]) == team.id {
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
    
    func showScore(match: String) -> Bool {
        let split = match.split(separator: "&&")
        let match = matches[Int(split[0]) ?? 0]
        
        if match.started == nil && match.red_score == 0 && match.blue_score == 0 {
            return false
        }
        
        return true
    }
    
    func isPredicted(match: String) -> Bool {
        let split = match.split(separator: "&&")
        let match = matches[Int(split[0]) ?? 0]
        
        return match.predicted
    }
    
    func conditionalColor(match: String) -> Color {
        let split = match.split(separator: "&&")
        let match = matches[Int(split[0]) ?? 0]
        let victor = match.winning_alliance()
        
        if match.started == nil && match.red_score == 0 && match.blue_score == 0 {
            return .primary
        }
        else if victor == nil {
            return .yellow
        }
        else if victor! == match.alliance_for(team: self.team) {
            return .green
        }
        else {
            return .red
        }
    }
    
    func fetch_info(predict: Bool = false) {
        DispatchQueue.global(qos: .userInteractive).async { [self] in
            
            var matches = [Match]()
            
            if self.team.id == 0 || self.team.number == "" {
                self.team = Team(id: self.team.id, number: self.team.number)
            }
            
            if division == nil {
                matches = self.team.matches_at(event: event)
            }
            else {
                do {
                    self.event.fetch_matches(division: division!)
                    try self.event.calculate_team_performance_ratings(division: division!)
                    matches = self.event.matches[division!]!.filter{
                        $0.alliance_for(team: self.team) != nil
                    }
                }
                catch {
                    matches = self.team.matches_at(event: event)
                    self.predictions = false
                    self.calculating = false
                }
            }
            
            if predict && division != nil {
                for match in matches {
                    
                    guard match.red_score == 0 && match.blue_score == 0 && match.started == nil else {
                        continue
                    }
                    
                    var red_opr = 0.0
                    var blue_opr = 0.0
                    var red_dpr = 0.0
                    var blue_dpr = 0.0
                    
                    match.predicted = true
                    for match_team in match.red_alliance {
                        red_opr += (self.event.team_performance_ratings[match_team.id] ?? TeamPerformanceRatings(team: match_team, event: self.event, opr: 0, dpr: 0, ccwm: 0)).opr
                        red_dpr += (self.event.team_performance_ratings[match_team.id] ?? TeamPerformanceRatings(team: match_team, event: self.event, opr: 0, dpr: 0, ccwm: 0)).dpr
                    }
                    for match_team in match.blue_alliance {
                        blue_opr += (self.event.team_performance_ratings[match_team.id] ?? TeamPerformanceRatings(team: match_team, event: self.event, opr: 0, dpr: 0, ccwm: 0)).opr
                        blue_dpr += (self.event.team_performance_ratings[match_team.id] ?? TeamPerformanceRatings(team: match_team, event: self.event, opr: 0, dpr: 0, ccwm: 0)).dpr
                    }
                    
                    match.red_score = Int(round((red_opr + blue_dpr) / 2))
                    match.blue_score = Int(round((blue_opr + red_dpr) / 2))
                }
            }
            
            matches.removeAll(where: {
                $0.round != Round.qualification && $0.round != Round.practice
            })

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
                self.calculating = false
            }
        }
    }
        
    var body: some View {
        VStack {
            if showLoading {
                ProgressView().padding()
            }
            else if matches.isEmpty {
                NoData()
            }
            else {
                List($matches_list) { name in
                    HStack {
                        VStack {
                            Text(name.wrappedValue.split(separator: "&&")[1]).font(.system(size: 15)).frame(width: 60, alignment: .leading).foregroundColor(conditionalColor(match: name.wrappedValue)).opacity(isPredicted(match: name.wrappedValue) ? 0.6 : 1)
                            Spacer().frame(maxHeight: 4)
                            Text(name.wrappedValue.split(separator: "&&")[8]).font(.system(size: 12)).frame(width: 60, alignment: .leading)
                        }
                        VStack {
                            Text(String(teams_map[String(name.wrappedValue.split(separator: "&&")[2])] ?? "")).foregroundColor(.red).font(.system(size: 15)).underline(conditionalUnderline(match: name.wrappedValue, index: 2))
                            Text(String(teams_map[String(name.wrappedValue.split(separator: "&&")[3])] ?? "")).foregroundColor(.red).font(.system(size: 15)).underline(conditionalUnderline(match: name.wrappedValue, index: 3))
                        }.frame(width: 80)
                        Text(name.wrappedValue.split(separator: "&&")[6]).foregroundColor(.red).font(.system(size: 19)).frame(alignment: .leading).underline(conditionalUnderline(match: name.wrappedValue, index: 6)).opacity(showScore(match: name.wrappedValue) ? (isPredicted(match: name.wrappedValue) ? 0.6 : 1) : 0)
                        Spacer()
                        Text(name.wrappedValue.split(separator: "&&")[7]).foregroundColor(.blue).font(.system(size: 19)).frame(alignment: .trailing).underline(conditionalUnderline(match: name.wrappedValue, index: 7)).opacity(showScore(match: name.wrappedValue) ? (isPredicted(match: name.wrappedValue) ? 0.6 : 1) : 0)
                        VStack {
                            Text(String(teams_map[String(name.wrappedValue.split(separator: "&&")[4])] ?? "")).foregroundColor(.blue).font(.system(size: 15)).underline(conditionalUnderline(match: name.wrappedValue, index: 4))
                            Text(String(teams_map[String(name.wrappedValue.split(separator: "&&")[5])] ?? "")).foregroundColor(.blue).font(.system(size: 15)).underline(conditionalUnderline(match: name.wrappedValue, index: 5))
                        }.frame(width: 80)
                    }.frame(maxHeight: 30)
                }
            }
        }.task{
            fetch_info()
        }
            .background(.clear)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("\(team.number) Match List")
                        .fontWeight(.medium)
                        .font(.system(size: 19))
                        .foregroundColor(settings.navTextColor())
                }
                if division != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            predictions = !predictions
                            calculating = true
                            fetch_info(predict: predictions)
                        }, label: {
                            if calculating {
                                ProgressView()
                            }
                            else if predictions {
                                Image(systemName: "bolt.fill")
                            }
                            else {
                                Image(systemName: "bolt")
                            }
                        })
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(settings.tabColor(), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
    }
}

struct EventTeamMatches_Previews: PreviewProvider {
    static var previews: some View {
        EventTeamMatches(teams_map: .constant([String: String]()), event: Event(), team: Team())
    }
}
