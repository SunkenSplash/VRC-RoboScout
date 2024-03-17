//
//  EventTeamMatches.swift
//  VRC RoboScout
//
//  Created by William Castro on 3/28/23.
//

import SwiftUI
import CoreData
import ActivityKit

enum AlertText: String {
    case enabled = "Match updates enabled. Your upcoming and most recent matches will be shown on your lock screen."
    case disabled = "Match updates disabled. You may reenable them at any time."
    case missingMatches = "Could not start match updates. Please try again when the match list has been released."
    case missingPermission = "You have disabled Live Activities for VRC RoboScout. Please reenable them in the settings app."
}

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
    @State private var alertText = AlertText.enabled
    @State private var showAlert = false
    
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
    
    @ViewBuilder
    func centerDisplay(matchString: String) -> some View {
        let split = matchString.split(separator: "&&")
        let match = matches[Int(split[0]) ?? 0]
        
        if match.completed() || (match.predicted && predictions) {
            HStack {
                Text(String(describing: (match.predicted && predictions) ? match.predicted_red_score : match.red_score)).foregroundColor(.red).font(.system(size: 18)).frame(alignment: .leading).underline(conditionalUnderline(match: matchString, index: 6)).opacity((match.predicted && predictions) ? 0.6 : 1).bold()
                Spacer()
                Text(String(describing: (match.predicted && predictions) ? match.predicted_blue_score : match.blue_score)).foregroundColor(.blue).font(.system(size: 18)).frame(alignment: .trailing).underline(conditionalUnderline(match: matchString, index: 7)).opacity((match.predicted && predictions) ? 0.6 : 1).bold()
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
                let matches = self.team.matches_at(event: event)
                if !matches.isEmpty {
                    self.division = (self.team.matches_at(event: event)[0]).division
                }
            }
            
            if division != nil {
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
                                Text(name.wrappedValue.split(separator: "&&")[1]).font(.system(size: 15)).frame(width: 60, alignment: .leading).foregroundColor(conditionalColor(match: name.wrappedValue)).opacity(isPredicted(match: name.wrappedValue) ? 0.6 : 1).bold()
                                Spacer().frame(maxHeight: 4)
                                Text(name.wrappedValue.split(separator: "&&")[8]).font(.system(size: 12)).frame(width: 60, alignment: .leading)
                            }.frame(width: 40)
                            VStack {
                                if String(teams_map[String(name.wrappedValue.split(separator: "&&")[3])] ?? "") != "" {
                                    Text(String(teams_map[String(name.wrappedValue.split(separator: "&&")[2])] ?? "")).foregroundColor(.red).font(.system(size: 15)).underline(conditionalUnderline(match: name.wrappedValue, index: 2))
                                    Text(String(teams_map[String(name.wrappedValue.split(separator: "&&")[3])] ?? "")).foregroundColor(.red).font(.system(size: 15)).underline(conditionalUnderline(match: name.wrappedValue, index: 3))
                                }
                                else {
                                    Text(String(teams_map[String(name.wrappedValue.split(separator: "&&")[2])] ?? "")).foregroundColor(.red).font(.system(size: 15)).underline(conditionalUnderline(match: name.wrappedValue, index: 2))
                                }
                            }.frame(width: 70)
                            centerDisplay(matchString: name.wrappedValue)
                            VStack {
                                if String(teams_map[String(name.wrappedValue.split(separator: "&&")[5])] ?? "") != "" {
                                    Text(String(teams_map[String(name.wrappedValue.split(separator: "&&")[4])] ?? "")).foregroundColor(.blue).font(.system(size: 15)).underline(conditionalUnderline(match: name.wrappedValue, index: 4))
                                    Text(String(teams_map[String(name.wrappedValue.split(separator: "&&")[5])] ?? "")).foregroundColor(.blue).font(.system(size: 15)).underline(conditionalUnderline(match: name.wrappedValue, index: 5))
                                }
                                else {
                                    Text(String(teams_map[String(name.wrappedValue.split(separator: "&&")[4])] ?? "")).foregroundColor(.blue).font(.system(size: 15)).underline(conditionalUnderline(match: name.wrappedValue, index: 4))
                                }
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
        }.alert(isPresented: $showAlert) {
            Alert(title: Text(alertText.rawValue), dismissButton: .default(Text("OK")))
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
                    if #available(iOS 16.2, *) {
                        Button(action: {
                            if ActivityAuthorizationInfo().areActivitiesEnabled {
                                self.showAlert = false
                                Task {
                                    do {
                                        if !activities.matchUpdatesActive(event: self.event, team: self.team) {
                                            DispatchQueue.main.async {
                                                self.alertText = AlertText.enabled
                                                self.showAlert = true
                                            }
                                            await activities.notificationTest()
                                            try await activities.startMatchUpdatesActivity(event: self.event, team: self.team, matches: self.matches)
                                        }
                                        else {
                                            DispatchQueue.main.async {
                                                self.alertText = AlertText.disabled
                                                self.showAlert = false
                                            }
                                            await activities.endMatchUpdatesActivity(event: self.event, team: self.team)
                                        }
                                    } catch {
                                        DispatchQueue.main.async {
                                            self.alertText = AlertText.missingMatches
                                            self.showAlert = true
                                        }
                                    }
                                }
                            }
                            else {
                                self.alertText = AlertText.missingPermission
                                self.showAlert = true
                            }
                        }, label: {
                            if ActivityAuthorizationInfo().areActivitiesEnabled {
                                if !activities.matchUpdatesActive(event: self.event, team: self.team) && matches.count >= 2 {
                                    Image(systemName: "bell").foregroundColor(settings.navTextColor())
                                }
                                else if matches.count >= 2 {
                                    Image(systemName: "bell.fill").foregroundColor(settings.navTextColor())
                                }
                                else {
                                    Image(systemName: "bell.slash").foregroundColor(settings.navTextColor())
                                }
                            }
                            else {
                                Image(systemName: "bell.slash").foregroundColor(settings.navTextColor())
                            }
                        })
                    }
                    Button(action: {
                        showingTeamNotes = true
                    }, label: {
                        Image(systemName: "note.text").foregroundColor(settings.navTextColor())
                    })
                    Button(action: {
                        if matches.isEmpty {
                            return
                        }
                        predictions = !predictions
                        calculating = true
                        fetch_info(predict: predictions)
                    }, label: {
                        if calculating && predictions {
                            ProgressView().foregroundColor(settings.navTextColor())
                        }
                        else if predictions {
                            Image(systemName: "bolt.fill").foregroundColor(settings.navTextColor())
                        }
                        else if !matches.isEmpty {
                            Image(systemName: "bolt").foregroundColor(settings.navTextColor())
                        }
                        else {
                            Image(systemName: "bolt.slash")
                        }
                    })
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(settings.tabColor(), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .tint(settings.accentColor())
    }
}

struct EventTeamMatches_Previews: PreviewProvider {
    static var previews: some View {
        EventTeamMatches(teams_map: .constant([String: String]()), event: Event(), team: Team())
    }
}
