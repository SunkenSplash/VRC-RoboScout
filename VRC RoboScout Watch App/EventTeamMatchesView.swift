//
//  EventTeamMatchesView.swift
//  VRC RoboScout
//
//  Created by William Castro on 5/19/25.
//

import SwiftUI

struct EventTeamMatchesView: View {
    
    @Binding var teams_map: [String: String]
    @State var event: Event
    @State var team: Team
    @State var division: Division?
    @State private var predictions = false
    @State private var calculating = false
    @State private var matches = [Match]()
    @State private var matches_list = [String]()
    @State private var showLoading = true
    
    init(teams_map: Binding<[String: String]>, event: Event, team: Team, division: Division? = nil) {
        self._teams_map = teams_map
        self._event = State(initialValue: event)
        self._team = State(initialValue: team)
        self._division = State(initialValue: division)
    }
    
    func fetch_info(predict: Bool = false) {
        DispatchQueue.global(qos: .userInteractive).async { [self] in
            
            var matches = [Match]()
            
            if self.team.id == 0 || self.team.number == "" {
                self.team = Team(id: self.team.id, number: self.team.number)
            }
            
            if division == nil {
                let matches = self.team.matches_at(event: event)
                if !matches.isEmpty {
                    self.division = (self.team.matches_at(event: event)[0]).division
                }
            }
            
            if division != nil {
                do {
                    self.event.fetch_matches(division: division!)
                    try self.event.calculate_team_performance_ratings(division: division!, forceRealCalculation: true)
                }
                catch {
                    print("Failed to calculate team performance ratings")
                }
                matches = self.event.matches[division!]!.filter{
                    $0.alliance_for(team: self.team) != nil
                }
            }
            
            if predict, let division = division {
                do {
                    try self.event.predict_matches(division: division)
                }
                catch {
                    print("Failed to predict matches")
                }
            }

            // Time should be in the format of "HH:mm" AM/PM
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"

            DispatchQueue.main.async {
                self.matches = matches
                self.matches_list.removeAll()
                var count = 0
                for match in matches {
                    var name = match.name
                    name.replace("Qualifier", with: "Q")
                    name.replace("Practice", with: "P")
                    name.replace("Final", with: "F")
                    name.replace("#", with: "")
                    
                    // If match.started is not nil, then use it
                    // Otherwise use match.scheduled
                    // If both are nil, then use ""
                    let date: String = {
                        if let started = match.started {
                            return formatter.string(from: started)
                        }
                        else if let scheduled = match.scheduled {
                            return formatter.string(from: scheduled)
                        }
                        else {
                            return " "
                        }
                    }()
                    
                    // count, name, red1, red2, blue1, blue2, red_score, blue_score, scheduled time
                    self.matches_list.append("\(count)&&\(name)&&\(match.red_alliance[0].id)&&\(match.red_alliance[1].id)&&\(match.blue_alliance[0].id)&&\(match.blue_alliance[1].id)&&\(match.red_score)&&\(match.blue_score)&&\(date)")
                    count += 1
                }
                self.showLoading = false
                self.calculating = false
            }
        }
    }

    var body: some View {
        VStack {
            if showLoading {
                ProgressView().padding()
                Spacer()
            }
            else if matches.isEmpty {
                NoData()
            }
            else {
                List($matches_list, id: \.self) { matchString in
                    MatchRowView(event: $event, matches: $matches, teams_map: $teams_map, predictions: $predictions, matchString: matchString, team: $team)
                }
            }
        }
        .onAppear {
            fetch_info()
        }
        .navigationTitle("\(self.team.number) Match List")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct EventTeamMatchesView_Previews: PreviewProvider {
    static var previews: some View {
        EventTeamMatchesView(teams_map: .constant(["139521": "229V", "149293": "44244N", "51053": "6526D", "129427": "9364H", "142585": "7700H", "154512": "1258V", "56472": "9364C", "34750": "609A", "143648": "10S", "124585": "16689A", "6726": "1469A", "158834": "16689X", "126698": "51581E", "123981": "938X", "103949": "7784W", "163848": "2681A", "159756": "8675V", "106963": "604X", "159758": "8675R", "133415": "938G", "112751": "10012G", "143633": "11688C", "159383": "938P", "131741": "51581S", "26857": "5155A", "5226": "10B", "163394": "1248X", "156024": "84141X", "139066": "98040C", "84626": "98225M", "66000": "98548C", "154057": "1698Y", "64866": "99621A", "123984": "938M", "153976": "3484X", "129041": "5327K", "3516": "10Z", "7461": "2605B", "19468": "920B", "154964": "16689E", "84623": "98225H", "153417": "1687C", "153961": "10M", "156083": "886N", "116369": "90385R", "153732": "7899A", "143928": "3583A", "111135": "8931R", "122903": "9364G", "155496": "7899B", "160663": "3150G", "154413": "12516A", "154424": "7899X", "46270": "609B", "159385": "938U", "124273": "884B", "122798": "884A", "161305": "7899D", "144871": "44244S", "84624": "98225J", "131949": "61002G", "63953": "7700E", "38353": "5233J", "143647": "10G", "159386": "938T", "104912": "80001B", "59817": "502A", "46216": "917A", "159382": "938N", "133559": "10J", "55588": "9805A", "112941": "938A", "142565": "8675F", "139487": "652A", "148732": "3512D", "134607": "949Z", "112942": "938B", "154963": "16689D", "63760": "6526H", "112945": "938C", "143659": "10009A", "86313": "11101B", "102468": "47874J", "137033": "3512B", "94347": "99621H", "139399": "537K", "135470": "938K", "133855": "502X", "147355": "84141B", "144387": "51777H", "133417": "938J", "86363": "47874A", "153351": "92620A", "41": "10A", "21700": "10N", "74089": "1010W", "153958": "1091A", "133414": "938F", "159384": "938R", "56": "10X", "3511": "10F", "75499": "99621B", "34474": "10C", "154970": "16689Z", "140299": "66475C", "135369": "10T", "156886": "47000X", "94342": "99621C", "143646": "10K", "154044": "1168A", "83403": "7700P", "95821": "90385G", "161365": "3512E", "3506": "10E", "571": "1000A", "142569": "93199G", "110534": "47874R", "154058": "1698X", "138964": "39313Z", "133416": "938H", "128381": "3150A", "133413": "938E", "84621": "98225F", "62819": "299Y", "143649": "10R", "147064": "84141A", "140136": "1023E", "154059": "10W", "56473": "9364D", "123983": "938W", "157347": "7899E", "143777": "88873A", "52997": "6526E", "93452": "5327S"]), event: Event(id: 51488), team: Team(id: 139521))
    }
}
