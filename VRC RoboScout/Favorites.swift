//
//  Favorites.swift
//  VRC RoboScout
//
//  Created by William Castro on 2/9/23.
//

import SwiftUI

struct FavoriteTeamsRow: View {
    
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var favorites: FavoriteStorage
    @EnvironmentObject var dataController: RoboScoutDataController
    
    var team: String

    var body: some View {
        NavigationLink(destination: TeamInfoView(teamNumber: team).environmentObject(settings).environmentObject(dataController)) {
            Text(team)
        }
    }
}

struct FavoriteEventsRow: View {
    
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var favorites: FavoriteStorage
    @EnvironmentObject var dataController: RoboScoutDataController
    
    var sku: String
    var data: [String: Event]
    
    func generate_location(event: Event) -> String {
        var location_array = [event.city, event.region, event.country]
        location_array = location_array.filter{ $0 != "" }
        return location_array.joined(separator: ", ").replacingOccurrences(of: "United States", with: "USA")
    }

    var body: some View {
        NavigationLink(destination: EventView(event: (data[sku] ?? Event(sku: sku, fetch: false))).environmentObject(settings).environmentObject(dataController)) {
            VStack {
                Text((data[sku] ?? Event(sku: sku, fetch: false)).name).frame(maxWidth: .infinity, alignment: .leading).frame(height: 20)
                Spacer().frame(height: 5)
                HStack {
                    Text(generate_location(event: data[sku] ?? Event(sku: sku, fetch: false))).font(.system(size: 11))
                    Spacer()
                    Text((data[sku] ?? Event(sku: sku, fetch: false)).start ?? Date(), style: .date).font(.system(size: 11))
                }
            }
        }
    }
}

class FavoriteStorage: ObservableObject {

    @Published var favorite_teams: [String]
    @Published var favorite_events: [String]
    
    init(favorite_teams: [String], favorite_events: [String]) {
        self.favorite_teams = favorite_teams
        self.favorite_events = favorite_events.sorted()
        self.sort_teams()
    }
    
    public func teams_as_array() -> [String] {
        var out_list = [String]()
        for team in self.favorite_teams {
            out_list.append(team)
        }
        return out_list
    }
    
    public func sort_teams() {
        self.favorite_teams.sort()
        self.favorite_teams.sort(by: {
            (Int($0.filter("0123456789".contains)) ?? 0) < (Int($1.filter("0123456789".contains)) ?? 0)
        })
    }
    
    public func is_favorited(event_sku: String) -> Bool {
        return self.favorite_events.contains(event_sku)
    }
}

struct Favorites: View {
    
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var favorites: FavoriteStorage
    @EnvironmentObject var dataController: RoboScoutDataController
    @EnvironmentObject var navigation_bar_manager: NavigationBarManager
    
    @State var event_sku_map = [String: Event]()
    @State var showEvents = false
    
    @Binding var tab_selection: Int
    @Binding var lookup_type: Int
    
    func generate_event_sku_map() {
        DispatchQueue.global(qos: .userInteractive).async { [self] in
            
            let data = RoboScoutAPI.robotevents_request(request_url: "/events", params: ["sku": favorites.favorite_events])
            var map = [String: Event]()

            for event_data in data {
                let event = Event(fetch: false, data: event_data)
                map[event.sku] = event
            }
            
            DispatchQueue.main.async {
                event_sku_map = map
                sort_events_by_date()
                showEvents = true
            }
            
        }
    }
    
    func sort_events_by_date() {
        // The start of a date can be determined with event_sku_map[sku].start
        favorites.favorite_events.sort{ (sku1, sku2) -> Bool in
            let event1 = event_sku_map[sku1] ?? Event(sku: sku1, fetch: false)
            let event2 = event_sku_map[sku2] ?? Event(sku: sku2, fetch: false)
            return event1.start ?? Date() > event2.start ?? Date()
        }
    }
    
    func deleteTeam(at offsets: IndexSet) {
        favorites.favorite_teams.remove(atOffsets: offsets)
        favorites.sort_teams()
        defaults.set(favorites.favorite_teams, forKey: "favorite_teams")
    }
    
    func deleteEvent(at offsets: IndexSet) {
        favorites.favorite_events.remove(atOffsets: offsets)
        defaults.set(favorites.favorite_events, forKey: "favorite_events")
    }
        
    var body: some View {
        VStack {
            Form {
                Section($favorites.favorite_teams.count > 0 ? "Favorite Teams" : "Add favorite teams in the team lookup") {
                    if !favorites.favorite_teams.isEmpty {
                        List {
                            ForEach($favorites.favorite_teams, id: \.self) { team in
                                FavoriteTeamsRow(team: team.wrappedValue)
                                    .environmentObject(favorites)
                                    .environmentObject(dataController)
                            }.onDelete(perform: deleteTeam)
                        }
                    }
                    else {
                        List {
                            Button("Find a team") {
                                tab_selection = 3
                                lookup_type = 0
                            }
                        }
                    }
                }
                Section($favorites.favorite_events.count > 0 ? "Favorite Events" : "Add favorite events on event pages") {
                    if showEvents && !favorites.favorite_events.isEmpty {
                        List {
                            ForEach($favorites.favorite_events, id: \.self) { sku in
                                FavoriteEventsRow(sku: sku.wrappedValue, data: event_sku_map)
                                    .environmentObject(favorites)
                                    .environmentObject(dataController)
                            }.onDelete(perform: deleteEvent)
                        }
                    }
                    else if !favorites.favorite_events.isEmpty {
                        ProgressView().frame(maxWidth: .infinity)
                    }
                    else {
                        List {
                            Button("Find an event") {
                                tab_selection = 3
                                lookup_type = 1
                            }
                        }
                    }
                }
            }.onAppear{
                if event_sku_map.count != favorites.favorite_events.count {
                    generate_event_sku_map()
                }
            }
        }.onAppear{
            navigation_bar_manager.title = "Favorites"
        }
    }
}

struct Favorites_Previews: PreviewProvider {
    static var previews: some View {
        Favorites(tab_selection: .constant(0), lookup_type: .constant(0))
    }
}
