//
//  RoboScoutAPI.swift
//  VRC RoboScout
//
//  Created by William Castro on 4/20/23.
//

import Foundation
import Matft

public class RoboScoutAPI {
    
    public var world_skills_cache: [[String: Any]]
    public var vrc_data_analysis_cache: [[String: Any]]
    public var season_id_map: [Int: String]
    public var current_season_id: Int
    
    public init() {
        self.world_skills_cache = [[String: Any]]()
        self.vrc_data_analysis_cache = [[String: Any]]()
        self.season_id_map = [Int: String]()
        self.current_season_id = 0
    }

    public static func robotevents_date(date: String) -> Date? {
        let formatter = DateFormatter()
        // Example date: "2023-04-26T11:54:40-04:00"
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"

        return formatter.date(from: date) ?? nil
    }
    
    public static func robotevents_url() -> String {
        return "https://www.robotevents.com/api/v2"
    }
    
    public static func vrc_data_analysis_url() -> String {
        return "http://vrc-data-analysis.com/v1"
    }
    
    public static func robotevents_access_key() -> String {
        return UserSettings.getRobotEventsAPIKey()
    }
    
    public static func robotevents_request(request_url: String, params: [String: Any] = [:]) -> [[String: Any]] {
        var data = [[String: Any]]()
        var request_url = self.robotevents_url() + request_url
        var page = 1
        var cont = true
        var params = params
        
        while cont {
            
            params["page"] = page
            
            let semaphore = DispatchSemaphore(value: 0)
            
            if params["per_page"] == nil {
                params["per_page"] = 250
            }
            
            var components = URLComponents(string: request_url)!
            components.queryItems = params.map { (key, value) in
                URLQueryItem(name: key, value: String(describing: value))
            }
            
            request_url = components.url?.description ?? request_url
            
            for (key, value) in params {
                if value is [CustomStringConvertible] {
                    for (index, elem) in (value as! [CustomStringConvertible]).enumerated() {
                        request_url += String(format: "&%@[%d]=%@", key, index, elem.description)
                    }
                }
            }

            // Create URL Request using the request_url string, which is the URL we are going to use to get data from Robotevents
            let request = NSMutableURLRequest(url: URL(string: request_url)!)
            request.setValue(String(format: "Bearer %@", self.robotevents_access_key()), forHTTPHeaderField: "Authorization")
            request.httpMethod = "GET"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let task = URLSession.shared.dataTask(with: request as URLRequest) { (response_data, response, error) in
                if response_data != nil {
                    do {
                        print(String(format: "RobotEvents API request (page %d): %@", page, components.url?.description ?? request_url))
                        // Convert the data to JSON
                        let json = try JSONSerialization.jsonObject(with: response_data!) as? [String: Any]
                        
                        if json == nil || (response as? HTTPURLResponse)?.statusCode != 200 {
                            return
                        }
                        
                        for elem in json!["data"] as! [Any] {
                            data.append(elem as! [String: Any])
                        }
                        page += 1
                        
                        if ((json!["meta"] as! [String: Any])["last_page"] as! Int == (json!["meta"] as! [String: Any])["current_page"] as! Int) {
                            cont = false
                        }
                        semaphore.signal()
                        
                    } catch let error as NSError {
                        print("NSERROR " + error.description)
                        cont = false
                        semaphore.signal()
                    }
                } else if let error = error {
                    print("ERROR " + error.localizedDescription)
                    cont = false
                    semaphore.signal()
                }
            }
            task.resume()
            _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        }
        return data
    }
    
    public static func robotevents_competition_scraper(params: [String: Any] = [:]) -> [String] {
        
        var request_url = "https://www.robotevents.com/robot-competitions/vex-robotics-competition"
        var params = params
        
        if params["page"] == nil {
            params["page"] = 1
        }
        
        let semaphore = DispatchSemaphore(value: 0)
        
        var components = URLComponents(string: request_url)!
        components.queryItems = params.map { (key, value) in
            URLQueryItem(name: key, value: String(describing: value))
        }
        
        request_url = components.url?.description ?? request_url
        
        for (key, value) in params {
            if value is [CustomStringConvertible] {
                for (index, elem) in (value as! [CustomStringConvertible]).enumerated() {
                    request_url += String(format: "&%@[%d]=%@", key, index, elem.description)
                }
            }
        }
        
        var sku_array = [String]()
        
        let request = NSMutableURLRequest(url: URL(string: request_url)!)
        request.setValue(String(format: "Bearer %@", self.robotevents_access_key()), forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) { (response_data, response, error) in
            if response_data != nil {
                print(String(format: "RobotEvents Scraper (page %d): %@", params["page"] as? Int ?? 0, components.url?.description ?? request_url))
                let html = String(data: response_data!, encoding: .utf8)!
                
                let regex = try! NSRegularExpression(pattern: "https://www\\.robotevents\\.com/robot-competitions/vex-robotics-competition/RE-VRC([+-]?(?=\\.\\d|\\d)(?:\\d+)?(?:\\.?\\d*))(?:[Ee]([+-]?\\d+))?([+-]?(?=\\.\\d|\\d)(?:\\d+)?(?:\\.?\\d*))(?:[Ee]([+-]?\\d+))?html", options: [.caseInsensitive])
                let range = NSRange(location: 0, length: html.count)
                let matches = regex.matches(in: html, options: [], range: range)
                
                for match in matches {
                    sku_array.append(String(html[Range(match.range, in: html)!]).replacingOccurrences(of: "https://www.robotevents.com/robot-competitions/vex-robotics-competition/", with: "").replacingOccurrences(of: ".html", with: ""))
                }
                
                semaphore.signal()
            } else if let error = error {
                print("ERROR " + error.localizedDescription)
                semaphore.signal()
            }
        }
        task.resume()
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        return sku_array
    }
    
    public static func vrc_data_analysis_request(request_url: String) -> [String: Any] {
        var data = [String: Any]()
        let request_url = self.vrc_data_analysis_url() + request_url
        
        let semaphore = DispatchSemaphore(value: 0)
        
        let components = URLComponents(string: request_url)!
        
        let request = NSMutableURLRequest(url: components.url! as URL)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) { (response_data, response, error) in
            if response_data != nil {
                do {
                    print(String(format: "VRC DA API request: %@", components.url?.description ?? request_url))
                    // Convert the data to JSON
                    let json = try JSONSerialization.jsonObject(with: response_data!) as? [String: Any]
                    
                    if json == nil || (response as? HTTPURLResponse)?.statusCode != 200 {
                        return
                    }
                    
                    data = json!
                    semaphore.signal()
                    
                } catch let error as NSError {
                    print("NSERROR " + error.description)
                    semaphore.signal()
                }
            } else if let error = error {
                print("ERROR " + error.localizedDescription)
                semaphore.signal()
            }
        }
        task.resume()
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        return data
    }
    
    public func generate_season_id_map() {
        let seasons_data = RoboScoutAPI.robotevents_request(request_url: "/seasons/")
        
        for season_data in seasons_data {
            if (season_data["program"] as! [String: Any])["id"] as! Int == 1 {
                self.season_id_map[(season_data)["id"] as! Int] = (season_data)["name"] as? String ?? ""
                if current_season_id == 0 {
                    current_season_id = (season_data)["id"] as! Int
                }
            }
        }

        print("Season ID map generated")
    }

    public static func selected_season_id() -> Int {
        return UserDefaults.standard.object(forKey: "selected_season_id") as? Int ?? 181
    }
    
    public func update_world_skills_cache(season: Int? = nil) {

        let semaphore = DispatchSemaphore(value: 0)
            
        let components = URLComponents(string: String(format: "https://www.robotevents.com/api/seasons/%d/skills", season ?? RoboScoutAPI.selected_season_id()))!
                    
        let request = NSMutableURLRequest(url: components.url! as URL)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) { (response_data, response, error) in
            if response_data != nil {
                // Convert the data to JSON
                let json = try? JSONSerialization.jsonObject(with: response_data!) as? [[String: Any]]
                
                if json != nil {
                    self.world_skills_cache = json!
                    print("World skills cache updated")
                }
                else {
                    self.world_skills_cache = [[String: Any]]()
                    print("Failed to update world skills cache")
                }
                semaphore.signal()
            } else if let error = error {
                print(error.localizedDescription)
                semaphore.signal()
            }
        }
        task.resume()
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
    }
        
    public func world_skills_for(team: Team) -> WorldSkills {
        if self.world_skills_cache.count == 0  {
            self.update_world_skills_cache()
        }
        
        var skills_data = [String: Any]()
        for skills_entry in self.world_skills_cache {
            if (skills_entry["team"] as! [String: Any])["id"] as! Int == team.id {
                skills_data = skills_entry
                break
            }
        }
        return WorldSkills(team: team, data: skills_data)
    }
                    
    public func world_skills_place(ranking: Int) -> WorldSkills {
        if self.world_skills_cache.count == 0 {
            self.update_world_skills_cache()
        }
        var skills_data = [String: Any]()
        for skills_entry in self.world_skills_cache {
            if skills_entry["rank"] as! Int == ranking {
                skills_data = skills_entry
                break
            }
        }
        return WorldSkills(team: Team(id: (skills_data["team"] as! [String: Any])["id"] as! Int), data: skills_data)
    }
                
    public func update_vrc_data_analysis_cache() {
        
        let semaphore = DispatchSemaphore(value: 0)
            
        let components = URLComponents(string: "http://vrc-data-analysis.com/v1/allteams")!
                    
        let request = NSMutableURLRequest(url: components.url! as URL)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) { (response_data, response, error) in
            if response_data != nil {
                do {
                    // Convert the data to JSON
                    let json = try JSONSerialization.jsonObject(with: response_data!) as? [[String: Any]]
                    
                    if json == nil {
                        print("Failed to update VRC Data Analysis cache")
                        return
                    }
                    
                    self.vrc_data_analysis_cache = [[String: Any]]()
                    
                    var abs_ranking = 0
                    var prev_count = 0
                    for team in json! {
                        
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
                        
                        self.vrc_data_analysis_cache.append(team_data_dict)
                        
                        self.vrc_data_analysis_cache.sort(by: {
                            ($0["abs_ranking"] as! Int) < ($1["abs_ranking"] as! Int)
                        })
                        
                        if self.vrc_data_analysis_cache.count > prev_count {
                            abs_ranking += 1
                        }
                        prev_count = self.vrc_data_analysis_cache.count
                    }
                    print("Updated VRC Data Analysis cache")
                    
                    semaphore.signal()
                    

                }  catch let error as NSError {
                    print(error.localizedDescription)
                    semaphore.signal()
                }
            } else if let error = error {
                print(error.localizedDescription)
                semaphore.signal()
            }
        }
        task.resume()
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
    }
    
    public func fetch_raw_vrc_data_analysis() -> [[String: Any]] {
        let semaphore = DispatchSemaphore(value: 0)
            
        let components = URLComponents(string: "http://vrc-data-analysis.com/v1/allteams")!
                    
        let request = NSMutableURLRequest(url: components.url! as URL)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var data = [[String: Any]]()
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) { (response_data, response, error) in
            if response_data != nil {
                do {
                    // Convert the data to JSON
                    let json = ((try JSONSerialization.jsonObject(with: response_data!) as? [[String: Any]]) ?? [[String: Any]]()).filter({ ($0["ts_ranking"] as! Int) != 99999 })
                    data = json
                    semaphore.signal()
                }  catch let error as NSError {
                    print(error.localizedDescription)
                    semaphore.signal()
                }
            } else if let error = error {
                print(error.localizedDescription)
                semaphore.signal()
            }
        }
        task.resume()
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        
        return data
    }
    
    public func vrc_data_analysis_for(team: Team, fetch: Bool) -> VRCDataAnalysis {
        var vrc_data_analysis_data = [String: Any]()
        if fetch {
            vrc_data_analysis_data = RoboScoutAPI.vrc_data_analysis_request(request_url: "/team/\(team.number)")
        }
        else {
            for vrc_data_analysis_entry in self.vrc_data_analysis_cache {
                if vrc_data_analysis_entry["id"] as! Int == team.id {
                    vrc_data_analysis_data = vrc_data_analysis_entry
                    break
                }
            }
        }
        
        return VRCDataAnalysis(data: vrc_data_analysis_data)
    }
    
}
        
public class VRCDataAnalysis {
    
    public var id: Int
    public var team_number: String
    public var abs_ranking: Int
    public var trueskill_ranking: Int
    public var trueskill_ranking_change: Int
    public var name: String
    public var grade: String
    public var region: String
    public var country: String
    public var trueskill: Double
    public var ccwm: Double
    public var opr: Double
    public var dpr: Double
    public var ap_per_match: Double
    public var awp_per_match: Double
    public var wp_per_match: Double
    public var total_wins: Int
    public var total_losses: Int
    public var total_ties: Int
    public var elimination_wins: Int
    public var elimination_losses: Int
    public var elimination_ties: Int
    public var qualifier_wins: Int
    public var qualifier_losses: Int
    public var qualifier_ties: Int
    public var regionals_qualified: Bool
    public var worlds_qualified: Bool
    
    public init(data: [String: Any] = [:]) {
        self.id = (data["id"] != nil) ? data["id"] as! Int : 0
        self.team_number = (data["team_number"] != nil) ? data["team_number"] as! String : ""
        self.abs_ranking = (data["abs_ranking"] != nil) ? data["abs_ranking"] as! Int : 0
        self.trueskill_ranking = (data["trueskill_ranking"] != nil) ? data["trueskill_ranking"] as! Int : 0
        self.trueskill_ranking_change = (data["trueskill_ranking_change"] != nil) ? data["trueskill_ranking_change"] as! Int : 0
        self.name = (data["name"] != nil) ? data["name"] as! String : ""
        self.grade = (data["grade"] != nil) ? data["grade"] as! String : ""
        self.region = (data["region"] != nil) ? data["region"] as! String : ""
        self.country = (data["country"] != nil) ? data["country"] as! String : ""
        self.trueskill = (data["trueskill"] != nil) ? data["trueskill"] as! Double : 0.0
        self.ccwm = (data["ccwm"] != nil) ? data["ccwm"] as! Double : 0.0
        self.opr = (data["opr"] != nil) ? data["opr"] as! Double : 0.0
        self.dpr = (data["dpr"] != nil) ? data["dpr"] as! Double : 0.0
        self.ap_per_match = (data["ap_per_match"] != nil) ? data["ap_per_match"] as! Double : 0.0
        self.awp_per_match = (data["awp_per_match"] != nil) ? data["awp_per_match"] as! Double : 0.0
        self.wp_per_match = (data["wp_per_match"] != nil) ? data["wp_per_match"] as! Double : 0.0
        self.total_wins = (data["total_wins"] != nil) ? data["total_wins"] as! Int : 0
        self.total_losses = (data["total_losses"] != nil) ? data["total_losses"] as! Int : 0
        self.total_ties = (data["total_ties"] != nil) ? data["total_ties"] as! Int : 0
        self.elimination_wins = (data["elimination_wins"] != nil) ? data["elimination_wins"] as! Int : 0
        self.elimination_losses = (data["elimination_losses"] != nil) ? data["elimination_losses"] as! Int : 0
        self.elimination_ties = (data["elimination_ties"] != nil) ? data["elimination_ties"] as! Int : 0
        self.qualifier_wins = (data["qualifier_wins"] != nil) ? data["qualifier_wins"] as! Int : 0
        self.qualifier_losses = (data["qualifier_losses"] != nil) ? data["qualifier_losses"] as! Int : 0
        self.qualifier_ties = (data["qualifier_ties"] != nil) ? data["qualifier_ties"] as! Int : 0
        self.regionals_qualified = (data["regionals_qualified"] != nil) ? data["regionals_qualified"] as! Bool : false
        self.worlds_qualified = (data["worlds_qualified"] != nil) ? data["worlds_qualified"] as! Bool : false
    }
    
    public func toString() -> String {
        return String(format: "%@ #%d - %f", self.team_number, self.trueskill_ranking, self.trueskill)
    }
}

public class Division: Hashable {
    public var id: Int
    public var name: String
    
    public func hash(into hasher: inout Hasher) {
            hasher.combine(0)
        }
    
    public init(data: [String: Any] = [:]) {
        self.id = data["id"] as? Int ?? 0
        self.name = data["name"] as? String ?? ""
    }
    
    public init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
    
    public static func ==(lhs: Division, rhs: Division) -> Bool {
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
}

public class Match {
    public var id: Int
    public var event: Event
    public var division: Division
    public var field: String
    public var scheduled: Date?
    public var started: Date?
    public var matchnum: Int
    public var name: String
    public var blue_alliance: [Team]
    public var red_alliance: [Team]
    public var blue_score: Int
    public var red_score: Int
    
    public init(data: [String: Any] = [:], fetch: Bool = false) {

        self.id = (data["id"] != nil) ? data["id"] as? Int ?? 0 : 0
        self.event = (data["event"] != nil) ? Event(id: ((data["event"] as! [String: Any])["id"] as! Int), fetch: fetch) : Event(id: 0, fetch: false)
        self.division = (data["division"] != nil) ? Division(data: data["division"] as! [String : Any]) : Division()
        self.field = (data["field"] != nil) ? data["field"] as? String ?? "" : ""
        self.scheduled = (data["scheduled"] != nil) ? RoboScoutAPI.robotevents_date(date: data["scheduled"] as? String ?? "") : nil
        self.started = (data["started"] != nil) ? RoboScoutAPI.robotevents_date(date: data["started"] as? String ?? "") : nil
        self.matchnum = (data["matchnum"] != nil) ? data["matchnum"] as? Int ?? 0 : 0
        self.name = (data["name"] != nil) ? data["name"] as? String ?? "" : ""
        self.blue_alliance = [Team]()
        self.red_alliance = [Team]()
        self.blue_score = 0
        self.red_score = 0
        
        for alliance in (data["alliances"] != nil) ? data["alliances"] as! [[String: Any]] : [[String: Any]]() {
            if alliance["color"] as! String == "blue" {
                self.blue_score = alliance["score"] as? Int ?? -1
                
                for team in (alliance["teams"] != nil) ? alliance["teams"] as! [[String: Any]] : [[String: Any]]() {
                    self.blue_alliance.append(Team(id:(team["team"] as! [String: Any])["id"] as! Int, fetch: false))
                }
            }
            else {
                self.red_score = alliance["score"] as? Int ?? -1
                
                for team in (alliance["teams"] != nil) ? alliance["teams"] as! [[String: Any]] : [[String: Any]]() {
                    self.red_alliance.append(Team(id:(team["team"] as! [String: Any])["id"] as! Int, fetch: false))
                }
            }
        }
        while self.red_alliance.count < 2 {
            self.red_alliance.append(Team(id: 0, fetch: false))
        }
        while self.blue_alliance.count < 2 {
            self.blue_alliance.append(Team(id: 0, fetch: false))
        }
    }
    
    func fetch_full_info() {
        var blue_full = [Team]()
        var red_full = [Team]()
        
        for team in self.blue_alliance {
            blue_full.append(Team(id: team.id))
        }
        
        for team in self.red_alliance {
            red_full.append(Team(id: team.id))
        }
        
        self.blue_alliance = blue_full
        self.red_alliance = red_full
    }
    
    // Returns 0 for not found, 1 for red alliance, and 2 for blue alliance
    func alliance_for(team: Team) -> Int {
        for alliance_team in self.red_alliance {
            if alliance_team.id == team.id {
                return 1
            }
        }
        for alliance_team in self.blue_alliance {
            if alliance_team.id == team.id {
                return 2
            }
        }
        return 0
    }
    
    // Returns 0 for a tie, 1 for red alliance, and 2 for blue alliance
    func winning_alliance() -> Int {
        if self.red_score > self.blue_score {
            return 1
        }
        else if self.blue_score > self.red_score {
            return 2
        }
        else {
            return 0
        }
    }
    
    func toString() -> String {
        return "\(self.name) - \(self.red_score) to \(self.blue_score)"
    }
}

public class TeamRanking {
    public var id: Int
    public var team: Team
    public var event: Event
    public var division: Division
    public var rank: Int
    public var wins: Int
    public var losses: Int
    public var ties: Int
    public var wp: Int
    public var ap: Int
    public var sp: Int
    public var high_score: Int
    public var average_points: Double
    public var total_points: Int
    
    public init(data: [String: Any] = [:]) {
        self.id = data["id"] as? Int ?? 0
        self.team = Team(id: (data["team"] as? [String: Any] ?? [:])["id"] as? Int ?? 0, fetch: false)
        self.event = Event(id: (data["event"] as? [String: Any] ?? [:])["id"] as? Int ?? 0, fetch: false)
        self.division = Division(data: data["division"] as? [String: Any] ?? [:])
        self.rank = data["rank"] as? Int ?? -1
        self.wins = data["wins"] as? Int ?? -1
        self.losses = data["losses"] as? Int ?? -1
        self.ties = data["ties"] as? Int ?? -1
        self.wp = data["wp"] as? Int ?? -1
        self.ap = data["ap"] as? Int ?? -1
        self.sp = data["sp"] as? Int ?? -1
        self.high_score = data["high_score"] as? Int ?? -1
        self.average_points = data["average_points"] as? Double ?? -1.0
        self.total_points = data["total_points"] as? Int ?? -1
    }
}

public class TeamSkillsRanking {
    public var driver_id: Int = 0
    public var programming_id: Int = 0
    public var team: Team
    public var event: Event
    public var rank: Int
    public var combined_score: Int = 0
    public var driver_score: Int = 0
    public var programming_score: Int = 0
    public var driver_attempts: Int = 0
    public var programming_attempts: Int = 0
    
    public init(data: [[String: Any]] = [[:]]) {
        self.team = Team(id: (data[0]["team"] as? [String: Any] ?? [:])["id"] as? Int ?? 0, fetch: false)
        self.event = Event(id: (data[0]["event"] as? [String: Any] ?? [:])["id"] as? Int ?? 0, fetch: false)
        self.rank = data[0]["rank"] as? Int ?? 0
        for skills_type in data {
            if (skills_type["type"] as? String ?? "") == "driver" {
                self.driver_id = skills_type["id"] as? Int ?? 0
                self.driver_score = skills_type["score"] as? Int ?? 0
                self.driver_attempts = skills_type["attempts"] as? Int ?? 0
            }
            else if (skills_type["type"] as? String ?? "") == "programming" {
                self.programming_id = skills_type["id"] as? Int ?? 0
                self.programming_score = skills_type["score"] as? Int ?? 0
                self.programming_attempts = skills_type["attempts"] as? Int ?? 0
            }
        }
        self.combined_score = self.driver_score + self.programming_score
    }
}

public struct TeamPerformanceRatings {
    public var team: Team
    public var event: Event
    public var opr: Double
    public var dpr: Double
    public var ccwm: Double
}

public class Event {
    
    public var id: Int
    public var sku: String
    public var name: String
    public var start: Date?
    public var end: Date?
    public var season: Int
    public var city: String
    public var region: String
    public var country: String
    public var matches: [Division: [Match]]
    public var teams: [Team]
    public var teams_map: [Int: Team]
    public var team_performance_ratings: [Int: TeamPerformanceRatings]
    public var divisions: [Division]
    public var rankings: [Division: [TeamRanking]]
    public var skills_rankings: [TeamSkillsRanking]
    
    public init(id: Int = 0, sku: String = "", fetch: Bool = true, data: [String: Any] = [:]) {

        self.id = (data["id"] != nil) ? data["id"] as! Int : id
        self.sku = (data["sku"] != nil) ? data["sku"] as! String : sku
        self.name = (data["name"] != nil) ? data["name"] as! String : ""
        self.start = (data["start"] != nil) ? RoboScoutAPI.robotevents_date(date: data["start"] as! String) : nil
        self.end = (data["end"] != nil) ? RoboScoutAPI.robotevents_date(date: data["end"] as! String) : nil
        self.season = (data["season"] != nil) ? (data["season"] as! [String: Any])["id"] as! Int : 0
        self.city = (data["location"] != nil) ? ((data["location"] as! [String: Any])["city"] as? String ?? "") : ""
        self.region = (data["location"] != nil) ? ((data["location"] as! [String: Any])["region"] as? String ?? "") : ""
        self.country = (data["location"] != nil) ? ((data["location"] as! [String: Any])["country"] as? String ?? "") : ""
        self.matches = [Division: [Match]]()
        self.teams = [Team]()
        self.teams_map = [Int: Team]()
        self.team_performance_ratings = [Int: TeamPerformanceRatings]()
        self.divisions = [Division]()
        self.rankings = [Division: [TeamRanking]]()
        self.skills_rankings = [TeamSkillsRanking]()
        
        if data["divisions"] != nil {
            for division in (data["divisions"] as! [[String: Any]]) {
                self.divisions.append(Division(data: division))
            }
        }
        
        if fetch {
            self.fetch_info()
        }
    }
    
    public func fetch_info() {
        let data = RoboScoutAPI.robotevents_request(request_url: "/events/", params: self.id != 0 ? ["id": self.id] : ["sku": self.sku])
        if data.isEmpty {
            return
        }
        
        self.id = data[0]["id"] as? Int ?? 0
        self.sku = data[0]["sku"] as? String ?? ""
        self.name = data[0]["name"] as? String ?? ""
        self.start = RoboScoutAPI.robotevents_date(date: data[0]["start"] as? String ?? "")
        self.end = RoboScoutAPI.robotevents_date(date: data[0]["end"] as? String ?? "")
        self.season = (data[0]["season"] as! [String: Any])["id"] as? Int ?? 0
        self.city = (data[0]["location"] as! [String: Any])["city"] as? String ?? ""
        self.region = (data[0]["location"] as! [String: Any])["region"] as? String ?? ""
        self.country = (data[0]["location"] as! [String: Any])["country"] as? String ?? ""
        
        for division in (data[0]["divisions"] as! [[String: Any]]) {
            self.divisions.append(Division(data: division))
        }
    }
        
    public func fetch_teams() {
        self.teams = [Team]()
        let data = RoboScoutAPI.robotevents_request(request_url: String(format: "/events/%d/teams", self.id))
        for team in data {
            let cached_team = Team(id: team["id"] as! Int, fetch: false, data: team)
            self.teams.append(cached_team)
            self.teams_map[cached_team.id] = cached_team
        }
    }
    
    public func get_team(id: Int) -> Team? {
        return self.teams_map[id]
    }
    
    public func fetch_rankings(division: Division) {
        let data = RoboScoutAPI.robotevents_request(request_url: "/events/\(self.id)/divisions/\(division.id)/rankings")
        self.rankings[division] = [TeamRanking]()
        for ranking in data {
            var division_rankings = self.rankings[division] ?? [TeamRanking]()
            division_rankings.append(TeamRanking(data: ranking))
            self.rankings[division] = division_rankings
        }
    }
    
    public func fetch_skills_rankings() {
        let data = RoboScoutAPI.robotevents_request(request_url: "/events/\(self.id)/skills")
        var index = 0
        while index < data.count {
            var bundle = [data[index]]
            if (((index + 1) < data.count) && (data[index + 1]["team"] as! [String: Any])["id"] as! Int == (data[index]["team"] as! [String: Any])["id"] as! Int) {
                bundle.append(data[index + 1])
                index += 1
            }
            self.skills_rankings.append(TeamSkillsRanking(data: bundle))
            index += 1
        }
        
        // Remove all skills rankings with rank of 0
        self.skills_rankings = self.skills_rankings.filter({ $0.rank != 0 })
    }
    
    public func fetch_matches(division: Division) {
        let data = RoboScoutAPI.robotevents_request(request_url: "/events/\(self.id)/divisions/\(division.id)/matches")
        
        self.matches[division] = [Match]()
        
        var matches = [Match]()
        for match_data in data {
            matches.append(Match(data: match_data))
        }
        self.matches[division] = matches
    }
                
    public func toString() -> String {
        return String(format: "%@ %d", self.name, self.id)
    }
    
    public func calculate_team_performance_ratings(division: Division) {
        self.team_performance_ratings = [Int: TeamPerformanceRatings]()
        
        if self.teams.isEmpty {
            self.fetch_teams()
        }
        
        self.fetch_matches(division: division)
        
        var m = [[Int]]()
        var scores = [[Int]]()
        var margins = [[Int]]()
        
        var division_teams = [Team]()
        
        if !self.matches.keys.contains(division) {
            self.matches[division] = [Match]()
        }
        
        if self.matches[division]!.isEmpty {
            return
        }
        
        var added_teams = [Int]()
        for match in self.matches[division]! {
            var match_teams = [Team]()
            match_teams.append(contentsOf: match.red_alliance)
            match_teams.append(contentsOf: match.blue_alliance)
            for team in match_teams {
                if !added_teams.contains(team.id) && self.get_team(id: team.id) != nil {
                    division_teams.append(self.get_team(id: team.id)!)
                }
                added_teams.append(team.id)
            }
        }
        
        for match in self.matches[division]! {
            
            if !match.name.starts(with: "Qualifier") {
                continue
            }
                        
            var red = [Int]()
            var blue = [Int]()
            
            for team in division_teams {
                if match.red_alliance[0].id == team.id || match.red_alliance[1].id == team.id {
                    red.append(1)
                }
                else {
                    red.append(0)
                }
                if match.blue_alliance[0].id == team.id || match.blue_alliance[1].id == team.id {
                    blue.append(1)
                }
                else {
                    blue.append(0)
                }
            }
            m.append(red)
            m.append(blue)
            
            scores.append([match.red_score])
            scores.append([match.blue_score])
            margins.append([match.red_score - match.blue_score])
            margins.append([match.blue_score - match.red_score])
        }
        
        let mM = MfArray(m)
        let mScores = MfArray(scores)
        let mMargins = MfArray(margins)
        
        let pinv = try! Matft.linalg.pinv(mM)
        
        let mOPRs = Matft.matmul(pinv, mScores)
        let mCCWMs = Matft.matmul(pinv, mMargins)
        
        func convertToList(mfarray: MfArray) -> [Double] {
            var list = [Double]()
            for arr in mfarray.toArray() as! [[Float]] {
                for value in arr {
                    list.append(Double(value))
                }
            }
            return list
        }
        
        let OPRs = convertToList(mfarray: mOPRs)
        let CCWMs = convertToList(mfarray: mCCWMs)
        
        var i = 0
        for team in division_teams {
            self.team_performance_ratings[team.id] = TeamPerformanceRatings(team: team, event: self, opr: OPRs[i], dpr: OPRs[i] - CCWMs[i], ccwm: CCWMs[i])
            i += 1
        }
    }

}

public class EventSkills {
    
    public var team: Team
    public var event: Event
    public var driver: Int
    public var programming: Int
    public var combined: Int
    
    public init(team: Team, event: Event, driver: Int = 0, programming: Int = 0) {
        self.team = team
        self.event = event
        self.driver = driver
        self.programming = programming
        self.combined = driver + programming
    }
        
    public func toString() -> String {
        return String(format:"%@ @ %@ - %d", self.team.toString(), self.event.toString(), self.combined)
    }
}

public class WorldSkills {
    
    public var team: Team
    public var ranking: Int
    public var event: Event
    public var driver: Int
    public var programming: Int
    public var highest_driver: Int
    public var highest_programming: Int
    public var combined: Int
    
    public init(team: Team, data: [String: Any] = [:]) {
        if data["scores"] == nil {
            self.team = team
            self.ranking = 0
            self.event = Event(id: 0, fetch: false)
            self.driver = 0
            self.programming = 0
            self.highest_driver = 0
            self.highest_programming = 0
            self.combined = 0
            return
        }
        self.team = team
        self.ranking = (data["rank"] != nil) ? data["rank"] as! Int : 0
        self.event = (data["event"] != nil) ? Event(sku: (data["event"] as! [String: Any])["sku"] as! String) : Event(id: 0)
        self.driver = ((data["scores"] as! [String: Any])["driver"] != nil) ? (data["scores"] as! [String: Any])["driver"] as! Int : 0
        self.programming = ((data["scores"] as! [String: Any])["programming"] != nil) ? (data["scores"] as! [String: Any])["programming"] as! Int : 0
        self.highest_driver = ((data["scores"] as! [String: Any])["maxDriver"] != nil) ? (data["scores"] as! [String: Any])["maxDriver"] as! Int : 0
        self.highest_programming = ((data["scores"] as! [String: Any])["maxProgramming"] != nil) ? (data["scores"] as! [String: Any])["maxProgramming"] as! Int : 0
        self.combined = ((data["scores"] as! [String: Any])["score"] != nil) ? (data["scores"] as! [String: Any])["score"] as! Int : 0
    }
    
    public func toString() -> String {
        return String(format: "%@ #%d - %d", self.team.toString(), self.ranking, self.combined)
    }
}

public class Team {
    
    // RobotEvents API
    public var id: Int
    public var events: [Event]
    public var name: String
    public var number: String
    public var organization: String
    public var robot_name: String
    public var city: String
    public var region: String
    public var country: String
    public var grade: String
    public var registered: Bool
    
    public init(id: Int = 0, number: String = "", fetch: Bool = true, data: [String: Any] = [:]) {
        
        // RobotEvents API
        self.id = (data["id"] != nil) ? data["id"] as? Int ?? id : id
        self.events = (data["events"] != nil) ? data["events"] as? [Event] ?? [] : []
        self.name = (data["team_name"] != nil) ? data["team_name"] as? String ?? "" : ""
        self.number = (data["number"] != nil) ? data["number"] as? String ?? number : number
        self.organization = (data["organization"] != nil) ? data["organization"] as? String ?? "" : ""
        self.robot_name = (data["robot_name"] != nil) ? data["robot_name"] as? String ?? "" : ""
        self.city = (data["location"] != nil) ? ((data["location"] as! [String: Any])["city"] as? String ?? "") : ""
        self.region = (data["location"] != nil) ? ((data["location"] as! [String: Any])["region"] as? String ?? "") : ""
        self.country = (data["location"] != nil) ? ((data["location"] as! [String: Any])["country"] as? String ?? "") : ""
        self.grade = (data["grade"] != nil) ? data["grade"] as? String ?? "" : ""
        self.registered = (data["registered"] != nil) ? data["registered"] as? Bool ?? false : false
        
        if fetch {
            self.fetch_info()
        }
    }
    
    public func fetch_info() {
        
        let data = RoboScoutAPI.robotevents_request(request_url: "/teams", params: self.id != 0 ? ["id": self.id, "program": 1] : ["number": self.number, "program": 1])
        
        if data.count == 0 {
            return
        }
        
        // RobotEvents API
        self.id = data[0]["id"] as? Int ?? 0
        self.name = data[0]["team_name"] as? String ?? ""
        self.number = data[0]["number"] as? String ?? ""
        self.organization = data[0]["organization"] as? String ?? ""
        self.robot_name = data[0]["robot_name"] as? String ?? ""
        self.city = (data[0]["location"] as! [String: Any])["city"] as? String ?? ""
        self.country = (data[0]["location"] as! [String: Any])["country"] as? String ?? ""
        self.region = (data[0]["location"] as! [String: Any])["region"] as? String ?? self.country
        self.grade = data[0]["grade"] as? String ?? ""
        self.registered = data[0]["registered"] as? Bool ?? false
        
    }
    
    public func matches_at(event: Event) -> [Match] {
        let matches_data = RoboScoutAPI.robotevents_request(request_url: "/teams/\(self.id)/matches", params: ["event": event.id])
        var practice = [Match]()
        var qual = [Match]()
        var r32 = [Match]()
        var r16 = [Match]()
        var qf = [Match]()
        var sf = [Match]()
        var final = [Match]()
        
        for match_data in matches_data {
            let match = Match(data: match_data)
            let match_type = match.name.split(separator: " ")[0]
            
            if match_type == "Practice" {
                practice.append(match)
            }
            else if match_type == "Qualifier" {
                qual.append(match)
            }
            else if match_type == "R32" {
                r32.append(match)
            }
            else if match_type == "R16" {
                r16.append(match)
            }
            else if match_type == "QF" {
                qf.append(match)
            }
            else if match_type == "SF" {
                sf.append(match)
            }
            else if match_type == "Final" {
                final.append(match)
            }
        }
        
        var matches = [Match]()
        
        matches.append(contentsOf: practice)
        matches.append(contentsOf: qual)
        matches.append(contentsOf: r32)
        matches.append(contentsOf: r16)
        matches.append(contentsOf: qf)
        matches.append(contentsOf: sf)
        matches.append(contentsOf: final)
        
        return matches
    }
    
    public func fetch_events(season: Int? = nil) {
        let data = RoboScoutAPI.robotevents_request(request_url: "/events/", params: ["team": self.id, "season": season ?? RoboScoutAPI.selected_season_id()])
        for event in data {
            self.events.append(Event(id: event["id"] as! Int, fetch: false, data: event))
        }
    }
    
    public func skills_at(event: Event) -> EventSkills {
        let data = RoboScoutAPI.robotevents_request(request_url: String(format: "/events/%d/skills", event.id), params: ["team": self.id])
        
        var driver = 0
        var programming = 0
        
        for skills in data {
            if skills["type"] as! String == "driver" {
                driver = skills["score"] as! Int
            }
            else if skills["type"] as! String == "programming" {
                programming = skills["score"] as! Int
            }
        }
        
        return EventSkills(team: self, event: event, driver: driver, programming: programming)
    }
    
    public func average_ranking(season: Int? = nil) -> Double {
        let data = RoboScoutAPI.robotevents_request(request_url: String(format: "/teams/%d/rankings/", self.id), params: ["season": season ?? RoboScoutAPI.selected_season_id()])
        var total = 0
        for comp in data {
            total += comp["rank"] as! Int
        }
        return Double(total) / Double(data.count)
    }
                                        
    public func toString() -> String {
        return String(format: "%@ %@", self.name, self.number)
    }
}
