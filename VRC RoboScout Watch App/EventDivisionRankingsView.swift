//
//  EventDivisionRankingsView.swift
//  VRC RoboScout
//
//  Created by William Castro on 5/19/23.
//

import SwiftUI

class EventDivisionRankingsList: ObservableObject {
    @Published var rankings_indexes: [Int]
    
    init(rankings_indexes: [Int] = [Int]()) {
        self.rankings_indexes = rankings_indexes.sorted()
    }
    
    func sort_by(option: Int, event: Event, division: Division) {
        var sorted = [Int]()
        
        // Create an array of team performance ratings from the event.team_performance_ratings[division] dictionary
        let team_performance_ratings = Array(event.team_performance_ratings[division]!.values)
        
        let team_rankings = event.rankings[division] ?? [TeamRanking]()
        
        // By rank
        if option == 0 {
            // Create the indexes of the rankings in order
            for i in 0..<event.rankings[division]!.count {
                sorted.append(i)
            }
        }
        // By OPR
        else if option == 1 {
            // Sort the team performance ratings for the given division by OPR
            // The larger the OPR, the better the ranking
            let option_order = team_performance_ratings.sorted(by: { $0.opr < $1.opr })
            // Get the indexes of the sorted team performance ratings
            for team_performance_rating in option_order {
                sorted.append(event.rankings[division]!.firstIndex(where: { $0.team.id == team_performance_rating.team.id })!)
            }
        }
        // By DPR
        else if option == 2 {
            // Sort the team performance ratings for the given division by DPR
            // The smaller the DPR, the better the ranking
            let option_order = team_performance_ratings.sorted(by: { $0.dpr > $1.dpr })
            // Get the indexes of the sorted team performance ratings
            for team_performance_rating in option_order {
                sorted.append(event.rankings[division]!.firstIndex(where: { $0.team.id == team_performance_rating.team.id })!)
            }
        }
        // By CCWM
        else if option == 3 {
            // Sort the team performance ratings for the given division by CCWM
            // The larger the CCWM, the better the ranking
            let option_order = team_performance_ratings.sorted(by: { $0.ccwm < $1.ccwm })
            // Get the indexes of the sorted team performance ratings
            for team_performance_rating in option_order {
                sorted.append(event.rankings[division]!.firstIndex(where: { $0.team.id == team_performance_rating.team.id })!)
            }
        }
        // By AP
        else if option == 4 {
            // Sort the team rankings for the given division by AP
            // The larger the AP, the better the ranking
            let option_order = team_rankings.sorted(by: { $0.ap < $1.ap })
            // Get the indexes of the sorted team rankings
            for team_ranking in option_order {
                sorted.append(event.rankings[division]!.firstIndex(where: { $0.team.id == team_ranking.team.id })!)
            }
        }
        // By SP
        else if option == 5 {
            // Sort the team rankings for the given division by SP
            // The larger the SP, the better the ranking
            let option_order = team_rankings.sorted(by: { $0.sp < $1.sp })
            // Get the indexes of the sorted team rankings
            for team_ranking in option_order {
                sorted.append(event.rankings[division]!.firstIndex(where: { $0.team.id == team_ranking.team.id })!)
            }
        }
        // By high score
        else if option == 6 {
            // Sort the team rankings for the given division by high score
            // The larger the high score, the better the ranking
            let option_order = team_rankings.sorted(by: { $0.high_score < $1.high_score })
            // Get the indexes of the sorted team rankings
            for team_ranking in option_order {
                sorted.append(event.rankings[division]!.firstIndex(where: { $0.team.id == team_ranking.team.id })!)
            }
        }
        self.rankings_indexes = sorted
    }
}

struct EventDivisionRankingsView: View {
    
    @EnvironmentObject var settings: UserSettings
    
    @State var event: Event
    @State var division: Division
    @State var teams_map: [String: String]
    @State var event_rankings_list: EventDivisionRankingsList
    @State var showLoading = true
    @State var showingSheet = false
    @Binding var sortingOption: Int
    
    init(event: Event, division: Division, teams_map: [String: String], sortingOption: Binding<Int>) {
        self.event = event
        self.division = division
        self.teams_map = teams_map
        self.event_rankings_list = EventDivisionRankingsList()
        self._sortingOption = sortingOption
    }
    
    func fetch_rankings() {
        DispatchQueue.global(qos: .userInteractive).async { [self] in
            event.fetch_rankings(division: division)
            var fetched_rankings_indexes = [Int]()
            var counter = 0
            for _ in (event.rankings[division] ?? [TeamRanking]()) {
                fetched_rankings_indexes.append(counter)
                counter += 1
            }
            DispatchQueue.main.async {
                self.event_rankings_list = EventDivisionRankingsList(rankings_indexes: fetched_rankings_indexes)
                self.showLoading = false
            }
        }
    }
    
    func team_ranking(rank: Int) -> TeamRanking {
        return event.rankings[division]![rank]
    }
    
    var body: some View {
        VStack {
            if showLoading {
                ProgressView().padding()
                Spacer()
            }
            else if (event.rankings[division] ?? [TeamRanking]()).isEmpty {
                NoData()
            }
            else {
                List(event_rankings_list.rankings_indexes.reversed(), id: \.self) { rank in
                    NavigationLink(destination: EventTeamMatchesView(teams_map: $teams_map, event: self.event, team: Team(id: team_ranking(rank: rank).team.id, fetch: false), division: self.division)) {
                        VStack {
                            HStack {
                                Text(teams_map[String(team_ranking(rank: rank).team.id)] ?? "").font(.system(size: 15)).minimumScaleFactor(0.01).frame(alignment: .leading).bold()
                                Spacer()
                                Text((event.get_team(id: team_ranking(rank: rank).team.id) ?? Team()).name).font(.system(size: 15)).frame(alignment: .trailing).lineLimit(1)
                            }
                            HStack {
                                Text("# \(team_ranking(rank: rank).rank)").frame(alignment: .leading).font(.system(size: 15))
                                Spacer()
                                Text("\(team_ranking(rank: rank).wins)-\(team_ranking(rank: rank).losses)-\(team_ranking(rank: rank).ties)").frame(alignment: .trailing).font(.system(size: 15))
                            }
                            HStack {
                                VStack {
                                    Text("WP: \(team_ranking(rank: rank).wp)").font(.system(size: 12)).foregroundColor(.secondary)
                                }
                                Spacer()
                                VStack {
                                    Text("AP: \(team_ranking(rank: rank).ap)").font(.system(size: 12)).foregroundColor(.secondary)
                                }
                                Spacer()
                                VStack {
                                    Text("SP: \(team_ranking(rank: rank).sp)").font(.system(size: 12)).foregroundColor(.secondary)
                                }
                            }
                        }.onChange(of: sortingOption) { _, option in // first parameter is the previous option, not needed
                            self.event_rankings_list.sort_by(option: option, event: self.event, division: self.division)
                            self.showLoading = true
                            self.showLoading = false
                        }
                    }
                }
            }
        }.task{
            do {
                try self.event.calculate_team_performance_ratings(division: self.division)
            }
            catch {}
            fetch_rankings()
        }
    }
}

struct EventDivisionRankingsView_Previews: PreviewProvider {
    static var previews: some View {
        EventDivisionRankingsView(event: Event(id: 51488), division: Division(id: 1, name: "North Division"), teams_map: ["139521": "229V", "149293": "44244N", "51053": "6526D", "129427": "9364H", "142585": "7700H", "154512": "1258V", "56472": "9364C", "34750": "609A", "143648": "10S", "124585": "16689A", "6726": "1469A", "158834": "16689X", "126698": "51581E", "123981": "938X", "103949": "7784W", "163848": "2681A", "159756": "8675V", "106963": "604X", "159758": "8675R", "133415": "938G", "112751": "10012G", "143633": "11688C", "159383": "938P", "131741": "51581S", "26857": "5155A", "5226": "10B", "163394": "1248X", "156024": "84141X", "139066": "98040C", "84626": "98225M", "66000": "98548C", "154057": "1698Y", "64866": "99621A", "123984": "938M", "153976": "3484X", "129041": "5327K", "3516": "10Z", "7461": "2605B", "19468": "920B", "154964": "16689E", "84623": "98225H", "153417": "1687C", "153961": "10M", "156083": "886N", "116369": "90385R", "153732": "7899A", "143928": "3583A", "111135": "8931R", "122903": "9364G", "155496": "7899B", "160663": "3150G", "154413": "12516A", "154424": "7899X", "46270": "609B", "159385": "938U", "124273": "884B", "122798": "884A", "161305": "7899D", "144871": "44244S", "84624": "98225J", "131949": "61002G", "63953": "7700E", "38353": "5233J", "143647": "10G", "159386": "938T", "104912": "80001B", "59817": "502A", "46216": "917A", "159382": "938N", "133559": "10J", "55588": "9805A", "112941": "938A", "142565": "8675F", "139487": "652A", "148732": "3512D", "134607": "949Z", "112942": "938B", "154963": "16689D", "63760": "6526H", "112945": "938C", "143659": "10009A", "86313": "11101B", "102468": "47874J", "137033": "3512B", "94347": "99621H", "139399": "537K", "135470": "938K", "133855": "502X", "147355": "84141B", "144387": "51777H", "133417": "938J", "86363": "47874A", "153351": "92620A", "41": "10A", "21700": "10N", "74089": "1010W", "153958": "1091A", "133414": "938F", "159384": "938R", "56": "10X", "3511": "10F", "75499": "99621B", "34474": "10C", "154970": "16689Z", "140299": "66475C", "135369": "10T", "156886": "47000X", "94342": "99621C", "143646": "10K", "154044": "1168A", "83403": "7700P", "95821": "90385G", "161365": "3512E", "3506": "10E", "571": "1000A", "142569": "93199G", "110534": "47874R", "154058": "1698X", "138964": "39313Z", "133416": "938H", "128381": "3150A", "133413": "938E", "84621": "98225F", "62819": "299Y", "143649": "10R", "147064": "84141A", "140136": "1023E", "154059": "10W", "56473": "9364D", "123983": "938W", "157347": "7899E", "143777": "88873A", "52997": "6526E", "93452": "5327S"], sortingOption: .constant(0))
    }
}
