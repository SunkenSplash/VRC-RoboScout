//
//  EventInfoView.swift
//  VRC RoboScout Watch App
//
//  Created by William Castro on 7/29/24.
//

import SwiftUI

struct EventInfoView: View {
    
    @EnvironmentObject var settings: UserSettings
    
    @State var event: Event
    
    @State private var presentDivisions = false
    @State private var presentDeveloper = false
    
    let dateFormatter = DateFormatter()
    
    func skuWithSpace() -> String {
        var array = Array(event.sku)
        let firstNum = array.firstIndex {
            $0.isNumber
        }
        array.insert(" ", at: firstNum!)
        return String(array)
    }
    
    init(event: Event) {
        self.event = event
        dateFormatter.dateFormat = "yyyy-MM-dd"
    }
        
    var body: some View {
        VStack {
            List {
                Text(event.name).multilineTextAlignment(.center).padding(EdgeInsets(top: 5, leading: -10, bottom: 5, trailing: -10)).listRowBackground(EmptyView()).frame(maxWidth: .infinity)
                HStack {
                    Text("Teams")
                    Spacer()
                    Text(String(event.teams.count))
                }
                HStack {
                    Button("Divisions") {
                        presentDivisions = true
                    }
                    Spacer()
                    Text(String(event.divisions.count))
                }.fullScreenCover(isPresented: $presentDivisions) {
                    List(event.divisions.map{ $0.name }, id: \.self) {
                        Text($0)
                    }
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
                    Text((API.season_id_map[UserSettings.getGradeLevel() != "College" ? 0 : 1][event.season] ?? "").split(separator: " ").dropFirst().joined(separator: " "))
                }
                HStack {
                    Button("Developer") {
                        presentDeveloper = true
                    }
                    Spacer()
                    Text(skuWithSpace())
                }.fullScreenCover(isPresented: $presentDeveloper) {
                    List {
                        HStack {
                            Text("ID")
                            Spacer()
                            Text("\(String(event.id))")
                        }
                        HStack {
                            Text("SKU")
                            Spacer()
                            Text(event.sku)
                        }
                    }
                }
            }
        }.background(.clear)
            .navigationTitle("Event Info")
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    EventInfoView(event: Event())
}
