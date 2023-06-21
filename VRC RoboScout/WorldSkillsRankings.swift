//
//  WorldSkillsRankings.swift
//  VRC RoboScout
//
//  Created by William Castro on 2/23/23.
//

import SwiftUI

struct WorldSkillsTeam: Identifiable {
    let id = UUID()
    let number: String
    let ranking: Int
    let additional_ranking: Int
    let driver: Int
    let programming: Int
    let highest_driver: Int
    let highest_programming: Int
    let combined: Int
}

struct WorldSkillsRow: View {
    var team_world_skills: WorldSkillsTeam

    var body: some View {
        HStack {
            HStack {
                Text(team_world_skills.additional_ranking == 0 ? "#\(team_world_skills.ranking)" : "#\(team_world_skills.ranking) (#\(team_world_skills.additional_ranking))")
                Spacer()
            }.frame(width: 80)
            Spacer()
            Text("\(team_world_skills.number)")
            Spacer()
            HStack {
                Menu("\(team_world_skills.combined)") {
                    Text("\(team_world_skills.combined) Combined")
                    Text("\(team_world_skills.programming) Programming")
                    Text("\(team_world_skills.driver) Driver")
                    Text("\(team_world_skills.highest_programming) Highest Programming")
                    Text("\(team_world_skills.highest_driver) Highest Driver")
                }
                HStack {
                    Spacer()
                    VStack {
                        Text(String(describing: team_world_skills.programming)).font(.system(size: 10))
                        Text(String(describing: team_world_skills.driver)).font(.system(size: 10))
                    }
                }.frame(width: 30)
            }.frame(width: 80)
        }
    }
}

class WorldSkillsTeams: ObservableObject {
    
    var world_skills_teams: [WorldSkillsTeam]
    
    init(begin: Int, end: Int, region: Int = 0, letter: Character = "0", filter_array: [String] = [], fetch: Bool = false) {
        if fetch && API.world_skills_cache.count == 0 {
            API.update_world_skills_cache()
        }
        var end = end
        self.world_skills_teams = [WorldSkillsTeam]()
        if end == 0 {
            end = API.world_skills_cache.count
        }
        // Favorites
        if filter_array.count != 0 {
            var rank = 1
            for team in API.world_skills_cache {
                if !filter_array.contains((team["team"] as! [String: Any])["team"] as! String) {
                    continue
                }
                self.world_skills_teams.append(WorldSkillsTeam(number: (team["team"] as! [String: Any])["team"] as! String, ranking: rank, additional_ranking: team["rank"] as! Int, driver: (team["scores"] as! [String: Any])["driver"] as! Int, programming: (team["scores"] as! [String: Any])["programming"] as! Int, highest_driver: (team["scores"] as! [String: Any])["highest_driver"] as! Int, highest_programming: (team["scores"] as! [String: Any])["highest_programming"] as! Int, combined: (team["scores"] as! [String: Any])["score"] as! Int))
                rank += 1
            }
        }
        // Region
        else if region != 0 {
            var rank = 1
            for team in API.world_skills_cache {
                if region != (team["team"] as! [String: Any])["eventRegionId"] as! Int {
                    continue
                }
                self.world_skills_teams.append(WorldSkillsTeam(number: (team["team"] as! [String: Any])["team"] as! String, ranking: rank, additional_ranking: team["rank"] as! Int, driver: (team["scores"] as! [String: Any])["driver"] as! Int, programming: (team["scores"] as! [String: Any])["programming"] as! Int, highest_driver: (team["scores"] as! [String: Any])["highest_driver"] as! Int, highest_programming: (team["scores"] as! [String: Any])["highest_programming"] as! Int, combined: (team["scores"] as! [String: Any])["score"] as! Int))
                rank += 1
            }
        }
        // Letter
        else if letter != "0" {
            var rank = 1
            for team in API.world_skills_cache {
                if letter != ((team["team"] as! [String: Any])["team"] as! String).last {
                    continue
                }
                self.world_skills_teams.append(WorldSkillsTeam(number: (team["team"] as! [String: Any])["team"] as! String, ranking: rank, additional_ranking: team["rank"] as! Int, driver: (team["scores"] as! [String: Any])["driver"] as! Int, programming: (team["scores"] as! [String: Any])["programming"] as! Int, highest_driver: (team["scores"] as! [String: Any])["highest_driver"] as! Int, highest_programming: (team["scores"] as! [String: Any])["highest_programming"] as! Int, combined: (team["scores"] as! [String: Any])["score"] as! Int))
                rank += 1
            }
        }
        // World
        else {
            for i in begin - 1...end - 1 {
                if API.world_skills_cache.count == 0 {
                    return
                }
                let team = API.world_skills_cache[i]
                self.world_skills_teams.append(WorldSkillsTeam(number: (team["team"] as! [String: Any])["team"] as! String, ranking: team["rank"] as! Int, additional_ranking: 0, driver: (team["scores"] as! [String: Any])["driver"] as! Int, programming: (team["scores"] as! [String: Any])["programming"] as! Int, highest_driver: (team["scores"] as! [String: Any])["maxDriver"] as! Int, highest_programming: (team["scores"] as! [String: Any])["maxProgramming"] as! Int, combined: (team["scores"] as! [String: Any])["score"] as! Int))
            }
        }
    }
}

var region_id_map: [String: Int] = [
    "South Dakota": 2491,
    "Pennsylvania - East": 2488,
    "Virginia": 2495,
    "Kansas": 2466,
    "New York - South": 3579,
    "Hawaii": 2462,
    "District of Columbia": 2459,
    "China": 2500,
    "Michigan": 2472,
    "Taiwan": 2528,
    "Alabama": 2452,
    "California - Region 4": 2910,
    "Tennessee": 2492,
    "Texas - Region 3": 2680,
    "Washington": 2496,
    "Kentucky": 2467,
    "Georgia": 2461,
    "Arizona": 2454,
    "Texas - Region 2": 2679,
    "Louisiana": 2468,
    "Colorado": 2457,
    "California - Region 2": 3660,
    "Minnesota": 2473,
    "Southern New England": 2471,
    "Maryland": 2470,
    "Australia": 2507,
    "South Carolina": 2490,
    "Ontario": 2504,
    "Wisconsin": 2498,
    "Mississippi": 2474,
    "Japan": 2519,
    "Ohio": 2485,
    "Florida - North/Central": 2460,
    "Oregon": 2487,
    "Quebec": 3014,
    "Texas - Region 4": 2681,
    "North Carolina": 2483,
    "New Jersey": 2480,
    "Montana": 2476,
    "Nebraska": 2477,
    "Utah": 2494,
    "Alberta/Saskatchewan": 2506,
    "British Columbia (BC)": 2505,
    "Indiana": 2465,
    "Florida - South": 2677,
    "Singapore": 2525
]

struct WorldSkillsRankings: View {
    
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var favorites: FavoriteStorage
    @EnvironmentObject var navigation_bar_manager: NavigationBarManager
    
    @State private var display_skills = "World Skills"
    @State private var start = 1
    @State private var end = 200
    @State private var region_id = 0
    @State private var letter: Character = "0"
    @State private var current_index = 100
    @State private var world_skills_rankings = WorldSkillsTeams(begin: 1, end: 200, fetch: false)
    @State private var season_id = RoboScoutAPI.selected_season_id()
    
    var body: some View {
        VStack {
            if API.world_skills_cache.isEmpty {
                NoData()
            }
            else {
                Menu("Filter") {
                    Button("Favorites") {
                        display_skills = "Favorites Skills"
                        start = 1
                        end = 200
                        region_id = 0
                        letter = "0"
                        current_index = 100
                        world_skills_rankings = WorldSkillsTeams(begin: 1, end: API.world_skills_cache.count, filter_array: favorites.teams_as_array(), fetch: false)
                    }
                    Menu("Region") {
                        Button("World") {
                            display_skills = "World Skills"
                            start = 1
                            end = 200
                            region_id = 0
                            letter = "0"
                            current_index = 100
                            world_skills_rankings = WorldSkillsTeams(begin: 1, end: 200, fetch: false)
                        }
                        ForEach(region_id_map.sorted(by: <), id: \.key) { region, id in
                            Button(region) {
                                display_skills = "\(region) Skills"
                                start = 1
                                end = 200
                                region_id = id
                                letter = "0"
                                current_index = 100
                                world_skills_rankings = WorldSkillsTeams(begin: 1, end: API.world_skills_cache.count, region: id, fetch: false)
                            }
                        }
                    }
                    Menu("Letter") {
                        ForEach(["A", "B", "C", "D", "E", "F", "G", "H", "J", "K", "L", "M", "N", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"], id: \.self) { char in
                            Button(char) {
                                display_skills = "\(char) Skills"
                                start = 1
                                end = 200
                                letter = char.first!
                                current_index = 100
                                world_skills_rankings = WorldSkillsTeams(begin: 1, end: API.world_skills_cache.count, letter: char.first!, fetch: false)
                            }
                        }
                    }
                    Button("Clear Filters") {
                        display_skills = "World Skills"
                        start = 1
                        end = 200
                        region_id = 0
                        letter = "0"
                        current_index = 100
                        world_skills_rankings = WorldSkillsTeams(begin: 1, end: 200, fetch: false)
                    }
                }.fontWeight(.medium)
                    .font(.system(size: 19))
                    .padding(20)
                    .onAppear{
                        if RoboScoutAPI.selected_season_id() != self.season_id {
                            display_skills = "World Skills"
                            start = 1
                            end = 200
                            region_id = 0
                            letter = "0"
                            current_index = 100
                            world_skills_rankings = WorldSkillsTeams(begin: 1, end: 200, fetch: false)
                            self.season_id = RoboScoutAPI.selected_season_id()
                        }
                    }
                ScrollViewReader { proxy in
                    List($world_skills_rankings.world_skills_teams) { team in
                        WorldSkillsRow(team_world_skills: team.wrappedValue).id(team.wrappedValue.ranking).onAppear{
                            if region_id != 0 || letter != "0" {
                                return
                            }
                            let cache_size = API.world_skills_cache.count
                            if cache_size == 0 {
                                return
                            }
                            if team.wrappedValue.ranking == current_index + 100 {
                                current_index += 50
                                start = start + 50 > cache_size ? cache_size - 50 : start + 50
                                end = end + 50 > cache_size ? cache_size : end + 50
                                Task {
                                    world_skills_rankings = WorldSkillsTeams(begin: start, end: end)
                                    proxy.scrollTo(current_index - 25)
                                }
                            }
                            else if team.wrappedValue.ranking == current_index - 100 + 1 && team.wrappedValue.ranking != 1 {
                                current_index -= 50
                                start = start - 50 < 1 ? 1 : start - 50
                                end = end - 50 < 1 ? 1 + 50 : end - 50
                                Task {
                                    world_skills_rankings = WorldSkillsTeams(begin: start, end: end)
                                    proxy.scrollTo(current_index + 25)
                                }
                            }
                        }
                    }
                }
            }
        }.background(.clear)
            .onAppear{
                navigation_bar_manager.title = $display_skills.wrappedValue
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(settings.tabColor(), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
    }
}


struct WorldSkillsRankings_Previews: PreviewProvider {
    static var previews: some View {
        WorldSkillsRankings()
    }
}
