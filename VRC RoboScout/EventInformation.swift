//
//  EventInformation.swift
//  VRC RoboScout
//
//  Created by William Castro on 3/27/23.
//

import SwiftUI

struct EventInformation: View {
    
    @EnvironmentObject var settings: UserSettings
    
    @State var event: Event
    
    let dateFormatter = DateFormatter()
    
    init(event: Event) {
        self.event = event
        dateFormatter.dateFormat = "yyyy-MM-dd"
    }
        
    var body: some View {
        VStack {
            Spacer()
            Text(event.name).font(.title2).multilineTextAlignment(.center).padding()
            List {
                HStack {
                    Text("Teams")
                    Spacer()
                    Text(String(event.teams.count))
                }
                HStack {
                    Menu("Divisions") {
                        ForEach(event.divisions.map{ $0.name }, id: \.self) {
                            Text($0)
                        }
                    }
                    Spacer()
                    Text(String(event.divisions.count))
                }
                HStack {
                    Text("City")
                    Spacer()
                    Text(event.city)
                }
                HStack {
                    Text("Region")
                    Spacer()
                    Text(event.region)
                }
                HStack {
                    Text("Country")
                    Spacer()
                    Text(event.country)
                }
                HStack {
                    Text("Date")
                    Spacer()
                    Text(event.start!, style: .date)
                }
                HStack {
                    Text("Season")
                    Spacer()
                    Text(API.season_id_map[event.season] ?? "")
                }
                HStack {
                    Menu("Developer") {
                        Text("ID: \(String(event.id))")
                        Text("SKU: \(event.sku)")
                    }
                }
            }
            Spacer()
        }.background(.clear)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Event Info")
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

struct EventInformation_Previews: PreviewProvider {
    static var previews: some View {
        EventInformation(event: Event())
    }
}

