//
//  TeamEventsViewW.swift
//  VRC RoboScout W Watch App
//
//  Created by William Castro on 7/29/24.
//

import SwiftUI

struct EventRow: View {
    
    @EnvironmentObject var wcSession: WatchSessionW
    
    @EnvironmentObject var settings: UserSettings
    
    private var event: Event
    private var team: Team?
    
    init(event: Event, team: Team? = nil) {
        self.event = event
        self.team = team
    }
    
    func generate_location() -> String {
        var location_array = [self.event.city, self.event.region, self.event.country]
        location_array = location_array.filter{ $0 != "" }
        return location_array.joined(separator: ", ").replacingOccurrences(of: "United States", with: "USA")
    }

    var body: some View {
        NavigationLink(destination: EventViewW(event: self.event, team: self.team).environmentObject(settings)) {
            Text(self.event.name).lineLimit(2)
        }
    }
}

class TeamEvents: ObservableObject {
    @Published var event_indexes: [String]
    @Published var events: [Event]
    
    init(team: Team? = nil) {
        event_indexes = [String]()
        events = [Event]()
        if team == nil {
            return
        }
        team!.fetch_events()
        events = team!.events
        var count = 0
        for _ in events {
            event_indexes.append(String(count))
            count += 1
        }
        event_indexes.reverse()
    }
}


struct TeamEventsViewW: View {
    
    @EnvironmentObject var wcSession: WatchSessionW
    
    @EnvironmentObject var settings: UserSettings
    
    @State private var events: TeamEvents
    @State private var team: Team?
    @State private var team_number: String?
    @State private var showLoading = true
    
    init(team_number: String?) {
        self.team = nil
        self.team_number = team_number
        self.events = TeamEvents()
    }
    
    func fetch_team_events() {
        DispatchQueue.global(qos: .userInteractive).async { [self] in
            if self.team != nil && !self.events.events.isEmpty {
                return
            }
            
            let fetched_team = Team(number: self.team_number ?? "")
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
                Spacer()
            }
            else if events.event_indexes.isEmpty {
                Spacer()
                NoData()
                Spacer()
            }
            else {
                List(events.event_indexes) { event_index in
                    EventRow(event: events.events[Int(event_index)!], team: team)
                }
            }
        }.task{
            fetch_team_events()
        }.background(.clear)
            .navigationTitle("\(self.team_number ?? "") Events")
            .navigationBarTitleDisplayMode(.automatic)
            .tint(settings.buttonColor())
        
    }
}

#Preview {
    TeamEventsViewW(team_number: "229V")
}


