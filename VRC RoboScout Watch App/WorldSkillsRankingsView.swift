//
//  WorldSkillsRankingsView.swift
//  VRC RoboScout Watch App
//
//  Created by William Castro on 7/27/24.
//

import SwiftUI

struct WorldSkillsTeam: Identifiable, Hashable {
    let id = UUID()
    let number: String
    let ranking: Int
    let additional_ranking: Int
    let driver: Int
    let programming: Int
    let highest_driver: Int
    let highest_programming: Int
    let combined: Int
    
    init(world_skills: WorldSkills, ranking: Int, additional_ranking: Int? = nil) {
        self.number = world_skills.team.number
        self.ranking = ranking
        self.additional_ranking = additional_ranking ?? 0
        self.driver = world_skills.driver
        self.programming = world_skills.programming
        self.highest_driver = world_skills.highest_driver
        self.highest_programming = world_skills.highest_programming
        self.combined = world_skills.combined
    }
}

struct WorldSkillsRow: View {
    
    var team_world_skills: WorldSkillsTeam

    var body: some View {
        HStack(alignment: .center) {
            VStack {
                Text("#\(team_world_skills.ranking)").frame(maxWidth: .infinity, alignment: .leading)
                if team_world_skills.additional_ranking != 0 {
                    Text("#\(team_world_skills.additional_ranking)").font(.system(size: 15)).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading)
                }
            }.frame(width: 50)
            Spacer()
            Text("\(team_world_skills.number)").font(.system(size: 15)).frame(width: 60, alignment: .center)
            Spacer()
            VStack {
                Text("\(team_world_skills.combined)")
                HStack {
                    Text(String(describing: team_world_skills.programming)).font(.system(size: 10))
                    Text(String(describing: team_world_skills.driver)).font(.system(size: 10))
                }
            }.frame(width: 50)
        }
    }
}

class WorldSkillsTeams: ObservableObject {
    
    var world_skills_teams: [WorldSkillsTeam]
    
    init(region: Int = 0, letter: Character = "0", filter_array: [String] = [], fetch: Bool = false) {
        if fetch && API.world_skills_cache.teams.count == 0 {
            API.update_world_skills_cache()
        }
        self.world_skills_teams = [WorldSkillsTeam]()
        // Favorites
        if filter_array.count != 0 {
            var rank = 1
            for team in API.world_skills_cache.teams {
                if !filter_array.contains(team.team.number) {
                    continue
                }
                self.world_skills_teams.append(WorldSkillsTeam(world_skills: team, ranking: rank, additional_ranking: team.ranking))
                rank += 1
            }
        }
        // Region
        else if region != 0 {
            var rank = 1
            for team in API.world_skills_cache.teams {
                if region != team.event_region_id {
                    continue
                }
                self.world_skills_teams.append(WorldSkillsTeam(world_skills: team, ranking: rank, additional_ranking: team.ranking))
                rank += 1
            }
        }
        // Letter
        else if letter != "0" {
            var rank = 1
            for team in API.world_skills_cache.teams {
                if letter != team.team.number.last {
                    continue
                }
                self.world_skills_teams.append(WorldSkillsTeam(world_skills: team, ranking: rank, additional_ranking: team.ranking))
                rank += 1
            }
        }
        // World
        else {
            if API.world_skills_cache.teams.count == 0 {
                return
            }
            for i in 0..<API.world_skills_cache.teams.count {
                let team = API.world_skills_cache.teams[i]
                self.world_skills_teams.append(WorldSkillsTeam(world_skills: team, ranking: team.ranking))
            }
        }
    }
}

struct WorldSkillsRankingsView: View {
    
    @EnvironmentObject var settings: UserSettings
    @Binding var title: String
    @Binding var showFilters: Bool
    @State private var expandedTeamWS = WorldSkillsTeam(world_skills: WorldSkills(), ranking: 0)
    @State private var showRegionFilters = false
    @State private var showLetterFilters = false
    @State private var region_id = 0
    @State private var letter: Character = "0"
    @State private var world_skills_rankings = WorldSkillsTeams(fetch: false)
    @State private var season_id = API.selected_season_id()
    @State private var grade_level = UserSettings.getGradeLevel()
    @State private var show_leaderboard = false
    @State private var importing = true
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack {
            if importing && API.world_skills_cache.teams.isEmpty {
                ImportingData()
                    .onReceive(timer) { _ in
                        if API.imported_skills {
                            world_skills_rankings = WorldSkillsTeams(fetch: false)
                            importing = false
                        }
                    }
            }
            else if !importing && API.world_skills_cache.teams.isEmpty {
                NoData()
            }
            else {
                if (show_leaderboard) {
                    List($world_skills_rankings.world_skills_teams) { team in
                        WorldSkillsRow(team_world_skills: team.wrappedValue).id(team.wrappedValue.ranking).onTapGesture {
                            expandedTeamWS = team.wrappedValue
                        }
                    }.fullScreenCover(isPresented: Binding<Bool>( // I wish we didn't need to do this
                        get: {
                            expandedTeamWS.number != ""
                        }, set: { expanded in
                            if !expanded {
                                expandedTeamWS = WorldSkillsTeam(world_skills: WorldSkills(), ranking: 0)
                            }
                        })) {
                        List {
                            Text("\(expandedTeamWS.combined) Combined")
                            Text("\(expandedTeamWS.programming) Prog")
                            Text("\(expandedTeamWS.driver) Driver")
                            Text("\(expandedTeamWS.highest_programming) Highest Prog")
                            Text("\(expandedTeamWS.highest_driver) Highest Driver")
                        }
                    }.fullScreenCover(isPresented: $showFilters) {
                        List {
                            if !(defaults.object(forKey: "favorite_teams") as? [String] ?? [String]()).isEmpty {
                                Button("Favorites") {
                                    title = "Favorites"
                                    region_id = 0
                                    letter = "0"
                                    world_skills_rankings = WorldSkillsTeams(filter_array: defaults.object(forKey: "favorite_teams") as? [String] ?? [String](), fetch: false)
                                    showFilters = false
                                }
                            }
                            Button("Region") {
                                showRegionFilters = true
                            }.fullScreenCover(isPresented: $showRegionFilters) {
                                List {
                                    Button("World") {
                                        title = "World Skills"
                                        region_id = 0
                                        letter = "0"
                                        world_skills_rankings = WorldSkillsTeams(fetch: false)
                                        showRegionFilters = false
                                        showFilters = false
                                    }
                                    ForEach(API.regions_map.sorted(by: <), id: \.key) { region, id in
                                        Button(region) {
                                            title = "\(region)"
                                            region_id = id
                                            letter = "0"
                                            world_skills_rankings = WorldSkillsTeams(region: id, fetch: false)
                                            showRegionFilters = false
                                            showFilters = false
                                        }
                                    }
                                }
                            }
                            Button("Letter") {
                                showLetterFilters = true
                            }.fullScreenCover(isPresented: $showLetterFilters) {
                                List(["A", "B", "C", "D", "E", "F", "G", "H", "J", "K", "L", "M", "N", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"], id: \.self) { char in
                                    Button(char) {
                                        title = "\(char) Skills"
                                        letter = char.first!
                                        world_skills_rankings = WorldSkillsTeams(letter: char.first!, fetch: false)
                                        showLetterFilters = false
                                        showFilters = false
                                    }
                                }
                            }
                            Button("Clear Filters") {
                                title = "World Skills"
                                region_id = 0
                                letter = "0"
                                world_skills_rankings = WorldSkillsTeams(fetch: false)
                                showFilters = false
                            }
                        }
                    }
                }
            }
        }.onAppear{
            self.show_leaderboard = true
            if (API.selected_season_id() != self.season_id) || (UserSettings.getGradeLevel() != self.grade_level) || (self.world_skills_rankings.world_skills_teams.isEmpty) {
                title = "World Skills"
                region_id = 0
                letter = "0"
                world_skills_rankings = WorldSkillsTeams(fetch: false)
                self.season_id = API.selected_season_id()
                self.grade_level = UserSettings.getGradeLevel()
            }
        }
        .onDisappear{
            self.show_leaderboard = false
        }
    }
}

#Preview {
    WorldSkillsRankingsView(title: .constant("World Skills"), showFilters: .constant(false))
}
