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
        
        if (alliance == 1 && index == 6) || (alliance == 2 && index == 7) {
            return true
        }
        
        return false
    }
    
    func conditionalColor(match: String) -> Color {
        let split = match.split(separator: "&&")
        let match = matches[Int(split[0]) ?? 0]
        let victor = match.winning_alliance()
        
        if victor == 0 {
            return .yellow
        }
        else if victor == match.alliance_for(team: self.team) {
            return .green
        }
        
        return .red
    }
    
    func fetch_info() {
        DispatchQueue.global(qos: .userInteractive).async { [self] in
            
            if self.team.number != "" {
                self.team = Team(number: self.team.number)
            }
            else {
                self.team = Team(id: self.team.id)
            }
            
            let matches = self.team.matches_at(event: event)

            // Time should be in the format of "HH:mm" AM/PM
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"

            DispatchQueue.main.async {
                self.team = Team(number: self.team.number)
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
            }
            
            List($matches_list) { name in
                HStack {
                    VStack {
                        Text(name.wrappedValue.split(separator: "&&")[1]).frame(width: 60, alignment: .leading).foregroundColor(conditionalColor(match: name.wrappedValue))
                        Text(name.wrappedValue.split(separator: "&&")[8]).font(.system(size: 12)).frame(width: 60, alignment: .leading)
                    }
                    VStack {
                        Text(String(teams_map[String(name.wrappedValue.split(separator: "&&")[2])] ?? "")).foregroundColor(.red).font(.system(size: 15)).underline(conditionalUnderline(match: name.wrappedValue, index: 2))
                        Text(String(teams_map[String(name.wrappedValue.split(separator: "&&")[3])] ?? "")).foregroundColor(.red).font(.system(size: 15)).underline(conditionalUnderline(match: name.wrappedValue, index: 3))
                    }.frame(width: 80)
                    Text(name.wrappedValue.split(separator: "&&")[6]).foregroundColor(.red).font(.system(size: 19)).frame(alignment: .leading).underline(conditionalUnderline(match: name.wrappedValue, index: 6))
                    Spacer()
                    Text(name.wrappedValue.split(separator: "&&")[7]).foregroundColor(.blue).font(.system(size: 19)).frame(alignment: .trailing).underline(conditionalUnderline(match: name.wrappedValue, index: 7))
                    VStack {
                        Text(String(teams_map[String(name.wrappedValue.split(separator: "&&")[4])] ?? "")).foregroundColor(.blue).font(.system(size: 15)).underline(conditionalUnderline(match: name.wrappedValue, index: 4))
                        Text(String(teams_map[String(name.wrappedValue.split(separator: "&&")[5])] ?? "")).foregroundColor(.blue).font(.system(size: 15)).underline(conditionalUnderline(match: name.wrappedValue, index: 5))
                    }.frame(width: 80)
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
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(settings.tabColor(), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
    }
}

struct EventTeamMatches_Previews: PreviewProvider {
    static var previews: some View {
        EventTeamMatches(teams_map: .constant([String: String]()), event: Event(id: 0, fetch: false), team: Team(id: 0, fetch: false))
    }
}
