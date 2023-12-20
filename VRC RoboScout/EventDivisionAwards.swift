//
//  EventDivisionAwards.swift
//  VRC RoboScout
//
//  Created by William Castro on 6/23/23.
//

import SwiftUI

struct ExcellenceEligibleTeams: View {
    
    @State var event: Event
    @State var division: Division
    @State var middleSchool: Bool
    @Binding var excellenceOffered: Bool
    @Binding var middleSchoolExcellenceOffered: Bool
    @State var eligible_teams = [Team]()
    @State var showLoading = true
    
    func generate_location(team: Team) -> String {
        var location_array = [team.city, team.region, team.country]
        location_array = location_array.filter{ $0 != "" }
        return location_array.joined(separator: ", ")
    }
    
    func levelFilter(rankings: [Any]) -> [Any] {
        var output = [Any]()
        for ranking in rankings {
            if let ranking = ranking as? TeamRanking, middleSchool ? event.get_team(id: ranking.team.id)!.grade == "Middle School" : ($excellenceOffered.wrappedValue && $middleSchoolExcellenceOffered.wrappedValue ? event.get_team(id: ranking.team.id)!.grade != "Middle School" : true) {
                output.append(ranking)
            }
            if let ranking = ranking as? TeamSkillsRanking, middleSchool ? event.get_team(id: ranking.team.id)!.grade == "Middle School" : ($excellenceOffered.wrappedValue && $middleSchoolExcellenceOffered.wrappedValue ? event.get_team(id: ranking.team.id)!.grade != "Middle School" : true) {
                output.append(ranking)
            }
        }
        return output
    }
    
    func fetch_info() {
        DispatchQueue.global(qos: .userInteractive).async { [self] in
            
            if (event.rankings[division] ?? [TeamRanking]()).isEmpty || event.skills_rankings.isEmpty {
                return
            }
            
            // Top 30% in qualifier rankings
            let ranking_cutoff = Int(Double(levelFilter(rankings: event.rankings[division] ?? [TeamRanking]()).count) * 0.3)
            let rankings = levelFilter(rankings: event.rankings[division] ?? [TeamRanking]()) as! [TeamRanking]
            let rankings_teams = rankings.reversed().dropLast(rankings.count - ranking_cutoff).map{
                $0.team
            }
            
            // Top 30% in skills rankings
            let skills_rankings = levelFilter(rankings: event.skills_rankings) as! [TeamSkillsRanking]
            let skills_rankings_teams = skills_rankings.dropLast(skills_rankings.count - ranking_cutoff).map{
                $0.team
            }
            
            // Top 30% in auton skills
            let auton_skills_rankings = skills_rankings.sorted{
                $0.programming_score > $1.programming_score
            }
            let auton_skills_rankings_teams = auton_skills_rankings.dropLast(skills_rankings.count - ranking_cutoff).map{
                $0.team
            }
            
            var eligible_teams = [Team]()
            
            for team in event.teams {
                if rankings_teams.contains(where: { $0.id == team.id }) && skills_rankings_teams.contains(where: { $0.id == team.id }) && auton_skills_rankings_teams.contains(where: { $0.id == team.id }) {
                    eligible_teams.append(team)
                }
            }
            
            DispatchQueue.main.async {
                self.eligible_teams = eligible_teams
                self.showLoading = false
            }
        }
        
    }
    
    var body: some View {
        VStack {
            if showLoading {
                ProgressView().padding().onAppear{
                    fetch_info()
                }
                Spacer()
            }
            else {
                VStack(alignment: .leading) {
                    Text("Requirements:").padding()
                    BulletList(listItems: ["Top 30% in qualifier rankings", "Top 30% in skills rankings", "Top 30% in autonomous skills rankings"], listItemSpacing: 10).padding()
                    Text("The following teams are eligible:").padding()
                }
                if eligible_teams.isEmpty {
                    List {
                        Text("No eligible teams")
                    }
                    Spacer()
                }
                else {
                    List($eligible_teams) { team in
                        HStack {
                            Text(team.wrappedValue.number).font(.system(size: 20)).minimumScaleFactor(0.01).frame(width: 80, height: 30, alignment: .leading).bold()
                            VStack {
                                Text(team.wrappedValue.name).frame(maxWidth: .infinity, alignment: .leading).frame(height: 20)
                                Spacer().frame(height: 5)
                                Text(generate_location(team: team.wrappedValue)).font(.system(size: 11)).frame(maxWidth: .infinity, alignment: .leading).frame(height: 15)
                            }
                        }
                    }
                    Spacer()
                }
            }
        }
    }
}

struct EventDivisionAwards: View {
    
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var favorites: FavoriteStorage
    @EnvironmentObject var navigation_bar_manager: NavigationBarManager
    
    @State var event: Event
    @State var division: Division
    @State var showLoading = true
    @State var showingExcellenceEligibility = false
    @State var showingMiddleSchoolExcellenceEligibility = false
    @State var excellenceOffered = false
    @State var middleSchoolExcellenceOffered = false
    
    init(event: Event, division: Division) {
        self.event = event
        self.division = division
    }
    
    func fetch_awards() {
        DispatchQueue.global(qos: .userInteractive).async { [self] in
            event.fetch_awards(division: division)
            event.fetch_rankings(division: division)
            event.fetch_skills_rankings()
            DispatchQueue.main.async {
                self.showLoading = false
            }
        }
    }
    
    var body: some View {
        VStack {
            if showLoading {
                ProgressView().padding()
                Spacer()
            }
            else if (event.awards[division] ?? [DivisionalAward]()).isEmpty {
                NoData()
            }
            else {
                List {
                    ForEach(0..<event.awards[division]!.count, id: \.self) { i in
                        VStack(alignment: .leading) {
                            HStack {
                                Text(event.awards[division]![i].title)
                                Spacer()
                                if !event.awards[division]![i].qualifications.isEmpty {
                                    Menu {
                                        Text("Qualifies for:")
                                        ForEach(event.awards[division]![i].qualifications, id: \.self) { qual in
                                            Text(qual)
                                        }
                                    } label: {
                                        Image(systemName: "globe.americas")
                                    }
                                }
                            }
                            if event.awards[division]![i].teams.isEmpty && event.awards[division]![i].title.contains("Excellence") && !(event.rankings[division] ?? [TeamRanking]()).isEmpty && !event.skills_rankings.isEmpty {
                                Spacer().frame(height: 5)
                                Button("Show eligible teams") {
                                    if event.awards[division]![i].title.contains("Middle") {
                                        showingMiddleSchoolExcellenceEligibility = true
                                    }
                                    else {
                                        showingExcellenceEligibility = true
                                    }
                                }.font(.system(size: 14))
                                    .onAppear{
                                        if event.awards[division]![i].title.contains("Middle") {
                                            middleSchoolExcellenceOffered = true
                                        }
                                        else {
                                            excellenceOffered = true
                                        }
                                    }
                                    .sheet(isPresented: event.awards[division]![i].title.contains("Middle") ? $showingMiddleSchoolExcellenceEligibility : $showingExcellenceEligibility) {
                                        Text("Excellence Eligibility").font(.title).padding()
                                        ExcellenceEligibleTeams(event: event, division: division, middleSchool: event.awards[division]![i].title.contains("Middle"), excellenceOffered: $excellenceOffered, middleSchoolExcellenceOffered: $middleSchoolExcellenceOffered)
                                }
                            }
                            else if !event.awards[division]![i].teams.isEmpty {
                                Spacer().frame(height: 5)
                                ForEach(0..<event.awards[division]![i].teams.count, id: \.self) { j in
                                    if !event.awards[division]![i].teams.isEmpty {
                                        HStack {
                                            Text(event.awards[division]![i].teams[j].number).frame(maxWidth: .infinity, alignment: .leading).frame(width: 60).font(.system(size: 14)).foregroundColor(.secondary).bold()
                                            Text(event.awards[division]![i].teams[j].name).frame(maxWidth: .infinity, alignment: .leading).font(.system(size: 14)).foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }.task{
            fetch_awards()
        }.onAppear{
            navigation_bar_manager.title = "\(division.name) Awards"
        }
    }
}

struct EventDivisionAwards_Previews: PreviewProvider {
    static var previews: some View {
        EventDivisionAwards(event: Event(), division: Division())
    }
}
