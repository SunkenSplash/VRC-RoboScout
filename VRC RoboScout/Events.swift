//
//  Events.swift
//  VRC RoboScout
//
//  Created by William Castro on 3/27/23.
//

import SwiftUI

struct TeamEvent: Identifiable {
    let id = UUID()
    let sku: String
}

struct EventRow: View {
    
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var favorites: FavoriteStorage
    
    private var event: Event
    private var team: Team
    
    init(event: Event, team: Team) {
        self.event = event
        self.team = team
    }
    
    func generate_location() -> String {
        var location_array = [self.event.city, self.event.region, self.event.country]
        location_array = location_array.filter{ $0 != "" }
        return location_array.joined(separator: ", ")
    }

    var body: some View {
        NavigationLink(destination: EventView(event: self.event, team: self.team).environmentObject(favorites).environmentObject(settings)) {
            VStack {
                Text(self.event.name).frame(maxWidth: .infinity, alignment: .leading).frame(height: 20)
                Spacer().frame(height: 5)
                HStack {
                    Text(generate_location()).font(.system(size: 11))
                    Spacer()
                    Text(event.start!, style: .date).font(.system(size: 11))
                }
            }
        }
    }
}

class TeamEvents: ObservableObject {
    @Published var event_indexes: [String]
    @Published var events: [Event]
    
    init(team: Team = Team(id: 0, fetch: false)) {
        event_indexes = [String]()
        events = [Event]()
        if team.id == 0 {
            return
        }
        team.fetch_events()
        events = team.events
        var count = 0
        for _ in events {
            event_indexes.append(String(count))
            count += 1
        }
        event_indexes.reverse()
    }
}


struct Events: View {
    
    @EnvironmentObject var settings: UserSettings
    @State private var events: TeamEvents
    @State private var team: Team
    @State private var team_number: String
    @State private var showLoading = true
    
    init(team_number: String) {
        self.team = Team(id: 0, fetch: false)
        self.team_number = team_number
        self.events = TeamEvents()
    }
    
    func fetch_events() {
        DispatchQueue.global(qos: .userInteractive).async { [self] in
            if self.team.number != "" && !self.events.events.isEmpty {
                return
            }
            
            let fetched_team = Team(number: self.team_number)
            let fetched_events = TeamEvents(team: fetched_team)
            
            DispatchQueue.main.async {
                self.team = fetched_team
                self.events = fetched_events
                self.showLoading = false
            }
        }
    }
        
    var body: some View {
        VStack {
            if showLoading {
                ProgressView().padding()
            }
            List(events.event_indexes) { event_index in
                EventRow(event: events.events[Int(event_index)!], team: team)
            }
        }.task{
            fetch_events()
        }.background(.clear)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("\(self.team_number) Events")
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

struct Events_Previews: PreviewProvider {
    static var previews: some View {
        Events(team_number: "2733J")
    }
}

