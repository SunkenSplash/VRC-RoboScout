//
//  EventView.swift
//  VRC RoboScout
//
//  Created by William Castro on 3/27/23.
//

import SwiftUI

struct EventDivisionRow: View {
    
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var favorites: FavoriteStorage
    @EnvironmentObject var dataController: RoboScoutDataController
    
    @Binding var teams_map: [String: String]
    @Binding var event_teams: [Team]
    
    var division: String
    var event: Event

    var body: some View {
        NavigationLink(destination: EventDivisionView(event: event, event_teams: event_teams, division: Division(id: Int(division.split(separator: "&&")[0]) ?? 0, name: String(division.split(separator: "&&")[1])), teams_map: teams_map).environmentObject(settings).environmentObject(favorites).environmentObject(dataController)) {
            Text(division.split(separator: "&&")[1])
        }
    }
}

class EventDivisions: ObservableObject {
    @Published var event_divisions: [String]
    
    init(event_divisions: [String]) {
        self.event_divisions = event_divisions
    }
    
    public func as_array() -> [String] {
        var out_list = [String]()
        for division in self.event_divisions {
            out_list.append(division)
        }
        return out_list
    }
}

struct EventView: View {
    
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var favorites: FavoriteStorage
    @EnvironmentObject var dataController: RoboScoutDataController
    
    @State private var event: Event
    @State private var team: Team?
    @State private var teams_map = [String: String]()
    @State private var event_teams = [Team]()
    @State private var event_teams_list = [String]()
    @State private var showLoading = true
    @State private var event_divisions: EventDivisions
    @State private var favorited = false
    
    init(event: Event, team: Team? = nil) {
        self.event = event
        self.team = team
        self.event_divisions = EventDivisions(event_divisions: event.divisions.map{ "\($0.id)&&\($0.name)" })
    }
    
    func fetch_event_data() {
        
        self.favorited = favorites.is_favorited(event_sku: event.sku)
        
        DispatchQueue.global(qos: .userInteractive).async { [self] in
            
            if showLoading == false {
                return
            }
            
            if self.event.name.isEmpty {
                self.event.fetch_info()
                self.event_divisions = EventDivisions(event_divisions: event.divisions.map{ "\($0.id)&&\($0.name)" })
            }
            
            if self.event.teams.isEmpty {
                event.fetch_teams()
            }
            self.event_teams = event.teams
            
            DispatchQueue.main.async {
                self.event_teams_list.removeAll()
                for team in self.event_teams {
                    self.teams_map[String(team.id)] = team.number
                    self.event_teams_list.append(team.number)
                }
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
            else {
                Form {
                    Section("Event") {
                        NavigationLink(destination: EventInformation(event: event).environmentObject(settings)) {
                            Text("Information")
                        }
                        NavigationLink(destination: EventTeams(event: event, teams_map: $teams_map, event_teams: $event_teams, event_teams_list: event_teams_list).environmentObject(settings).environmentObject(dataController)) {
                            Text("Teams")
                        }
                        if team != nil {
                            NavigationLink(destination: EventTeamMatches(teams_map: $teams_map, event: event, team: team!).environmentObject(settings).environmentObject(dataController)) {
                                Text("\(team!.number) Match List")
                            }
                        }
                    }
                    Section("Skills") {
                        NavigationLink(destination: EventSkillsRankings(event: event, teams_map: teams_map).environmentObject(settings)) {
                            Text("Skills Rankings")
                        }
                    }
                    Section("Divisions") {
                        List($event_divisions.event_divisions) { division in
                            EventDivisionRow(teams_map: $teams_map, event_teams: $event_teams, division: division.wrappedValue, event: event)
                                .environmentObject(settings)
                                .environmentObject(favorites)
                        }
                    }
                }
            }
        }.tint(settings.accentColor())
            .task{
                fetch_event_data()
            }
            .background(.clear)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text(self.event.name)
                            .fontWeight(.medium)
                            .font(.system(size: 19))
                            .foregroundColor(settings.navTextColor())
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            for sku in favorites.favorite_events {
                                if sku == event.sku {
                                    favorites.favorite_events.removeAll(where: {
                                        $0 == event.sku
                                    })
                                    defaults.set(favorites.favorite_events, forKey: "favorite_events")
                                    favorited = false
                                    return
                                }
                            }
                            Task {
                                favorites.favorite_events.append(self.event.sku)
                                defaults.set(favorites.favorite_events, forKey: "favorite_events")
                                favorited = true
                            }
                        }, label: {
                            if favorited {
                                Image(systemName: "star.fill").foregroundColor(settings.navTextColor())
                            }
                            else {
                                Image(systemName: "star").foregroundColor(settings.navTextColor())
                            }
                        })
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(settings.tabColor(), for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
    }
}

struct EventView_Previews: PreviewProvider {
    static var previews: some View {
        EventView(event: Event())
    }
}
