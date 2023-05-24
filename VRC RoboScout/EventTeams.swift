//
//  EventTeams.swift
//  VRC RoboScout
//
//  Created by William Castro on 3/28/23.
//

import SwiftUI

struct EventTeams: View {
    
    @EnvironmentObject var settings: UserSettings
    
    @State var event: Event
    @Binding var teams_map: [String: String]
    @Binding var event_teams: [Team]
    @Binding var event_teams_list: [String]
    
    func generate_location(team: Team) -> String {
        var location_array = [team.city, team.region, team.country]
        location_array = location_array.filter{ $0 != "" }
        return location_array.joined(separator: ", ")
    }
        
    var body: some View {
        VStack {
            List($event_teams_list) { team in
                NavigationLink(destination: EventTeamMatches(teams_map: $teams_map, event: event, team: Team(number: team.wrappedValue, fetch: false)).environmentObject(settings)) {
                    HStack {
                        Text(event_teams[event_teams_list.firstIndex(of: team.wrappedValue) ?? 0].number).font(.system(size: 20)).minimumScaleFactor(0.01).frame(width: 60, height: 30, alignment: .leading)
                        VStack {
                            Text(event_teams[event_teams_list.firstIndex(of: team.wrappedValue) ?? 0].name).frame(maxWidth: .infinity, alignment: .leading).frame(height: 20)
                            Spacer().frame(height: 5)
                            Text(generate_location(team: event_teams[event_teams_list.firstIndex(of: team.wrappedValue) ?? 0])).font(.system(size: 11)).frame(maxWidth: .infinity, alignment: .leading).frame(height: 15)
                        }
                    }
                }
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
        EventTeams(event: Event(id: 0, fetch: false), teams_map: .constant([String: String]()), event_teams: .constant([Team]()), event_teams_list: .constant([String]()))
    }
}

