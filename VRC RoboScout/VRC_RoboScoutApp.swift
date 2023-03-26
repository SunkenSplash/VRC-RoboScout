//
//  VRC_RoboScoutApp.swift
//  VRC RoboScout
//
//  Created by William Castro on 2/9/23.
//

import SwiftUI
import CoreXLSX

let API = RoboScoutAPI()
let defaults = UserDefaults.standard

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif

func displayRoundedTenths(number: Double) -> String {
    return String(format: "%.1f", round(number * 10.0) / 10.0);
}

extension String: Identifiable {
    public typealias ID = Int
    public var id: Int {
        return hash
    }
}

public extension UIColor {

    class func StringFromUIColor(color: UIColor) -> String {
        let components = color.cgColor.components
        return "[\(components![0]), \(components![1]), \(components![2]), \(components![3])]"
    }
    
    class func UIColorFromString(string: String) -> UIColor {
        let componentsString = string.replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: "")
        let components = componentsString.components(separatedBy: ", ")
        return UIColor(red: CGFloat((components[0] as NSString).floatValue),
                     green: CGFloat((components[1] as NSString).floatValue),
                      blue: CGFloat((components[2] as NSString).floatValue),
                     alpha: CGFloat((components[3] as NSString).floatValue))
    }
    
}

struct CustomCenter: AlignmentID {
  static func defaultValue(in context: ViewDimensions) -> CGFloat {
    context[HorizontalAlignment.center]
  }
}

extension HorizontalAlignment {
  static let customCenter: HorizontalAlignment = .init(CustomCenter.self)
}

class UserSettings: ObservableObject {
    private var colorString: String
    private var minimalistic: Bool
    private var adam_score: Bool
    
    init() {
        self.colorString = defaults.object(forKey: "color") as? String ?? UIColor.StringFromUIColor(color: .systemRed)
        defaults.object(forKey: "minimalistic") as? Int ?? 0 == 1 ? (self.minimalistic = true) : (self.minimalistic = false)
        defaults.object(forKey: "adam_score") as? Int ?? 0 == 1 ? (self.adam_score = true) : (self.adam_score = false)
    }
    
    func readUserDefaults() {
        self.colorString = defaults.object(forKey: "color") as? String ?? UIColor.StringFromUIColor(color: .systemRed)
        defaults.object(forKey: "minimalistic") as? Int ?? 0 == 1 ? (self.minimalistic = true) : (self.minimalistic = false)
        defaults.object(forKey: "adam_score") as? Int ?? 0 == 1 ? (self.adam_score = true) : (self.adam_score = false)
    }
    
    func updateUserDefaults() {
        defaults.set(UIColor.StringFromUIColor(color: UIColor.UIColorFromString(string: self.colorString)), forKey: "color")
        defaults.set(self.minimalistic ? 1 : 0, forKey: "minimalistic")
        defaults.set(self.adam_score ? 1 : 0, forKey: "adam_score")
    }
    
    func setColor(color: SwiftUI.Color) {
        self.colorString = UIColor.StringFromUIColor(color: UIColor(color))
    }
    
    func setMinimalistic(state: Bool) {
        self.minimalistic = state
    }
    
    func setAdamScore(state: Bool) {
        self.adam_score = state
        defaults.set(self.adam_score ? 1 : 0, forKey: "adam_score")
    }
    
    func accentColor() -> SwiftUI.Color {
        if defaults.object(forKey: "color") as? String != nil {
            return Color(UIColor.UIColorFromString(string: defaults.object(forKey: "color") as! String))
        }
        else {
            return Color(UIColor.systemRed)
        }
        
    }
    
    func tabColor() -> SwiftUI.Color {
        if defaults.object(forKey: "minimalistic") as? Int ?? 0 == 1 {
            return Color(UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0))
        }
        else {
            return self.accentColor()
        }
    }
    
    func getMinimalistic() -> Bool {
        return defaults.object(forKey: "minimalistic") as? Int ?? 0 == 1
    }
    
    func getAdamScore() -> Bool {
        return defaults.object(forKey: "adam_score") as? Int ?? 0 == 1
    }
}

@main
struct VRC_RoboScout: App {
    
    @StateObject var favorites = FavoriteTeams(favorite_teams: defaults.object(forKey: "favorite_teams") as? [String] ?? [String]())
    @StateObject var settings = UserSettings()
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
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
                        .tint(settings.accentColor())
                    TeamLookup()
                        .tabItem {
                            if settings.getMinimalistic() {
                                Image(systemName: "magnifyingglass")
                            }
                            else {
                                Label("Team Lookup", systemImage: "magnifyingglass")
                            }
                        }
                        .environmentObject(favorites)
                        .environmentObject(settings)
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
                        .tint(settings.accentColor())
                }.tint(settings.accentColor())
            }
        }
    }
}

public class RoboScoutAPI {
    
    public var world_skills_cache: [[String: Any]]
    public var vrc_data_analysis_cache: [[String: Any]]
    
    public init() {
        self.world_skills_cache = [[String: Any]]()
        self.vrc_data_analysis_cache = [[String: Any]]()
    }
    
    public static func robotevents_url() -> String {
        return "https://www.robotevents.com/api/v2"
    }
    
    public static func vrc_data_analysis_url() -> String {
        return "http://vrc-data-analysis.com/v1"
    }
    
    public static func robotevents_access_key() -> String {
        return "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJhdWQiOiIzIiwianRpIjoiNThjYmZlOWI1ZWM3OTQ2OGM1M2EzNzViODIxOGRjNTUyZmNjZjRkYTcwNDQ3ZGQ5NGIwYTVjNzgzMDI4ZTI1YmI5MTE1M2ZhMTI4ZWVlNzYiLCJpYXQiOjE2NzU5NTcxNTMuMTc5NjgwMSwibmJmIjoxNjc1OTU3MTUzLjE3OTY4MywiZXhwIjoyNjIyNzI4MzUzLjE3MTcyLCJzdWIiOiI5NzI1NyIsInNjb3BlcyI6W119.IK6UM7wm0PEgQpKDgDnhhH2aSbJvLxwjx14VQG-me8zhT3StYoOGheNN01q7ANGI-1pPYVcydbewRF_enSjddUc7TlkG_qRl5DJV6m2qkC6hAsyTpRs7bMppJnmI9p1PKJ8ntizObwCC0H22JtH-xaKnpwOlcAsVWOiF9e_2GxfkjImpui8QTQ7ezjYJ269sPRdgHF9OdDlvXomSFq8JmaNSiuQX70mYOqyB18ZNHOq-owobBbnJZFJ7btIF9PERjaaM88DR_HKuX5gH8KSOhkSX3Lheslpo2cGo9RNqWXxdtWa-roXm-ZNIwThClIpytJWl1QX2S4VMKnEZS7EVdtP48OAm_E0VwdKVuG5-U151SmxFPzl9PEa7eXF2tIDnAHQItRg5l_6wEpwJIy9qkdOhLPRMf8wBv5lR4_SeWN0kz-BVy_EPNIQxXDRRG7-5yoTg5ABcoVVmNK32XEqpqquVpd8AYN0PXrzcSdHU3yUzM5gXBHknhyJFzwiFZOIRhiy2xb1E-6T_x2PZ3QiPVNfk9balZ0eWFAeLluyy60CrgHzlsFO-a0dsZZB0cEyMdw4jScZdNUH2vWRfPMwBllNRieTvs2xkxuATaCz1g8JjQzbjWcox68eXQFS5gtWIYY0w7j-eBrKiNPigL6CoFHG--KRBpqknj7rxS-YJqNA"
    }
    
    public static func robotevents_request(request_url: String, params: [String: Any] = [:]) -> [[String: Any]] {
        var data = [[String: Any]]()
        let request_url = self.robotevents_url() + request_url
        var page = 1
        var cont = true
        var params = params
        
        while cont {
            
            params["page"] = page
            
            let semaphore = DispatchSemaphore(value: 0)
            
            var components = URLComponents(string: request_url)!
            components.queryItems = params.map { (key, value) in
                URLQueryItem(name: key, value: String(describing: value))
            }
            
            let request = NSMutableURLRequest(url: components.url! as URL)
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
                    }
                } else if let error = error {
                    print("ERROR " + error.localizedDescription)
                }
            }
            task.resume()
            _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        }
        return data
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
                }
            } else if let error = error {
                print("ERROR " + error.localizedDescription)
            }
        }
        task.resume()
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        return data
    }
    
    public func update_world_skills_cache(season: Int = 173) -> Void {
        let semaphore = DispatchSemaphore(value: 0)
            
        let components = URLComponents(string: String(format: "https://www.robotevents.com/api/seasons/%d/skills", season))!
                    
        let request = NSMutableURLRequest(url: components.url! as URL)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) { (response_data, response, error) in
            if response_data != nil {
                do {
                    // Convert the data to JSON
                    let json = try JSONSerialization.jsonObject(with: response_data!) as? [[String: Any]]
                    
                    if json != nil {
                        self.world_skills_cache = json!
                        print("World skills cache updated")
                    }
                    else {
                        print("Failed to update world skills cache")
                    }
                    semaphore.signal()
                    

                }  catch let error as NSError {
                    print(error.localizedDescription)
                }
            } else if let error = error {
                print(error.localizedDescription)
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
                
    public func update_vrc_data_analysis_cache() -> Void {
        
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
                        
                        self.vrc_data_analysis_cache = self.vrc_data_analysis_cache.sorted(by: {
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
                }
            } else if let error = error {
                print(error.localizedDescription)
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
                }
            } else if let error = error {
                print(error.localizedDescription)
            }
        }
        task.resume()
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        
        return data
    }
    
    public func vrc_data_analysis_for(team: Team) -> VRCDataAnalysis {
        if self.vrc_data_analysis_cache.count == 0 {
            update_vrc_data_analysis_cache()
        }
        var vrc_data_analysis_data = [String: Any]()
        for vrc_data_analysis_entry in self.vrc_data_analysis_cache {
            if vrc_data_analysis_entry["id"] as! Int == team.id {
                vrc_data_analysis_data = vrc_data_analysis_entry
                break
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
public class Event {
    
    public var id: Int
    public var sku: String
    public var name: String
    public var start: String
    public var end: String
    public var season: Int
    public var city: String
    public var region: String
    public var country: String
    public var teams: [Team]
    
    public init(id: Int = 0, sku: String = "", fetch: Bool = true, data: [String: Any] = [:]) {
        self.id = (data["id"] != nil) ? data["id"] as! Int : id
        self.sku = (data["sku"] != nil) ? data["sku"] as! String : sku
        self.name = (data["name"] != nil) ? data["name"] as! String : ""
        self.start = (data["start"] != nil) ? data["start"] as! String : ""
        self.end = (data["end"] != nil) ? data["end"] as! String : ""
        self.season = (data["season"] != nil) ? (data["season"] as! [String: Any])["id"] as! Int : 0
        self.city = (data["city"] != nil) ? data["city"] as! String : ""
        self.region = (data["region"] != nil) ? data["region"] as! String : ""
        self.country = (data["country"] != nil) ? data["country"] as! String : ""
        self.teams = [Team]()
        
        if fetch {
            self.fetch_info()
        }
    }
    
    public func fetch_info() {
        let data = RoboScoutAPI.robotevents_request(request_url: "/events/", params: self.id != 0 ? ["id": self.id] : ["sku": self.sku])
        if data.isEmpty {
            return
        }
        self.id = data[0]["id"] as! Int
        self.sku = data[0]["sku"] as! String
        self.name = data[0]["name"] as! String
        self.start = data[0]["start"] as! String
        self.end = data[0]["end"] as! String
        self.season = (data[0]["season"] as! [String: Any])["id"] as! Int
        self.city = (data[0]["location"] as! [String: Any])["city"] as! String
        self.region = (data[0]["location"] as! [String: Any])["region"] as! String
        self.country = (data[0]["location"] as! [String: Any])["country"] as! String
    }
        
    public func fetch_teams() -> [Team] {
        let data = RoboScoutAPI.robotevents_request(request_url: String(format: "/events/%d/teams", self.id))
        for team in data {
            self.teams.append(Team(id: team["id"] as! Int, fetch: false, data: team))
        }
        return self.teams
    }
                
    public func toString() -> String {
        return String(format: "%@ %d", self.name, self.id)
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
        self.id = (data["id"] != nil) ? data["id"] as! Int : id
        self.events = (data["id"] != nil) ? data["events"] as! [Event] : []
        self.name = (data["name"] != nil) ? data["name"] as! String : ""
        self.number = (data["number"] != nil) ? data["number"] as! String : number
        self.organization = (data["name"] != nil) ? data["name"] as! String : ""
        self.robot_name = (data["robot_name"] != nil) ? data["robot_name"] as! String : ""
        self.city = (data["city"] != nil) ? data["city"] as! String : ""
        self.region = (data["region"] != nil) ? data["region"] as! String : ""
        self.country = (data["country"] != nil) ? data["country"] as! String : ""
        self.grade = (data["grade"] != nil) ? data["grade"] as! String : ""
        self.registered = (data["registered"] != nil) ? data["registered"] as! Bool : false
        
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
    
    public func fetch_events(season: Int = 173) {
        let data = RoboScoutAPI.robotevents_request(request_url: "/events/", params: ["team": self.id, "season": season])
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
    
    public func average_ranking(season: Int = 173) -> Double {
        let data = RoboScoutAPI.robotevents_request(request_url: String(format: "/teams/%d/rankings/", self.id), params: ["season": season])
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
