//
//  EventTeams.swift
//  VRC RoboScout
//
//  Created by William Castro on 3/28/23.
//

import SwiftUI

struct EventTeams: View {
    
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var navigation_bar_manager: NavigationBarManager
    
    @State var event: Event
    @State var division: Division?
    @State var showLoading = true
    @Binding var teams_map: [String: String]
    @Binding var event_teams: [Team]
    @State var event_teams_map = [String: Team]()
    @State var event_teams_list: [String]
    
    func generate_location(team: Team) -> String {
        var location_array = [team.city, team.region, team.country]
        location_array = location_array.filter{ $0 != "" }
        return location_array.joined(separator: ", ")
    }
    
    func fetch_event_teams_list() {
        DispatchQueue.global(qos: .userInteractive).async { [self] in
            
            if !self.event.rankings.keys.contains(self.division!) {
                self.event.fetch_rankings(division: self.division!)
            }
            
            DispatchQueue.main.async {
                self.event_teams_list = [String]()
                
                for ranking in self.event.rankings[self.division!]! {
                    self.event_teams_list.append(self.teams_map[String(ranking.team.id)] ?? "")
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
            if division != nil && showLoading {
                ProgressView().padding().task{
                    fetch_event_teams_list()
                }
                Spacer()
            }
            else {
                List($event_teams_list) { team in
                    NavigationLink(destination: EventTeamMatches(teams_map: $teams_map, event: event, team: Team(number: team.wrappedValue, fetch: false)).environmentObject(settings)) {
                        HStack {
                            Text((event_teams_map[team.wrappedValue] ?? Team()).number).font(.system(size: 20)).minimumScaleFactor(0.01).frame(width: 60, height: 30, alignment: .leading)
                            VStack {
                                Text((event_teams_map[team.wrappedValue] ?? Team()).name).frame(maxWidth: .infinity, alignment: .leading).frame(height: 20)
                                Spacer().frame(height: 5)
                                Text(generate_location(team: (event_teams_map[team.wrappedValue] ?? Team()))).font(.system(size: 11)).frame(maxWidth: .infinity, alignment: .leading).frame(height: 15)
                            }
                        }
                    }
                }
            }
        }
        .onAppear{
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

