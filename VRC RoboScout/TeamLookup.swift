//
//  TeamLookup.swift
//  VRC RoboScout
//
//  Created by William Castro on 2/20/23.
//

import SwiftUI
import CoreML

struct TeamInfo: Identifiable {
    let id = UUID()
    let property: String
    let value: String
}

struct TeamInfoRow: View {
    var team_info: TeamInfo

    var body: some View {
        HStack{
            Text(team_info.property)
            Spacer()
            Text(team_info.value)
        }
    }
}

struct TeamLookup: View {
    @State var team_number: String = ""
    @State var favorited: Bool = false
    @State var fetch: Bool = false
    @State var fetched: Bool = false
    @State private var team: Team = Team(id: 0, fetch: false)
    @State private var vrc_data_analysis = VRCDataAnalysis()
    @State private var world_skills = WorldSkills(team: Team(id: 0, fetch: false))
    @State private var avg_rank: Double = 0.0
    @State private var showLoading: Bool = false
    @State private var showingAlert = false
    
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var favorites: FavoriteStorage
    
    let adam_score_map = [
        "Low",
        "Low Mid",
        "Mid",
        "High Mid",
        "High",
        "Very High"
    ]
    
    func adam_score() -> String {
        guard let model = try? AdamScore(configuration: MLModelConfiguration()) else {
            print("Error loading AdamScore model")
            return "Error"
        }
        guard let score = try? model.prediction(world_skills_ranking: Double(world_skills.ranking), trueskill_ranking: Double(vrc_data_analysis.trueskill_ranking), average_qualification_ranking: avg_rank, ccwm: Double(vrc_data_analysis.ccwm), winrate: Double(vrc_data_analysis.total_wins) / Double(vrc_data_analysis.total_wins + vrc_data_analysis.total_losses + vrc_data_analysis.total_ties)) else {
            print("Runtime error with AdamScore model")
            return "Error"
        }
        return adam_score_map[Int(score.adamscore)]
    }
    
    func fetch_info(number: String) {
        hideKeyboard()
        
        showLoading = true
        team_number = number.uppercased()
        
        DispatchQueue.global(qos: .userInteractive).async { [self] in
            
            let fetched_team = Team(number: number)
                        
            if fetched_team.id == 0 {
                DispatchQueue.main.async {
                    showLoading = false
                }
                return
            }
            
            let fetced_vrc_data_analysis = API.vrc_data_analysis_for(team: fetched_team, fetch: false)
            let fetched_world_skills = API.world_skills_for(team: fetched_team)
            let fetched_avg_rank = fetched_team.average_ranking()
            
            var is_favorited = false
            for favorite_team in favorites.favorite_teams {
                if favorite_team == fetched_team.number {
                    is_favorited = true
                }
            }
                        
            DispatchQueue.main.async {
                team = fetched_team
                vrc_data_analysis = fetced_vrc_data_analysis
                world_skills = fetched_world_skills
                avg_rank = fetched_avg_rank
                favorited = is_favorited
                
                showLoading = false
                fetched = true
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack() {
                HStack {
                    Image(systemName: "star").font(.system(size: 25)).padding(20).hidden()
                    TextField(
                        "229V",
                        text: $team_number,
                        onEditingChanged: { _ in
                            team = Team(id: 0, fetch: false)
                            vrc_data_analysis = VRCDataAnalysis()
                            world_skills = WorldSkills(team: Team(id: 0, fetch: false))
                            avg_rank = 0.0
                            fetched = false
                            favorited = false
                            showLoading = false
                        },
                        onCommit: {
                            showLoading = true
                            fetch_info(number: team_number)
                        }
                    ).frame(alignment: .center).padding(20).multilineTextAlignment(.center).font(.system(size: 36))
                        .onAppear{
                            if fetch {
                                fetch_info(number: team_number)
                                fetch = false
                            }
                        }
                    Button(action: {
                        
                        if team_number == "" {
                            return
                        }
                        
                        showLoading = true
                        
                        hideKeyboard()
                        team_number = team_number.uppercased()
                        if team.number != team_number {
                            fetch_info(number: team_number)
                            showLoading = true
                        }
                        
                        if team.number != team_number {
                            return
                        }
                        
                        for favorite_team in favorites.favorite_teams {
                            if favorite_team == team.number {
                                favorites.favorite_teams.removeAll(where: {
                                    $0 == team.number
                                })
                                favorites.sort_teams()
                                defaults.set(favorites.favorite_teams, forKey: "favorite_teams")
                                favorited = false
                                return
                            }
                        }
                        Task {
                            favorites.favorite_teams.append(team_number)
                            favorites.sort_teams()
                            defaults.set(favorites.favorite_teams, forKey: "favorite_teams")
                            favorited = true
                            showLoading = false
                        }
                    }, label: {
                        if favorited {
                            Image(systemName: "star.fill").font(.system(size: 25))
                        }
                        else {
                            Image(systemName: "star").font(.system(size: 25))
                        }
                    }).padding(20)
                }
                VStack {
                    if showLoading {
                        ProgressView()
                    }
                }.frame(height: 10)
                List {
                    HStack {
                        Text("Name")
                        Spacer()
                        Text(team.name)
                    }
                    HStack {
                        Text("Robot")
                        Spacer()
                        Text(team.robot_name)
                    }
                    HStack {
                        Text("Organization")
                        Spacer()
                        Text(team.organization)
                    }
                    HStack {
                        Text("Location")
                        Spacer()
                        Text(fetched ? "\(team.city), \(team.region)" : "")
                    }
                    HStack {
                        Menu("TrueSkill Ranking") {
                            Text(fetched && $vrc_data_analysis.wrappedValue.trueskill_ranking != 0 ? "\(displayRoundedTenths(number: vrc_data_analysis.trueskill)) TrueSkill" : "Please import TrueSkill data")
                            Text((vrc_data_analysis.trueskill_ranking_change >= 0 ? "Up " : "Down ") + "\(abs(vrc_data_analysis.trueskill_ranking_change))" + " places since last update")
                        }
                        Spacer()
                        Text(fetched && $vrc_data_analysis.wrappedValue.trueskill_ranking != 0 ? "\(vrc_data_analysis.trueskill_ranking)" : "")
                    }
                    HStack {
                        Text("World Skills Ranking")
                        Spacer()
                        Text(fetched && world_skills.ranking != 0 ? "\(world_skills.ranking)" : "")
                    }
                    HStack {
                        Menu("World Skills Score") {
                            Text("\(world_skills.driver) Driver")
                            Text("\(world_skills.programming) Programming")
                            Text("\(world_skills.highest_driver) Highest Driver")
                            Text("\(world_skills.highest_programming) Highest Programming")
                        }
                        Spacer()
                        Text(fetched && world_skills.ranking != 0 ? "\(world_skills.combined)" : "")
                    }
                    HStack {
                        Menu("Match Statistics") {
                            Text("Average Qualifiers Ranking: \(displayRoundedTenths(number: avg_rank))")
                            Text("CCWM: \(displayRoundedTenths(number: vrc_data_analysis.ccwm))")
                            Text("Winrate: " + ((vrc_data_analysis.total_wins + vrc_data_analysis.total_losses + vrc_data_analysis.total_ties > 0) ? ((displayRoundedTenths(number: Double(vrc_data_analysis.total_wins) / Double(vrc_data_analysis.total_wins + vrc_data_analysis.total_losses + vrc_data_analysis.total_ties) * 100.0)) + "%") : ""))
                            Text("Total Wins: \(vrc_data_analysis.total_wins)")
                            Text("Total Losses: \(vrc_data_analysis.total_losses)")
                            Text("Total Ties: \(vrc_data_analysis.total_ties)")
                        }
                        Spacer()
                        Text(fetched && $vrc_data_analysis.wrappedValue.trueskill != 0.0 ? "\(vrc_data_analysis.total_wins + vrc_data_analysis.total_losses + vrc_data_analysis.total_ties) Matches" : "")
                    }
                    if settings.getAdamScore() {
                        HStack {
                            Button("AdamScore™") {
                                showingAlert = true
                            }.alert("AdamScore™ takes into account TrueSkill, world skills, average qualifiers ranking, CCWM, and winrate to rate teams with a machine learning model trained on data from Adam, Team Jelly's scout.", isPresented: $showingAlert) {
                                Button("OK", role: .cancel) { }
                            }
                            Spacer()
                            Text(fetched && $vrc_data_analysis.wrappedValue.trueskill != 0.0 && world_skills.ranking != 0 ? adam_score() : "")
                        }
                    }
                    HStack {
                        NavigationLink(destination: Events(team_number: team.number).environmentObject(settings)) {
                            Text("Events")
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Team Lookup")
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

struct TeamLookup_Previews: PreviewProvider {
    static var previews: some View {
        TeamLookup()
    }
}
