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
    @State var minimalistic = UserSettings.getMinimalistic()
    @State var adam_score = UserSettings.getAdamScore()
    @State var performance_ratings_calculation_option = UserSettings.getPerformanceRatingsCalculationOption() == "via"
    @State var grade_level = UserSettings.getGradeLevel()
    @State var selected_season_id = UserSettings.getSelectedSeasonID()
    @State var apiKey = UserSettings.getRobotEventsAPIKey() ?? ""
    @State var team_info_default_page = UserSettings.getTeamInfoDefaultPage() == "statistics"
    @State var match_team_default_page = UserSettings.getMatchTeamDefaultPage() == "statistics"
    @State var showLoading = false
    @State var showApply = false
    @State var clearedTeams = false
    @State var clearedEvents = false
    @State var clearedNotes = false
    @State var confirmClearTeams = false
    @State var confirmClearEvents = false
    @State var confirmClearData = false
    @State var confirmClearNotes = false
    @State var confirmAppearance = false
    @State var confirmAPIKey = false
    
    var mode: String {
        #if DEBUG
        return " DEBUG"
        #else
        return ""
        #endif
    }
    
    func format_season_option(raw: String) -> String {
        var season = raw
        season = season.replacingOccurrences(of: "VRC ", with: "").replacingOccurrences(of: "VEXU ", with: "")
        
        let season_split = season.split(separator: "-")
        
        if season_split.count == 1 {
            return season
        }
        
        return "\(season_split[0])-\(season_split[1].dropFirst(2))"
    }
    
    var body: some View {
        VStack {
            List {
            Link(destination: URL(string: "https://www.paypal.com/donate/?business=FGDW39F77H6PW&no_recurring=0&item_name=Donations+allow+me+to+bring+new+features+and+functionality+to+VRC+RoboScout.+Thank+you+for+your+support%21&currency_code=USD")!, label: {
                    HStack {
                        Image(systemName: "gift")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                            .cornerRadius(8)
                        VStack(alignment: .center) {
                            Text("Donate to VRC RoboScout").bold()
                            Text("Donations support development. Thank you <3").font(.system(size: 15)).foregroundColor(.secondary).multilineTextAlignment(.center)
                        }.padding(EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 10))
                        Spacer()
                    }.padding()
                }).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .background(settings.accentColor().opacity(0.3))
                    .cornerRadius(20)
                Section("Competition") {
                    Picker("Competition", selection: $grade_level) {
                        Text("VRC MS").tag("Middle School")
                        Text("VRC HS").tag("High School")
                        Text("VEXU").tag("College")
                    }.pickerStyle(.segmented).padding([.top, .bottom], 5)
                        .onChange(of: grade_level) { grade in
                            settings.setGradeLevel(grade_level: grade)
                            settings.updateUserDefaults()
                            self.showLoading = true
                            DispatchQueue.global(qos: .userInteractive).async {
                                API.generate_season_id_map()
                                settings.setSelectedSeasonID(id: API.season_id_map[UserSettings.getGradeLevel() != "College" ? 0 : 1].keys.sorted().reversed()[0])
                                settings.updateUserDefaults()
                                API.update_world_skills_cache()
                                API.update_vrc_data_analysis_cache()
                                DispatchQueue.main.async {
                                    self.selected_season_id = UserSettings.getSelectedSeasonID()
                                    self.showLoading = false
                                }
                            }
                            
                        }
                    HStack {
                        Spacer()
                        if showLoading || API.season_id_map.isEmpty {
                            ProgressView()
                        }
                        else {
                            Picker("Season", selection: $selected_season_id) {
                                ForEach(API.season_id_map[UserSettings.getGradeLevel() != "College" ? 0 : 1].keys.sorted().reversed(), id: \.self) { season_id in
                                    Text(format_season_option(raw: API.season_id_map[UserSettings.getGradeLevel() != "College" ? 0 : 1][season_id] ?? "Unknown")).tag(season_id)
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
                Section("Data Analysis") {
                    Toggle("AdamScore™", isOn: $adam_score).onChange(of: adam_score) { _ in
                        settings.setAdamScore(state: adam_score)
                        settings.updateUserDefaults()
                    }
                    /*Toggle("VEX via OPR, DPR, CCWM", isOn: $performance_ratings_calculation_option).onChange(of: performance_ratings_calculation_option) { _ in
                        settings.setPerformanceRatingsCalculationOption(option: performance_ratings_calculation_option ? "via" : "real")
                        settings.updateUserDefaults()
                    }*/
                }
                Section("Appearance") {
                    NavigationLink(destination: ChangeAppIcon().environmentObject(settings)) {
                        Text("Change App Icon")
                    }
                    ColorPicker("Color", selection: $selected_color, supportsOpacity: false).onChange(of: selected_color) { _ in
                        settings.setColor(color: selected_color)
                        showApply = true
                    }
                    Toggle("Minimalistic", isOn: $minimalistic).onChange(of: minimalistic) { _ in
                        settings.setMinimalistic(state: minimalistic)
                        showApply = true
                    }
                    if showApply {
                        Button("Apply changes") {
                            confirmAppearance = true
                        }.confirmationDialog("Are you sure?", isPresented: $confirmAppearance) {
                            Button("Apply and close app?", role: .destructive) {
                                settings.updateUserDefaults()
                                print("App Closing")
                                exit(0)
                            }
                        }
                    }
                }
                Section("Customization") {
                    Toggle("Show statistics by default on Team Info page", isOn: $team_info_default_page).onChange(of: team_info_default_page) { _ in
                        settings.setTeamInfoDefaultPage(page: team_info_default_page ? "statistics" : "events")
                        settings.updateUserDefaults()
                    }
                    Toggle("Show statistics by default on Match Team page", isOn: $match_team_default_page).onChange(of: match_team_default_page) { _ in
                        settings.setMatchTeamDefaultPage(page: match_team_default_page ? "statistics" : "matches")
                        settings.updateUserDefaults()
                    }
                }
                Section("Danger") {
                    Button("Clear favorite teams") {
                        confirmClearTeams = true
                    }.alert(isPresented: $clearedTeams) {
                        Alert(title: Text("Cleared favorite teams"), dismissButton: .default(Text("OK")))
                    }.confirmationDialog("Are you sure?", isPresented: $confirmClearTeams) {
                        Button("Clear ALL favorited teams?", role: .destructive) {
                            defaults.set([String](), forKey: "favorite_teams")
                            favorites.favorite_teams = [String]()
                            clearedTeams = true
                            print("Favorite teams cleared")
                        }
                    }
                    Button("Clear favorite events") {
                        confirmClearEvents = true
                    }.alert(isPresented: $clearedEvents) {
                        Alert(title: Text("Cleared favorite events"), dismissButton: .default(Text("OK")))
                    }.confirmationDialog("Are you sure?", isPresented: $confirmClearEvents) {
                        Button("Clear ALL favorited events?", role: .destructive) {
                            defaults.set([String](), forKey: "favorite_events")
                            favorites.favorite_events = [String]()
                            clearedEvents = true
                            print("Favorite events cleared")
                        }
                    }
                    Button("Clear all match notes") {
                        confirmClearNotes = true
                    }.alert(isPresented: $clearedNotes) {
                        Alert(title: Text("Cleared match notes"), dismissButton: .default(Text("OK")))
                    }.confirmationDialog("Are you sure?", isPresented: $confirmClearNotes) {
                        Button("Clear ALL match notes?", role: .destructive) {
                            dataController.deleteAllNotes()
                            clearedNotes = true
                        }
                    }
                }
                Section("Developer") {
                    HStack {
                        Text("RobotEvents API Key")
                        Spacer()
                        SecureField("Enter Key", text: $apiKey, onCommit: {
                            confirmAPIKey = true
                        }).confirmationDialog("Are you sure?", isPresented: $confirmAPIKey) {
                            Button("Set API Key and close app?", role: .destructive) {
                                defaults.set(apiKey, forKey: "robotevents_api_key")
                                print("Set RobotEvents API Key")
                                exit(0)
                            }
                        }
                    }
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("\(UIApplication.appVersion!) (\(UIApplication.appBuildNumber!))\(self.mode)")
                    }
                }
                Section("Developed by Teams Ace 229V and Jelly 2733J") {}
            }
            Link("Join the Discord Server", destination: URL(string: "https://discord.gg/KczJZUfs5f")!).padding()
        }.onAppear{
            navigation_bar_manager.title = "Settings"
            settings.readUserDefaults()
        }
    }
}

struct Settings_Previews: PreviewProvider {
    static var previews: some View {
        Settings()
    }
}
