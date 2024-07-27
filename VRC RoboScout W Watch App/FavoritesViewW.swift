//
//  FavoritesViewW.swift
//  VRC RoboScout W Watch App
//
//  Created by William Castro on 7/26/24.
//

import Foundation
import SwiftUI

struct FavoritesViewW: View {
    
    @EnvironmentObject var wcSession: WatchSessionW
    
    @State var event_sku_map = [String: Event]()
    
    func generate_event_sku_map() {
        DispatchQueue.global(qos: .userInteractive).async { [self] in
            
            let data = RoboScoutAPI.robotevents_request(request_url: "/events", params: ["sku": wcSession.favorite_events])
            var map = [String: Event]()

            for event_data in data {
                let event = Event(fetch: false, data: event_data)
                map[event.sku] = event
            }
            
            DispatchQueue.main.async {
                event_sku_map = map
                sort_events_by_date()
            }
            
        }
    }
    
    func sort_events_by_date() {
        // The start of a date can be determined with event_sku_map[sku].start
        wcSession.favorite_events.sort{ (sku1, sku2) -> Bool in
            let event1 = event_sku_map[sku1] ?? Event(sku: sku1, fetch: false)
            let event2 = event_sku_map[sku2] ?? Event(sku: sku2, fetch: false)
            return event1.start ?? Date() > event2.start ?? Date()
        }
    }
        
    var body: some View {
        VStack {
            Form {
                Section("Favorite Teams") {
                    List(wcSession.favorite_teams, id: \.self) { team in
                        NavigationLink(destination: EmptyView()) {
                            Text(team)
                        }
                    }
                }
                Section("Favorite Events") {
                    if wcSession.favorite_events.sorted() != Array(event_sku_map.keys).sorted() {
                        ProgressView()
                            .onAppear{
                                generate_event_sku_map()
                            }
                    }
                    else {
                        List(wcSession.favorite_events, id: \.self) { sku in
                            NavigationLink(destination: EmptyView()) {
                                Text(event_sku_map[sku]?.name ?? "").lineLimit(2)
                            }
                        }
                    }
                }
            }
        }
    }
}
