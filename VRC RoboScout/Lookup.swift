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

struct Lookup: View {
    
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var favorites: FavoriteStorage
    @EnvironmentObject var navigation_bar_manager: NavigationBarManager
    
    @State var lookupState = 0
    
    var body: some View {
        VStack {
            Picker("Lookup", selection: $lookupState) {
                Text("Teams").tag(0)
                Text("Events").tag(1)
            }.pickerStyle(.segmented).padding()
            Spacer()
            if lookupState  == 0 {
                TeamLookup()
                    .environmentObject(favorites)
                    .environmentObject(settings)
            }
            else if lookupState == 1 {
                EventLookup()
                    .environmentObject(favorites)
                    .environmentObject(settings)
            }
        }.onAppear{
            navigation_bar_manager.title = "Lookup"
        }
    }
}

class EventSearch: ObservableObject {
    @Published var event_indexes: [String]
    @Published var events: [Event]
    
    init(name_query: String? = nil, page: Int = 1) {
        event_indexes = [String]()
        events = [Event]()
        if name_query == nil || name_query == "" {
            event_indexes = [String]()
            events = [Event]()
            return
        }
        let sku_array = RoboScoutAPI.robotevents_competition_scraper(params: ["name": name_query!, "seasonId": RoboScoutAPI.selected_season_id(), "page": page, "from_date": "01-Jan-1970"])
        let data = RoboScoutAPI.robotevents_request(request_url: "/seasons/\(RoboScoutAPI.selected_season_id())/events", params: ["sku": sku_array])
        
        for event_data in data {
            events.append(Event(fetch: false, data: event_data))
        }
        
        var count = 0
        for _ in events {
            event_indexes.append(String(count))
            count += 1
        }
        event_indexes.reverse()
    }
}

struct EventLookup: View {
    
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var favorites: FavoriteStorage
    
    @State private var events: EventSearch = EventSearch()
    @State private var name_query: String = ""
    @State private var page: Int = 1
    @State private var showLoading = false
    
    func event_query(name_query: String, page: Int = 1) {
        showLoading = true
        DispatchQueue.global(qos: .userInteractive).async { [self] in
            let fetched_events = EventSearch(name_query: name_query, page: page)
            
            DispatchQueue.main.async {
                self.events = fetched_events
                self.showLoading = false
            }
        }
    }
    
    var body: some View {
        VStack {
            TextField(
                "Event Name",
                text: $name_query,
                onCommit: {
                    showLoading = true
                    event_query(name_query: name_query)
                }
            ).frame(alignment: .center).multilineTextAlignment(.center).font(.system(size: 36)).padding(11)
            VStack {
                if showLoading {
                    ProgressView()
                }
            }.frame(height: 10)
            List(events.event_indexes) { event_index in
                EventRow(event: events.events[Int(event_index)!])
            }
            HStack {
                Spacer()
                Button(action: {
                    showLoading = true
                    events = EventSearch()
                    page -= 1
                    event_query(name_query: name_query, page: page)
                }, label: {
                    Image(systemName: "arrow.left").font(.system(size: 25))
                }).disabled(page <= 1 || showLoading).opacity((events.events.isEmpty && !showLoading) ? 0 : 1).padding(20)
                Text(String(describing: page)).font(.system(size: 25)).opacity((events.events.isEmpty && !showLoading) ? 0 : 1).padding()
                Button(action: {
                    showLoading = true
                    events = EventSearch()
                    page += 1
                    event_query(name_query: name_query, page: page)
                }, label: {
                    Image(systemName: "arrow.right").font(.system(size: 25))
                }).disabled(events.events.count < 20 || showLoading).opacity((events.events.isEmpty && !showLoading) ? 0 : 1).padding(20)
                Spacer()
            }
        }
    }
}

struct TeamLookup: View {
    
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var favorites: FavoriteStorage
    
    @State var team_number: String = ""
    @State var favorited: Bool = false
    @State var fetch: Bool = false
    @State var fetched: Bool = false
    @State private var team: Team = Team(id: 0, fetch: false)
    @State private var vrc_data_analysis = VRCDataAnalysis()
    @State private var world_skills = WorldSkills(team: Team(id: 0, fetch: false))
    @State private var avg_rank: Double = 0.0
    @State private var showLoading: Bool = false
    @State private var showingPopover = false
    
    let adam_score_map = [
        "Low",
        "Low Mid",
        "Mid",
        "High Mid",
        "High",
        "Very High"
    ]
    
    func adam_score() -> String {
        guard let model = try? AdamScore_500(configuration: MLModelConfiguration()) else {
            print("Error loading AdamScore model")
            return "Error"
        }
        guard let score = try? model.prediction(world_skills_ranking: Double(world_skills.ranking), trueskill_ranking: Double(vrc_data_analysis.trueskill_ranking), average_qualification_ranking: avg_rank, winrate: Double(vrc_data_analysis.total_wins) / Double(vrc_data_analysis.total_wins + vrc_data_analysis.total_losses + vrc_data_analysis.total_ties)) else {
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
        VStack {
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
                ).frame(alignment: .center).multilineTextAlignment(.center).font(.system(size: 36))
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
                        Text("Total Matches: \(vrc_data_analysis.total_wins + vrc_data_analysis.total_losses + vrc_data_analysis.total_ties)")
                        Text("Total Wins: \(vrc_data_analysis.total_wins)")
                        Text("Total Losses: \(vrc_data_analysis.total_losses)")
                        Text("Total Ties: \(vrc_data_analysis.total_ties)")
                    }
                    Spacer()
                    Text(fetched && $vrc_data_analysis.wrappedValue.trueskill != 0.0 ? "\(vrc_data_analysis.total_wins) - \(vrc_data_analysis.total_losses) -  \(vrc_data_analysis.total_ties)" : "")
                }
                if settings.getAdamScore() {
                    HStack {
                        Button("AdamScore™") {
                            showingPopover = true
                        }.popover(isPresented: $showingPopover) {
                            Text("AdamScore™")
                                .font(.headline)
                                .padding()
                            VStack(alignment: .leading) {
                                Text("AdamScore™ is a machine learning model trained on data from Team Ace's scout, Adam. 500 teams were manually reviewed and rated and the AdamScore™ model aims to predict the overall performance of any team.").padding()
                                Text("The following metrics are looked at:").padding()
                            }
                            BulletList(listItems: ["TrueSkill Ranking", "World Skills Ranking", "Average Qualifiers Ranking", "Winrate", "CCWM"], listItemSpacing: 10).padding()
                        }
                        Spacer()
                        Text(fetched && $vrc_data_analysis.wrappedValue.trueskill != 0.0 && world_skills.ranking != 0 ? adam_score() : "")
                    }
                }
                HStack {
                    NavigationLink(destination: TeamEventsView(team_number: team.number).environmentObject(settings)) {
                        Text("Events")
                    }
                }
            }
        }
    }
}

struct Lookup_Previews: PreviewProvider {
    static var previews: some View {
        Lookup()
    }
}
