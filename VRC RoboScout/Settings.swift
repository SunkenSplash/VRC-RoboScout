//
//  Settings.swift
//  VRC RoboScout
//
//  Created by William Castro on 3/3/23.
//

import SwiftUI

struct Settings: View {
    
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var favorites: FavoriteStorage
    @EnvironmentObject var navigation_bar_manager: NavigationBarManager
    
    @State var selected_color = UserSettings().accentColor()
    @State var minimalistic = UserSettings().getMinimalistic()
    @State var adam_score = UserSettings().getAdamScore()
    @State var selected_season_id = UserSettings().getSelectedSeasonID()
    @State var showLoading = false
    @State var showApply = false
    
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
                        print("Favorite teams cleared")
                    }
                    Button("Clear favorite events") {
                        defaults.set([String](), forKey: "favorite_events")
                        favorites.favorite_events = [String]()
                        print("Favorite events cleared")
                    }
                    Button("Reset all data") {
                        let domain = Bundle.main.bundleIdentifier!
                        UserDefaults.standard.removePersistentDomain(forName: domain)
                        UserDefaults.standard.synchronize()
                        print("UserDefaults cleared")
                        exit(0)
                    }
                }
                Section("Developed by Teams Ace 229V and Jelly 2733J") {}
            }.onAppear{
                navigation_bar_manager.title = "Settings"
            }
        }
    }
}

struct Settings_Previews: PreviewProvider {
    static var previews: some View {
        Settings()
    }
}
