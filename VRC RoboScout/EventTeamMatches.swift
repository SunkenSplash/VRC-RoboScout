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
                    try self.event.calculate_team_performance_ratings(division: division!, forceRealCalculation: true)
                }
                catch {
                    print("Failed to calculate team performance ratings")
                }
                matches = self.event.matches[division!]!.filter{
                    $0.alliance_for(team: self.team) != nil
                }
            }
            
            if predict, let division = division {
                do {
                    try self.event.predict_matches(division: division)
                }
                catch {
                    print("Failed to predict matches")
                }
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
                List($matches_list) { matchString in
                    MatchRowView(event: $event, matches: $matches, teams_map: $teams_map, predictions: $predictions, matchString: matchString, team: $team)
                }
            }
        }.sheet(isPresented: $showingTeamNotes) {
            Text("\(team.number) Match Notes").font(.title).padding().foregroundStyle(Color.primary)
            if (teamMatchNotes ?? [TeamMatchNote]()).filter({ ($0.note ?? "") != "" }).isEmpty {
                Text("No notes")
            }
            ScrollView {
                ForEach((teamMatchNotes ?? [TeamMatchNote]()).filter{ ($0.note ?? "") != "" }, id: \.self) { teamNote in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(teamNote.match_name ?? "Unknown Match").font(.title2).foregroundStyle(teamNote.winning_alliance == 0 ? (teamNote.played ? Color.yellow : Color.primary) : (teamNote.winning_alliance == teamNote.team_alliance ? Color.green : Color.red))
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
                        .foregroundColor(settings.topBarContentColor())
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if #available(iOS 16.2, *), false {
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
                                    Image(systemName: "bell").foregroundColor(settings.topBarContentColor())
                                }
                                else if matches.count >= 2 {
                                    Image(systemName: "bell.fill").foregroundColor(settings.topBarContentColor())
                                }
                                else {
                                    Image(systemName: "bell.slash").foregroundColor(settings.topBarContentColor())
                                }
                            }
                            else {
                                Image(systemName: "bell.slash").foregroundColor(settings.topBarContentColor())
                            }
                        })
                    }
                    Button(action: {
                        showingTeamNotes = true
                    }, label: {
                        Image(systemName: "note.text").foregroundColor(settings.topBarContentColor())
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
                            ProgressView().foregroundColor(settings.topBarContentColor())
                        }
                        else if predictions {
                            Image(systemName: "bolt.fill").foregroundColor(settings.topBarContentColor())
                        }
                        else if !matches.isEmpty {
                            Image(systemName: "bolt").foregroundColor(settings.topBarContentColor())
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
            .tint(settings.buttonColor())
    }
}

struct EventTeamMatches_Previews: PreviewProvider {
    static var previews: some View {
        EventTeamMatches(teams_map: .constant([String: String]()), event: Event(), team: Team())
    }
}
