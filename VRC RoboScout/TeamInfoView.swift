//
//  TeamInfoView.swift
//  VRC RoboScout
//
//  Created by William Castro on 12/12/23.
//

import SwiftUI
import CoreData

struct TeamInfoView: View {
    
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var dataController: RoboScoutDataController
    
    @State var teamNumber: String
    @State var selectedView = 0
    
    var body: some View {
        VStack {
            Picker("Team Information", selection: $selectedView) {
                Text("Events").tag(UserSettings.getTeamInfoDefaultPage() == "events" ? 0 : 1)
                Text("Statistics").tag(UserSettings.getTeamInfoDefaultPage() == "statistics" ? 0 : 1)
            }.pickerStyle(.segmented).padding()
            Spacer()
            if selectedView == (UserSettings.getTeamInfoDefaultPage() == "events" ? 0 : 1) {
                TeamEventsView(team_number: teamNumber)
                    .environmentObject(settings)
                    .environmentObject(dataController)
            }
            else if selectedView == (UserSettings.getTeamInfoDefaultPage() == "statistics" ? 0 : 1) {
                TeamLookup(team_number: teamNumber, editable: false, fetch: true)
                    .environmentObject(settings)
                    .environmentObject(dataController)
            }
        }.background(.clear)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Team Info")
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
