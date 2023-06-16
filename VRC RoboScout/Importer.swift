//
//  Importer.swift
//  VRC RoboScout
//
//  Created by William Castro on 3/26/23.
//

import SwiftUI

class NavigationBarManager: ObservableObject {
    @Published var title: String
    init(title: String) {
        self.title = title
    }
}

struct Importer: View {
    
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var favorites: FavoriteStorage
    
    @StateObject var navigation_bar_manager = NavigationBarManager(title: "Favorites")
    
    @State private var enter = false
    @State private var trueskill_progress = 0.0
    @State private var trueskill_fetch_error = false
    @State private var world_skills_done = false
    @State private var seasons_done = false
    @State private var cont = false
    @State private var total_teams = 0
    
    func import_seasons_and_skills() {
        DispatchQueue.global(qos: .userInteractive).async {
            API.generate_season_id_map()
            DispatchQueue.main.async {
                seasons_done = true
            }
            API.update_world_skills_cache()
            DispatchQueue.main.async {
                world_skills_done = true
            }
        }
    }
    
    func import_trueskill() {
        DispatchQueue.global(qos: .userInteractive).async { [self] in
            
            let components = URLComponents(string: "http://vrc-data-analysis.com/v1/allteams")!
            
            let request = NSMutableURLRequest(url: components.url! as URL)
            request.httpMethod = "GET"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let json = API.fetch_raw_vrc_data_analysis()
            
            if json.count == 0 {
                print("Failed to update VRC Data Analysis cache")
                DispatchQueue.main.async {
                    trueskill_progress = 0.0
                    trueskill_fetch_error = true
                }
                return
            }
            
            API.vrc_data_analysis_cache = [[String: Any]]()
            
            var abs_ranking = 0
            var prev_count = 0
            for team in json {
                
                if team["ts_ranking"] as? Int ?? 0 == 99999 {
                    break
                }
                
                let team = team as [String: Any]
                
                var team_data_dict = [String: Any]()
                
                team_data_dict = [
                    "abs_ranking": abs_ranking,
                    "trueskill_ranking": team["ts_ranking"] as? Int ?? 0,
                    "trueskill_ranking_change": team["ranking_change"] as? Int ?? 0,
                    "name": team["team_name"] as? String ?? "",
                    "id": Int(team["id"] as? Double ?? 0.0),
                    "number": team["team_number"] as? String ?? "",
                    "grade": team["grade"] as? String ?? "",
                    "region": team["event_region"] as? String ?? "",
                    "country": team["loc_country"] as? String ?? "",
                    "trueskill": team["trueskill"] as? Double ?? 0.0,
                    "ccwm": team["ccwm"] as? Double ?? 0.0,
                    "opr": team["opr"] as? Double ?? 0.0,
                    "dpr": team["dpr"] as? Double ?? 0.0,
                    "ap_per_match": team["ap_per_match"] as? Double ?? 0.0,
                    "awp_per_match": team["awp_per_match"] as? Double ?? 0.0,
                    "wp_per_match": team["wp_per_match"] as? Double ?? 0.0,
                    "total_wins": Int(team["total_wins"] as? Double ?? 0.0),
                    "total_losses": Int(team["total_losses"] as? Double ?? 0.0),
                    "total_ties": Int(team["total_ties"] as? Double ?? 0.0),
                    "elimination_wins": Int(team["elimination_wins"] as? Double ?? 0.0),
                    "elimination_losses": Int(team["elimination_losses"] as? Double ?? 0.0),
                    "elimination_ties": Int(team["elimination_ties"] as? Double ?? 0.0),
                    "qualifier_wins": Int(team["qual_wins"] as? Double ?? 0.0),
                    "qualifier_losses": Int(team["qual_losses"] as? Double ?? 0.0),
                    "qualifier_ties": Int(team["qual_ties"] as? Double ?? 0.0),
                    "regionals_qualified": team["qualified_for_regionals"] as? Int == 1,
                    "worlds_qualified": team["qualified_for_worlds"] as? Int == 1
                ]
                
                API.vrc_data_analysis_cache.append(team_data_dict)
                
                API.vrc_data_analysis_cache.sort(by: {
                    ($0["abs_ranking"] as! Int) < ($1["abs_ranking"] as! Int)
                })
                
                if API.vrc_data_analysis_cache.count > prev_count {
                    abs_ranking += 1
                }
                prev_count = API.vrc_data_analysis_cache.count
                
                DispatchQueue.main.async {
                    trueskill_progress = Double(prev_count) / Double(json.count)
                    total_teams = json.count
                }
                
            }
            print("Updated VRC Data Analysis cache")
            
            DispatchQueue.main.async {
                trueskill_progress = 1.0
            }
        }
    }
        
    var body: some View {
        NavigationStack {
            if trueskill_progress != 1.0 && !cont {
                VStack {
                    Spacer()
                    HStack {
                        Text("Season Information").font(.system(size: 18, design: .monospaced)).padding()
                        Spacer()
                        if !seasons_done {
                            ProgressView().padding().font(.system(size: 18))
                        }
                        else {
                            Image(systemName: "checkmark.circle.fill").padding().font(.system(size: 18))
                        }
                    }.padding()
                    HStack {
                        Text("World Skills").font(.system(size: 18, design: .monospaced)).padding()
                        Spacer()
                        if !world_skills_done {
                            ProgressView().padding().font(.system(size: 18))
                        }
                        else {
                            Image(systemName: "checkmark.circle.fill").padding().font(.system(size: 18))
                        }
                    }.padding()
                    VStack {
                        Text("TrueSkill").font(.system(size: 18, design: .monospaced)).frame(maxWidth: .infinity, alignment: .leading).padding()
                        ProgressView(value: trueskill_progress) {
                            Text(!trueskill_fetch_error ? (trueskill_progress != 0 ? "Processed \(API.vrc_data_analysis_cache.count) out of \(Int(total_teams)) teams" : "Accessing vrc-data-analysis.com...") : "Error fetching TrueSkill data").font(.system(size: 12, design: .monospaced))
                        }.padding(.leading).padding(.trailing)
                    }.padding()
                    Spacer()
                    VStack {
                        if (trueskill_progress > 0 || trueskill_fetch_error) && (seasons_done && world_skills_done) {
                            Button("Continue") {
                                cont = true
                            }
                        }
                    }.frame(height: 20)
                    Spacer()
                }.task {
                    import_seasons_and_skills()
                    import_trueskill()
                }.background(.clear)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text("Importing Data")
                                .fontWeight(.medium)
                                .font(.system(size: 19))
                                .foregroundColor(settings.navTextColor())
                        }
                    }
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbarBackground(settings.tabColor(), for: .navigationBar)
                    .toolbarBackground(.visible, for: .navigationBar)
            }
            else {
                TabView {
                    Favorites()
                        .tabItem {
                            if settings.getMinimalistic() {
                                Image(systemName: "star")
                            }
                            else {
                                Label("Favorites", systemImage: "star")
                            }
                        }
                        .environmentObject(favorites)
                        .environmentObject(settings)
                        .environmentObject(navigation_bar_manager)
                        .tint(settings.accentColor())
                    WorldSkillsRankings()
                        .tabItem {
                            if settings.getMinimalistic() {
                                Image(systemName: "globe")
                            }
                            else {
                                Label("World Skills", systemImage: "globe")
                            }
                        }
                        .environmentObject(favorites)
                        .environmentObject(settings)
                        .environmentObject(navigation_bar_manager)
                        .tint(settings.accentColor())
                    TrueSkill()
                        .tabItem {
                            if settings.getMinimalistic() {
                                Image(systemName: "trophy")
                            }
                            else {
                                Label("TrueSkill", systemImage: "trophy")
                            }
                        }
                        .environmentObject(favorites)
                        .environmentObject(settings)
                        .environmentObject(navigation_bar_manager)
                        .tint(settings.accentColor())
                    Lookup()
                        .tabItem {
                            if settings.getMinimalistic() {
                                Image(systemName: "magnifyingglass")
                            }
                            else {
                                Label("Lookup", systemImage: "magnifyingglass")
                            }
                        }
                        .environmentObject(favorites)
                        .environmentObject(settings)
                        .environmentObject(navigation_bar_manager)
                        .tint(settings.accentColor())
                    Settings()
                        .tabItem {
                            if settings.getMinimalistic() {
                                Image(systemName: "gear")
                            }
                            else {
                                Label("Settings", systemImage: "gear")
                            }
                        }
                        .environmentObject(favorites)
                        .environmentObject(settings)
                        .environmentObject(navigation_bar_manager)
                        .tint(settings.accentColor())
                }.onAppear {
                    let tabBarAppearance = UITabBarAppearance()
                    tabBarAppearance.configureWithDefaultBackground()
                    UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
                }.tint(settings.accentColor())
                    .background(.clear)
                            .toolbar {
                                ToolbarItem(placement: .principal) {
                                    Text(navigation_bar_manager.title)
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
    }
}

struct Importer_Previews: PreviewProvider {
    static var previews: some View {
        Importer()
    }
}
