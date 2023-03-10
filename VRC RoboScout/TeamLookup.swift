//
//  TeamLookup.swift
//  VRC RoboScout
//
//  Created by William Castro on 2/20/23.
//

import SwiftUI

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
    @State var fetch: Bool = false
    @State var fetched: Bool = false
    @State private var team: Team = Team(id: 0, fetch: false)
    @State private var vrc_data_analysis = VRCDataAnalysis(team: Team(id: 0, fetch: false))
    @State private var world_skills = WorldSkills(team: Team(id: 0, fetch: false))
    @State private var avg_rank: Double = 0.0
    @State private var showLoading: Bool = false
    
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var favorites: FavoriteTeams
    
    func fetch_info(team_number: String) {
        hideKeyboard()
        showLoading = true
        Task {
            team = Team(number: team_number)
            if team.id == 0 || team.registered == false {
                showLoading = false
                return
            }
            
            vrc_data_analysis = API.vrc_data_analysis_for(team: team)
            world_skills = API.world_skills_for(team: team)
            avg_rank = team.average_ranking(season: 173)
        
            showLoading = false
            fetched = true
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                TextField(
                    "2733J",
                    text: $team_number
                ).frame(alignment: .center).padding(20).multilineTextAlignment(.center).font(.system(size: 36))
                    .onAppear{
                        if fetch {
                            fetch_info(team_number: team_number)
                            fetch = false
                        }
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
                        Menu("TrueSkill") {
                            Text("Rank #\(vrc_data_analysis.tsranking)")
                            Text((vrc_data_analysis.tsranking_change >= 0 ? "Up " : "Down ") + "\(abs(vrc_data_analysis.tsranking_change))" + " places since last update")
                        }
                        Spacer()
                        Text(fetched ? "\(displayRoundedTenths(number: vrc_data_analysis.trueskill))" : "")
                    }
                    HStack {
                        Text("World Skills Ranking")
                        Spacer()
                        Text(fetched ? "\(world_skills.ranking)" : "")
                    }
                    HStack {
                        Menu("World Skills Score") {
                            Text("\(world_skills.driver) Driver")
                            Text("\(world_skills.programming) Programming")
                            Text("\(world_skills.highest_driver) Highest Driver")
                            Text("\(world_skills.highest_programming) Highest Programming")
                        }
                        Spacer()
                        Text(fetched ? "\(world_skills.combined)" : "")
                    }
                    HStack {
                        Menu("Match Statistics") {
                            Text("Average Qualifiers Ranking: \(displayRoundedTenths(number: avg_rank))")
                            Text("CCWM: \(displayRoundedTenths(number: vrc_data_analysis.ccwm))")
                            Text("Total Wins: \(vrc_data_analysis.total_wins)")
                            Text("Total Losses: \(vrc_data_analysis.total_losses)")
                            Text("Total Ties: \(vrc_data_analysis.total_ties)")
                        }
                        Spacer()
                        Text(fetched ? "\(vrc_data_analysis.total_wins + vrc_data_analysis.total_losses + vrc_data_analysis.total_ties) Matches" : "")
                    }
                }
                HStack {
                    Button("Fetch Info") {
                        fetch_info(team_number: team_number)
                    }.font(.system(size: 19)).frame(alignment: .center).padding(40)
                    Button("Add Favorite") {
                        hideKeyboard()
                        if team.number != team_number {
                            fetch_info(team_number: team_number)
                        }
                        for favorite_team in favorites.favorite_teams {
                            if favorite_team == team.number {
                                return
                            }
                        }
                        showLoading = true
                        Task {
                            favorites.favorite_teams.append(team_number)
                            favorites.sort()
                            defaults.set(favorites.favorite_teams, forKey: "favorite_teams")
                            showLoading = false
                        }
                    }.font(.system(size: 19)).frame(alignment: .center).padding(40)
                }
                
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Team Lookup")
                        .fontWeight(.medium)
                        .font(.system(size: 19))
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
