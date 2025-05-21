//
//  EventTeams.swift
//  VRC RoboScout Watch App
//
//  Created by William Castro on 5/19/25.
//

import SwiftUI

struct EventTeamsView: View {
    
    @EnvironmentObject var settings: UserSettings
    
    @State var event: Event
    @State var division: Division?
    @State var showLoading = true
    @Binding var teams_map: [String: String]
    @Binding var event_teams: [Team]
    @State var event_teams_map = [String: Team]()
    @State var event_teams_list: [String]
    
    @State var selectedTab = UserSettings.getMatchTeamDefaultPage() == "matches" ? 0 : 1
    
    func generate_location(team: Team) -> String {
        var location_array = [team.city, team.region, team.country]
        location_array = location_array.filter{ $0 != "" }
        return location_array.joined(separator: ", ")
    }
    
    func fetch_event_teams_list() {
        DispatchQueue.global(qos: .userInteractive).async { [self] in
            
            if self.division != nil && !self.event.rankings.keys.contains(self.division!) {
                self.event.fetch_rankings(division: self.division!)
            }
            
            if self.division != nil && self.event.rankings[self.division!]!.isEmpty && !self.event.matches.keys.contains(self.division!) { // 5, 6
                self.event.fetch_matches(division: self.division!)
            }
            
            DispatchQueue.main.async {
                self.event_teams_list = [String]()
                
                if self.division != nil && !self.event.rankings[self.division!]!.isEmpty { // 8
                    for ranking in self.event.rankings[self.division!]! { // 9
                        self.event_teams_list.append(self.teams_map[String(ranking.team.id)] ?? "")
                    }
                }
                else if self.division != nil {
                    for match in self.event.matches[self.division!]! {
                        var match_teams = match.red_alliance
                        match_teams.append(contentsOf: match.blue_alliance)
                        for team in match_teams {
                            if !self.event_teams_list.contains(self.teams_map[String(team.id)] ?? "") {
                                self.event_teams_list.append(self.teams_map[String(team.id)] ?? "")
                            }
                        }
                    }
                }
                else {
                    self.event_teams_list = self.event.teams.map{ $0.number }
                }
                self.event_teams_list.sort()
                self.event_teams_list.sort(by: {
                    (Int($0.filter("0123456789".contains)) ?? 0) < (Int($1.filter("0123456789".contains)) ?? 0)
                })
                showLoading = false
            }
        }
    }
        
    var body: some View {
        VStack {
            if showLoading {
                ProgressView().padding()
                Spacer()
            }
            else if $event_teams_list.isEmpty {
                NoData()
            }
            else {
                List {
                    ForEach(event_teams_list, id: \.self) { teamNum in
                        NavigationLink(destination: {
                            TabView(selection: $selectedTab) {
                                EventTeamMatchesView(teams_map: $teams_map, event: event, team: Team(number: teamNum, fetch: false), division: division).tag(0)
                                TeamLookupView(team_number: teamNum, fetch: true).tag(1)
                            }
                        }) {
                            VStack {
                                Text((event_teams_map[teamNum] ?? Team()).number).font(.system(size: 20)).minimumScaleFactor(0.01).frame(maxWidth: .infinity, alignment: .leading).bold()
                                Text((event_teams_map[teamNum] ?? Team()).name).frame(maxWidth: .infinity, alignment: .leading).lineLimit(1)
                            }
                        }
                    }
                }
            }
        }
        .onAppear{
            fetch_event_teams_list()
            for team in event_teams {
                event_teams_map[team.number] = team
            }
            selectedTab = UserSettings.getMatchTeamDefaultPage() == "matches" ? 0 : 1
        }.background(.clear)
            .navigationTitle(division != nil ? division!.name : "Event Teams")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct EventTeamsView_Previews: PreviewProvider {
    static var previews: some View {
        EventTeamsView(event: Event(), teams_map: .constant([String: String]()), event_teams: .constant([Team]()), event_teams_list: [String]())
    }
}

