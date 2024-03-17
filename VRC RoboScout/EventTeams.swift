//
//  EventTeams.swift
//  VRC RoboScout
//
//  Created by William Castro on 3/28/23.
//

import SwiftUI

struct EventTeams: View {
    
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var dataController: RoboScoutDataController
    @EnvironmentObject var navigation_bar_manager: NavigationBarManager
    
    @State var event: Event
    @State var division: Division?
    @State var showLoading = true
    @Binding var teams_map: [String: String]
    @Binding var event_teams: [Team]
    @State var event_teams_map = [String: Team]()
    @State var event_teams_list: [String]
    @State var teamNumberQuery = ""
    
    var searchResults: [String] {
        if teamNumberQuery.isEmpty {
            return event_teams_list
        }
        else {
            return event_teams_list.filter{ $0.lowercased().contains(teamNumberQuery.lowercased()) }
        }
    }
    
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
            
            if self.division != nil && self.event.rankings[self.division!]!.isEmpty && !self.event.matches.keys.contains(self.division!) {
                self.event.fetch_matches(division: self.division!)
            }
            
            DispatchQueue.main.async {
                self.event_teams_list = [String]()
                
                if self.division != nil && !self.event.rankings[self.division!]!.isEmpty {
                    for ranking in self.event.rankings[self.division!]! {
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
                NavigationView {
                    List {
                        ForEach(searchResults, id: \.self) { teamNum in
                            NavigationLink(destination: EventTeamView(teams_map: $teams_map, event: event, teamNumber: teamNum, division: division).environmentObject(settings).environmentObject(dataController)) {
                                HStack {
                                    Text((event_teams_map[teamNum] ?? Team()).number).font(.system(size: 20)).minimumScaleFactor(0.01).frame(width: 80, height: 30, alignment: .leading).bold()
                                    VStack {
                                        Text((event_teams_map[teamNum] ?? Team()).name).frame(maxWidth: .infinity, alignment: .leading).frame(height: 20)
                                        Spacer().frame(height: 5)
                                        Text(generate_location(team: (event_teams_map[teamNum] ?? Team()))).font(.system(size: 11)).frame(maxWidth: .infinity, alignment: .leading).frame(height: 15)
                                    }
                                }
                            }
                        }
                    }
                }.navigationViewStyle(StackNavigationViewStyle())
                    .searchable(text: $teamNumberQuery, prompt: "Enter a team number...")
                    .tint(settings.navTextColor())
            }
        }
        .onAppear{
            fetch_event_teams_list()
            for team in event_teams {
                event_teams_map[team.number] = team
            }
            if division != nil {
                navigation_bar_manager.title = "\(division!.name) Teams"
            }
        }.background(.clear)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Event Teams")
                        .fontWeight(.medium)
                        .font(.system(size: 19))
                        .foregroundColor(settings.navTextColor())
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: DataExporter(event: event, event_teams_list: event_teams_list).environmentObject(settings)) {
                        Image(systemName: "doc.badge.plus").foregroundColor(settings.navTextColor())
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(settings.tabColor(), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
    }
}

struct EventTeams_Previews: PreviewProvider {
    static var previews: some View {
        EventTeams(event: Event(), teams_map: .constant([String: String]()), event_teams: .constant([Team]()), event_teams_list: [String]())
    }
}

