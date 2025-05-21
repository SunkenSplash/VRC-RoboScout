//
//  SettingsView.swift
//  VRC RoboScout
//
//  Created by William Castro on 5/21/25.
//

import SwiftUI
import CoreData

struct SettingsView: View {
    
    @EnvironmentObject var settings: UserSettings
    
    @State var adam_score = UserSettings.getAdamScore()
    @State var performance_ratings_calculation_option = UserSettings.getPerformanceRatingsCalculationOption() == "via"
    @State var grade_level = UserSettings.getGradeLevel()
    @State var selected_season_id = UserSettings.getSelectedSeasonID()
    @State var apiKey = UserSettings.getRobotEventsAPIKey() ?? ""
    @State var team_info_default_page = UserSettings.getTeamInfoDefaultPage() == "statistics"
    @State var match_team_default_page = UserSettings.getMatchTeamDefaultPage() == "statistics"
    @State var showLoading = false
    @State var showAPIKeyInput = false
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
        season = season.replacingOccurrences(of: "VRC ", with: "").replacingOccurrences(of: "V5RC ", with: "").replacingOccurrences(of: "VEX V5 ", with: "").replacingOccurrences(of: "VEXU ", with: "").replacingOccurrences(of: "VURC ", with: "").replacingOccurrences(of: "VEX U ", with: "").replacingOccurrences(of: "Robotics Competition ", with: "")
        
        let season_split = season.split(separator: "-")
        
        if season_split.count == 1 {
            return season
        }
        
        return "\(season_split[0][season_split[0].index(season_split[0].startIndex, offsetBy: 2)..<season_split[0].endIndex])-\(season_split[1].dropFirst(2))"
    }
    
    var body: some View {
        VStack {
            List {
                Section("Competition") {
                    Picker("Grade Level", selection: $grade_level) {
                        Text("V5RC MS").tag("Middle School")
                        Text("V5RC HS").tag("High School")
                        Text("VURC").tag("College")
                    }.pickerStyle(.navigationLink).onChange(of: grade_level) { _, grade in
                        settings.setGradeLevel(grade_level: grade)
                        settings.updateUserDefaults(updateTopBarContentColor: false)
                        self.showLoading = true
                        DispatchQueue.global(qos: .userInteractive).async {
                            API.generate_season_id_map()
                            settings.setSelectedSeasonID(id: API.season_id_map[UserSettings.getGradeLevel() != "College" ? 0 : 1].keys.sorted().reversed()[0])
                            settings.updateUserDefaults(updateTopBarContentColor: false)
                            API.update_world_skills_cache()
                            API.update_vrc_data_analysis_cache()
                            DispatchQueue.main.async {
                                self.selected_season_id = UserSettings.getSelectedSeasonID()
                                self.showLoading = false
                            }
                        }
                    }
                    HStack {
                        if showLoading || API.season_id_map.isEmpty {
                            ProgressView().frame(maxWidth: .infinity, alignment: .center)
                        }
                        else {
                            Picker("Season", selection: $selected_season_id) {
                                ForEach(API.season_id_map[UserSettings.getGradeLevel() != "College" ? 0 : 1].keys.sorted().reversed(), id: \.self) { season_id in
                                    Text(format_season_option(raw: API.season_id_map[UserSettings.getGradeLevel() != "College" ? 0 : 1][season_id] ?? "Unknown")).tag(season_id)
                                }
                            }.pickerStyle(.navigationLink).onChange(of: selected_season_id) { _, _ in
                                settings.setSelectedSeasonID(id: selected_season_id)
                                settings.updateUserDefaults(updateTopBarContentColor: false)
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) { // This has to be done because the `navigationLink` picker crashes if you scroll to select an option and then immediately change the state of the previous view
                                    self.showLoading = true
                                    DispatchQueue.global(qos: .userInteractive).async {
                                        API.update_world_skills_cache()
                                        DispatchQueue.main.async {
                                            self.showLoading = false
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                Section("Data Analysis") {
                    Toggle("AdamScore™", isOn: $adam_score).onChange(of: adam_score) { _, _ in
                        settings.setAdamScore(state: adam_score)
                        settings.updateUserDefaults(updateTopBarContentColor: false)
                    }
                    /*Toggle("VEX via OPR, DPR, CCWM", isOn: $performance_ratings_calculation_option).onChange(of: performance_ratings_calculation_option) { _ in
                     settings.setPerformanceRatingsCalculationOption(option: performance_ratings_calculation_option ? "via" : "real")
                     settings.updateUserDefaults()
                     }*/
                }
                Section("Customization") {
                    Toggle("Show statistics by default from favorites", isOn: $team_info_default_page).onChange(of: team_info_default_page) { _, _ in
                        settings.setTeamInfoDefaultPage(page: team_info_default_page ? "statistics" : "events")
                        settings.updateUserDefaults(updateTopBarContentColor: false)
                    }
                    Toggle("Show statistics by default in event team lists", isOn: $match_team_default_page).onChange(of: match_team_default_page) { _, _ in
                        settings.setMatchTeamDefaultPage(page: match_team_default_page ? "statistics" : "matches")
                        settings.updateUserDefaults(updateTopBarContentColor: false)
                    }
                }
                Section("Developer") {
                    HStack {
                        Text("RobotEvents API Key").frame(maxWidth: .infinity, alignment: .leading).onTapGesture {
                            showAPIKeyInput = true
                        }.fullScreenCover(isPresented: $showAPIKeyInput) {
                            VStack {
                                Text("Enter Key:")
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
                        }
                    }
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String) (\(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String))\(self.mode)")
                    }
                }
                Section("Developed by Teams Ace 229V and Jelly 2733J") {}
            }
        }.onAppear{
            settings.readUserDefaults()
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
