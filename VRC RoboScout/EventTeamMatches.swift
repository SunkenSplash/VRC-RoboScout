//
//  EventTeamMatches.swift
//  VRC RoboScout
//
//  Created by William Castro on 3/28/23.
//

import SwiftUI
import CoreData

struct EventTeamMatches: View {
    
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var dataController: RoboScoutDataController
    
    @Binding var teams_map: [String: String]
    
    @State var event: Event
    @State var team: Team
    @State var division: Division?
    @State private var predictions = false
    @State private var calculating = false
    @State private var matches = [Match]()
    @State private var matches_list = [String]()
    @State private var showLoading = true
    @State private var showingTeamNotes = false
    
    @State var teamMatchNotes: [TeamMatchNote]? = nil
    
    private func updateDataSource() {
        self.dataController.fetchNotes(event: self.event, team: self.team) { (fetchNotesResult) in
            switch fetchNotesResult {
                case let .success(notes):
                    self.teamMatchNotes = notes
                case .failure(_):
                    print("Error fetching Core Data")
            }
        }
    }
    
    init(teams_map: Binding<[String: String]>, event: Event, team: Team, division: Division? = nil) {
        self._teams_map = teams_map
        self._event = State(initialValue: event)
        self._team = State(initialValue: team)
        self._division = State(initialValue: division)
    }
    
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

    func scoreToDisplay(match: String, index: Int) -> String {
        let split = match.split(separator: "&&")
        let match = matches[Int(split[0]) ?? 0]
        
        guard match.completed() || (match.predicted && predictions) else {
            return ""
        }
        
        if index == 6 {
            return String(describing: (match.predicted && predictions) ? match.predicted_red_score : match.red_score)
        }
        else {
            return String(describing: (match.predicted && predictions) ? match.predicted_blue_score : match.blue_score)
        }
    }
    
    func isPredicted(match: String) -> Bool {
        let split = match.split(separator: "&&")
        let match = matches[Int(split[0]) ?? 0]
        
        return match.predicted && predictions
    }
    
    func conditionalColor(match: String) -> Color {
        let split = match.split(separator: "&&")
        let match = matches[Int(split[0]) ?? 0]
        
        guard match.completed() || (match.predicted && predictions) else {
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
                    DispatchQueue.main.async {
                        self.predictions = false
                        self.calculating = false
                    }
                }
            }
            
            if predict, let division = division {
                do {
                    try self.event.predict_matches(division: division)
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
                    NavigationLink(destination: MatchNotes(event: event, match: matches[Int(name.wrappedValue.split(separator: "&&")[0])!]).environmentObject(settings).environmentObject(dataController)) {
                        HStack {
                            VStack {
                                Text(name.wrappedValue.split(separator: "&&")[1]).font(.system(size: 15)).frame(width: 60, alignment: .leading).foregroundColor(conditionalColor(match: name.wrappedValue)).opacity(isPredicted(match: name.wrappedValue) ? 0.6 : 1)
                                Spacer().frame(maxHeight: 4)
                                Text(name.wrappedValue.split(separator: "&&")[8]).font(.system(size: 12)).frame(width: 60, alignment: .leading)
                            }
                            VStack {
                                Text(String(teams_map[String(name.wrappedValue.split(separator: "&&")[2])] ?? "")).foregroundColor(.red).font(.system(size: 15)).underline(conditionalUnderline(match: name.wrappedValue, index: 2))
                                Text(String(teams_map[String(name.wrappedValue.split(separator: "&&")[3])] ?? "")).foregroundColor(.red).font(.system(size: 15)).underline(conditionalUnderline(match: name.wrappedValue, index: 3))
                            }.frame(width: 70)
                            Text(scoreToDisplay(match: name.wrappedValue, index: 6)).foregroundColor(.red).font(.system(size: 18)).frame(alignment: .leading).underline(conditionalUnderline(match: name.wrappedValue, index: 6)).opacity(isPredicted(match: name.wrappedValue) ? 0.6 : 1)
                            Spacer()
                            Text(scoreToDisplay(match: name.wrappedValue, index: 7)).foregroundColor(.blue).font(.system(size: 18)).frame(alignment: .trailing).underline(conditionalUnderline(match: name.wrappedValue, index: 7)).opacity(isPredicted(match: name.wrappedValue) ? 0.6 : 1)
                            VStack {
                                Text(String(teams_map[String(name.wrappedValue.split(separator: "&&")[4])] ?? "")).foregroundColor(.blue).font(.system(size: 15)).underline(conditionalUnderline(match: name.wrappedValue, index: 4))
                                Text(String(teams_map[String(name.wrappedValue.split(separator: "&&")[5])] ?? "")).foregroundColor(.blue).font(.system(size: 15)).underline(conditionalUnderline(match: name.wrappedValue, index: 5))
                            }.frame(width: 70)
                        }.frame(maxHeight: 30)
                    }
                }
            }
        }.sheet(isPresented: $showingTeamNotes) {
            Text("\(team.number) Match Notes").font(.title).padding().foregroundStyle(Color.primary)
            ScrollView {
                ForEach((teamMatchNotes ?? [TeamMatchNote]()).filter{ ($0.note ?? "") != "" }, id: \.self) { teamNote in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(teamNote.match_name ?? "Unknown Match").font(.headline).foregroundStyle(teamNote.winning_alliance == 0 ? (teamNote.played ? Color.yellow : Color.primary) : (teamNote.winning_alliance == teamNote.team_alliance ? Color.green : Color.red))
                            Text(teamNote.note ?? "No note.").foregroundStyle(Color.primary)
                        }
                        Spacer()
                    }.padding()
                }
            }
        }.onAppear{
            updateDataSource()
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
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingTeamNotes = true
                    }, label: {
                        Image(systemName: "note.text")
                    })
                    if division != nil {
                        Button(action: {
                            predictions = !predictions
                            calculating = true
                            fetch_info(predict: predictions)
                        }, label: {
                            if calculating && predictions {
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
