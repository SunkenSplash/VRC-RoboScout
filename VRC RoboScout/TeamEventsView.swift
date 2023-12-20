//
//  Events.swift
//  VRC RoboScout
//
//  Created by William Castro on 3/27/23.
//

import SwiftUI

struct EventRow: View {
    
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var favorites: FavoriteStorage
    @EnvironmentObject var dataController: RoboScoutDataController
    
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
        NavigationLink(destination: EventView(event: self.event, team: self.team).environmentObject(favorites).environmentObject(settings).environmentObject(dataController)) {
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


struct TeamEventsView: View {
    
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
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("\(self.team_number ?? "") Events")
                        .fontWeight(.medium)
                        .font(.system(size: 19))
                        .foregroundColor(settings.navTextColor())
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(settings.tabColor(), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .tint(settings.accentColor())
        
    }
}

struct TeamEventsView_Previews: PreviewProvider {
    static var previews: some View {
        TeamEventsView(team_number: "229V")
    }
}

