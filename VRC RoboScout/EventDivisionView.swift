//
//  EventDivisionView.swift
//  VRC RoboScout
//
//  Created by William Castro on 4/20/23.
//

import SwiftUI

public enum PredictionState {
    case disabled
    case off
    case calculating
    case on
}

public class PredictionManager: ObservableObject {
    @Published var state = PredictionState.off
}

struct EventDivisionView: View {
    
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var favorites: FavoriteStorage
    @EnvironmentObject var dataController: RoboScoutDataController
    
    @StateObject var navigation_bar_manager = NavigationBarManager(title: "Rankings")
    @StateObject var prediction_manager = PredictionManager()
    
    @State var event: Event
    @State var event_teams: [Team]
    @State var division: Division
    @State var teams_map: [String: String]
    @State var division_teams_list: [String]
    @State var matchNotesByTeam = [String: [TeamMatchNote]]()
    @State var showingNotes = false
    @State var showingInfo = false
    
    func getMatchNotesByTeam() {
        var matchNotes = [TeamMatchNote]()
        self.dataController.fetchNotes(event: self.event) { (fetchNotesResult) in
            switch fetchNotesResult {
                case let .success(notes):
                    matchNotes = notes
                case .failure(_):
                    print("Error fetching Core Data")
            }
        }
        self.matchNotesByTeam = [String: [TeamMatchNote]]()
        for note in matchNotes {
            if !self.matchNotesByTeam.keys.contains(note.team_number ?? "") {
                self.matchNotesByTeam[note.team_number ?? ""] = [TeamMatchNote]()
            }
        }
        for note in matchNotes {
            self.matchNotesByTeam[note.team_number ?? ""]?.append(note)
        }
    }
    
    func shortenedMatchName(matchName: String) -> String {
        var name = matchName
        name.replace("Qualifier", with: "Q")
        name.replace("Practice", with: "P")
        name.replace("Final", with: "F")
        name.replace("#", with: "")
        return name
    }
    
    func fetch_division_teams_list() {
        DispatchQueue.global(qos: .userInteractive).async { [self] in
            
            if !self.event.rankings.keys.contains(self.division) {
                self.event.fetch_rankings(division: self.division)
            }
            
            if self.event.rankings[self.division]!.isEmpty && !self.event.matches.keys.contains(self.division) {
                self.event.fetch_matches(division: self.division)
            }
            
            DispatchQueue.main.async {
                self.division_teams_list = [String]()
                
                if !self.event.rankings[self.division]!.isEmpty {
                    for ranking in self.event.rankings[self.division]! {
                        self.division_teams_list.append(self.teams_map[String(ranking.team.id)] ?? "")
                    }
                }
                else {
                    for match in self.event.matches[self.division]! {
                        var match_teams = match.red_alliance
                        match_teams.append(contentsOf: match.blue_alliance)
                        for team in match_teams {
                            if !self.division_teams_list.contains(self.teams_map[String(team.id)] ?? "") {
                                self.division_teams_list.append(self.teams_map[String(team.id)] ?? "")
                            }
                        }
                    }
                }
                self.division_teams_list.sort()
                self.division_teams_list.sort(by: {
                    (Int($0.filter("0123456789".contains)) ?? 0) < (Int($1.filter("0123456789".contains)) ?? 0)
                })
            }
        }
    }
    
    init(event: Event, event_teams: [Team], division: Division, teams_map: [String: String]) {
        self.event = event
        self.event_teams = event_teams
        self.division = division
        self.teams_map = teams_map
        self.division_teams_list = [String]()
    }
    
    var body: some View {
        TabView {
            EventTeams(event: self.event, division: self.division, teams_map: $teams_map, event_teams: $event_teams, event_teams_list: [String]())
                .tabItem {
                    if UserSettings.getMinimalistic() {
                        Image(systemName: "person.3.fill")
                    }
                    else {
                        Label("Teams", systemImage: "person.3.fill")
                    }
                }
                .environmentObject(favorites)
                .environmentObject(settings)
                .environmentObject(dataController)
                .environmentObject(navigation_bar_manager)
                .tint(settings.buttonColor())
            EventDivisionMatches(teams_map: $teams_map, event: self.event, division: self.division)
                .tabItem {
                    if UserSettings.getMinimalistic() {
                        Image(systemName: "clock.fill")
                    }
                    else {
                        Label("Match List", systemImage: "clock.fill")
                    }
                }
                .environmentObject(favorites)
                .environmentObject(settings)
                .environmentObject(navigation_bar_manager)
                .environmentObject(prediction_manager)
                .environmentObject(dataController)
                .tint(settings.buttonColor())
            EventDivisionRankings(event: self.event, division: self.division, teams_map: teams_map)
                .tabItem {
                    if UserSettings.getMinimalistic() {
                        Image(systemName: "list.number")
                    }
                    else {
                        Label("Rankings", systemImage: "list.number")
                    }
                }
                .environmentObject(favorites)
                .environmentObject(settings)
                .environmentObject(dataController)
                .environmentObject(navigation_bar_manager)
                .tint(settings.buttonColor())
                .onAppear{
                    getMatchNotesByTeam()
                }
                .sheet(isPresented: $showingNotes) {
                    Text("\(division.name) Match Notes").font(.title).multilineTextAlignment(.center).padding()
                    if self.matchNotesByTeam.isEmpty {
                        Text("No notes.")
                    }
                    ScrollView {
                        ForEach(Array(matchNotesByTeam.keys.sorted().sorted(by: { (Int($0.filter("0123456789".contains)) ?? 0) < (Int($1.filter("0123456789".contains)) ?? 0) })), id: \.self) { team_number in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(team_number).font(.title2)
                                    ForEach(self.matchNotesByTeam[team_number] ?? [TeamMatchNote](), id: \.self) { note in
                                        HStack(spacing: 0) {
                                            Text("\(shortenedMatchName(matchName: note.match_name ?? "Unknown Match")): ").foregroundStyle(note.winning_alliance == 0 ? (note.played ? Color.yellow : Color.primary) : (note.winning_alliance == note.team_alliance ? Color.green : Color.red))
                                            Text(note.note ?? "")
                                        }
                                    }
                                }
                                Spacer()
                            }.padding()
                        }
                    }
                }
                .sheet(isPresented: $showingInfo) {
                    Text("Ranking Performance Ratings")
                        .font(.headline)
                        .padding()
                    ScrollView {
                        VStack(alignment: .leading) {
                            Text("WP (Win Points) are the primary deciding factor in rankings. They are awarded by:").padding()
                            BulletList(listItems: ["Winning a match (+2 win points)", "Drawing a match (+1 win point)", "Earning the Autonomous Win Point (+1 win point)"], listItemSpacing: 10).padding()
                            Text("AP (Autonomous Points) are the first tiebreaker in rankings. They are awarded by:").padding()
                            BulletList(listItems: ["Winning the autonomous period (full points)", "Autonomous tie (half points)"], listItemSpacing: 10).padding()
                            Text("SP (Strength of Schedule Points) are the second tiebreaker in rankings. They are a measure of how difficult a team's schedule is, and are equal to the sum of the losing alliance scores for each match.").padding()
                            Text("OPR (Offensive Power Rating) is the scoring power a robot has. It can be considered a measure of how many additional points a team brings to their alliance in a match. Higher is better.").padding()
                            Text("DPR (Defensive Power Rating) is the defensive power of a robot and can be considered a measure of how much a team contibutes to the score of the opposing alliance. Lower is better.").padding()
                            Text("CCWM (Calculated Contribution to Winning Margin) is a measure of the positive impact a robot brings to an alliance. It is equal to OPR - DPR. Higher is better.").padding()
                        }
                    }
                }
            EventDivisionAwards(event: self.event, division: self.division)
                .tabItem {
                    if UserSettings.getMinimalistic() {
                        Image(systemName: "trophy")
                    }
                    else {
                        Label("Awards", systemImage: "trophy")
                    }
                }
                .environmentObject(favorites)
                .environmentObject(settings)
                .environmentObject(navigation_bar_manager)
                .tint(settings.buttonColor())
        }.onAppear {
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithDefaultBackground()
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
            fetch_division_teams_list()
        }.tint(settings.buttonColor())
            .background(.clear)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text(navigation_bar_manager.title)
                                .fontWeight(.medium)
                                .font(.system(size: 19))
                                .foregroundColor(settings.topBarContentColor())
                                .foregroundColor(settings.topBarContentColor())
                        }
                        if navigation_bar_manager.title.contains("Teams") {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                NavigationLink(destination: DataExporter(event: event, event_teams_list: division_teams_list).environmentObject(settings)) {
                                    Image(systemName: "doc.badge.plus").foregroundColor(settings.topBarContentColor())
                                }
                            }
                        }
                        if navigation_bar_manager.title.contains("Rankings") {
                            ToolbarItemGroup(placement: .navigationBarTrailing) {
                                Button(action: {
                                    showingNotes = true
                                }, label: {
                                    Image(systemName: "note.text").foregroundColor(settings.topBarContentColor())
                                })
                                Button(action: {
                                    showingInfo = true
                                }, label: {
                                    Image(systemName: "info.circle").foregroundColor(settings.topBarContentColor())
                                })
                            }
                        }
                        else if navigation_bar_manager.title.contains("Match List") {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button(action: {
                                    if prediction_manager.state == PredictionState.off {
                                        prediction_manager.state = PredictionState.calculating
                                    }
                                    else if prediction_manager.state == PredictionState.on {
                                        prediction_manager.state = PredictionState.off
                                    }
                                    self.event = self.event
                                }, label: {
                                    if prediction_manager.state == PredictionState.disabled {
                                        Image(systemName: "bolt.slash").foregroundColor(settings.topBarContentColor())
                                    }
                                    else if prediction_manager.state == PredictionState.off {
                                        Image(systemName: "bolt").foregroundColor(settings.topBarContentColor())
                                    }
                                    else if prediction_manager.state == PredictionState.calculating {
                                        ProgressView().foregroundColor(settings.topBarContentColor())
                                    }
                                    else {
                                        Image(systemName: "bolt.fill").foregroundColor(settings.topBarContentColor())
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

struct EventDivisionView_Previews: PreviewProvider {
    static var previews: some View {
        EventDivisionView(event: Event(), event_teams: [Team](), division: Division(), teams_map: [String: String]())
    }
}
