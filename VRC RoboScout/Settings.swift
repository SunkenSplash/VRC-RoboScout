//
//  Settings.swift
//  VRC RoboScout
//
//  Created by William Castro on 3/3/23.
//

import SwiftUI
import CoreData

struct Settings: View {
    
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var favorites: FavoriteStorage
    @EnvironmentObject var dataController: RoboScoutDataController
    @EnvironmentObject var navigation_bar_manager: NavigationBarManager
    
    @State var selected_color = UserSettings().accentColor()
    @State var minimalistic = UserSettings().getMinimalistic()
    @State var adam_score = UserSettings().getAdamScore()
    @State var selected_season_id = UserSettings().getSelectedSeasonID()
    @State var apiKey = UserSettings.getRobotEventsAPIKey()
    @State var showLoading = false
    @State var showApply = false
    @State var clearedTeams = false
    @State var clearedEvents = false
    @State var clearedNotes = false
    
    func format_season_option(raw: String) -> String {
        var season = raw
        season = season.replacingOccurrences(of: "VRC ", with: "")
        
        let season_split = season.split(separator: "-")
        
        if season_split.count == 1 {
            return season
        }
        
        return "\(season_split[0])-\(season_split[1].dropFirst(2))"
    }
    
    var body: some View {
        VStack {
            Form {
                Section("Data Analysis") {
                    Toggle("AdamScore™", isOn: $adam_score).onChange(of: adam_score) { _ in
                        settings.setAdamScore(state: adam_score)
                        settings.updateUserDefaults()
                    }
                }
                Section("Season") {
                    HStack {
                        Spacer()
                        if showLoading {
                            ProgressView()
                        }
                        else {
                            Picker("Season", selection: $selected_season_id) {
                                ForEach(API.season_id_map.keys.sorted().reversed(), id: \.self) { season_id in
                                    Text(format_season_option(raw: API.season_id_map[season_id] ?? "Unknown")).tag(season_id)
                                }
                            }.labelsHidden()
                                .onChange(of: selected_season_id) { _ in
                                    settings.setSelectedSeasonID(id: selected_season_id)
                                    settings.updateUserDefaults()
                                    self.showLoading = true
                                    DispatchQueue.global(qos: .userInteractive).async {
                                        API.update_world_skills_cache()
                                        DispatchQueue.main.async {
                                            self.showLoading = false
                                        }
                                    }
                                }
                        }
                        Spacer()
                    }
                }
                Section("Appearance") {
                    NavigationLink(destination: ChangeAppIcon().environmentObject(settings)) {
                        Text("Change App Icon")
                    }
                    ColorPicker("Color", selection: $selected_color, supportsOpacity: false).onChange(of: selected_color) { _ in
                        settings.setColor(color: selected_color)
                        adam_score = UserSettings().getAdamScore()
                        showApply = true
                    }
                    Toggle("Minimalistic", isOn: $minimalistic).onChange(of: minimalistic) { _ in
                        settings.setMinimalistic(state: minimalistic)
                        adam_score = UserSettings().getAdamScore()
                        showApply = true
                    }
                    if showApply {
                    Button("Restart to apply") {
                        settings.updateUserDefaults()
                        print("App Restarting")
                        exit(0)
                    }
                    }
                }
                Section("Danger") {
                    Button("Clear favorite teams") {
                        defaults.set([String](), forKey: "favorite_teams")
                        favorites.favorite_teams = [String]()
                        clearedTeams = true
                        print("Favorite teams cleared")
                    }.alert(isPresented: $clearedTeams) {
                        Alert(title: Text("Cleared favorite teams"), dismissButton: .default(Text("OK")))
                    }
                    Button("Clear favorite events") {
                        defaults.set([String](), forKey: "favorite_events")
                        favorites.favorite_events = [String]()
                        clearedEvents = true
                        print("Favorite events cleared")
                    }.alert(isPresented: $clearedEvents) {
                        Alert(title: Text("Cleared favorite events"), dismissButton: .default(Text("OK")))
                    }
                    Button("Erase all match notes") {
                        dataController.deleteAllNotes()
                        clearedNotes = true
                    }.alert(isPresented: $clearedNotes) {
                        Alert(title: Text("Cleared match notes"), dismissButton: .default(Text("OK")))
                    }
                    Button("Reset all data") {
                        let domain = Bundle.main.bundleIdentifier!
                        UserDefaults.standard.removePersistentDomain(forName: domain)
                        UserDefaults.standard.synchronize()
                        print("UserDefaults cleared")
                        exit(0)
                    }
                }
                Section("Developer") {
                    HStack {
                        Text("RobotEvents API Key")
                        Spacer()
                        SecureField("Enter Key", text: $apiKey, onCommit: {
                            defaults.set(apiKey, forKey: "robotevents_api_key")
                            print("Set RobotEvents API Key")
                        })
                    }
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(UIApplication.appVersion!)
                    }
                }
                Section("Developed by Teams Ace 229V and Jelly 2733J") {}
            }
            Link("Join the Discord Server", destination: URL(string: "https://discord.gg/7b9qcMhVnW")!).padding()
        }.onAppear{
            navigation_bar_manager.title = "Settings"
        }
    }
}

struct Settings_Previews: PreviewProvider {
    static var previews: some View {
        Settings()
    }
}
