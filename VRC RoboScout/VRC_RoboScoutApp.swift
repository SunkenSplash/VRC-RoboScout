//
//  VRC_RoboScoutApp.swift
//  VRC RoboScout
//
//  Created by William Castro on 2/9/23.
//

import SwiftUI
import CoreXLSX

let API = RobotEventsAPI()

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif

@main
struct VRC_RoboScout: App {
    
    @StateObject var favorites = FavoriteTeams(favorite_teams: [
        FavoriteTeam(number: "2733J"),
        FavoriteTeam(number: "229V"),
        FavoriteTeam(number: "515R"),
        FavoriteTeam(number: "2775V")
    ])
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                TabView {
                    Favorites()
                        .tabItem {
                            Label("Favorites", systemImage: "star")
                                .foregroundColor(.red)
                        }.environmentObject(favorites)
                    WorldSkillsRankings()
                        .tabItem {
                            Label("World Skills", systemImage: "globe")
                                .foregroundColor(.red)
                        }.environmentObject(favorites)
                    TrueSkill()
                        .tabItem {
                            Label("TrueSkill", systemImage: "trophy")
                                .foregroundColor(.red)
                        }.environmentObject(favorites)
                    TeamLookup()
                        .tabItem {
                            Label("Team Lookup", systemImage: "magnifyingglass")
                                .foregroundColor(.red)
                        }.environmentObject(favorites)
                }
            }
        }
    }
}

public class RobotEventsAPI {
    
    public var world_skills_cache: [[String: Any]]
    public var vrc_data_analysis_cache: [String: Any]
    
    public init() {
        self.world_skills_cache = [[String: Any]]()
        self.vrc_data_analysis_cache = [String: Any]()
    }
    
    public static func url() -> String {
        return "https://www.robotevents.com/api/v2"
    }
    
    public static func access_key() -> String {
        return "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJhdWQiOiIzIiwianRpIjoiNThjYmZlOWI1ZWM3OTQ2OGM1M2EzNzViODIxOGRjNTUyZmNjZjRkYTcwNDQ3ZGQ5NGIwYTVjNzgzMDI4ZTI1YmI5MTE1M2ZhMTI4ZWVlNzYiLCJpYXQiOjE2NzU5NTcxNTMuMTc5NjgwMSwibmJmIjoxNjc1OTU3MTUzLjE3OTY4MywiZXhwIjoyNjIyNzI4MzUzLjE3MTcyLCJzdWIiOiI5NzI1NyIsInNjb3BlcyI6W119.IK6UM7wm0PEgQpKDgDnhhH2aSbJvLxwjx14VQG-me8zhT3StYoOGheNN01q7ANGI-1pPYVcydbewRF_enSjddUc7TlkG_qRl5DJV6m2qkC6hAsyTpRs7bMppJnmI9p1PKJ8ntizObwCC0H22JtH-xaKnpwOlcAsVWOiF9e_2GxfkjImpui8QTQ7ezjYJ269sPRdgHF9OdDlvXomSFq8JmaNSiuQX70mYOqyB18ZNHOq-owobBbnJZFJ7btIF9PERjaaM88DR_HKuX5gH8KSOhkSX3Lheslpo2cGo9RNqWXxdtWa-roXm-ZNIwThClIpytJWl1QX2S4VMKnEZS7EVdtP48OAm_E0VwdKVuG5-U151SmxFPzl9PEa7eXF2tIDnAHQItRg5l_6wEpwJIy9qkdOhLPRMf8wBv5lR4_SeWN0kz-BVy_EPNIQxXDRRG7-5yoTg5ABcoVVmNK32XEqpqquVpd8AYN0PXrzcSdHU3yUzM5gXBHknhyJFzwiFZOIRhiy2xb1E-6T_x2PZ3QiPVNfk9balZ0eWFAeLluyy60CrgHzlsFO-a0dsZZB0cEyMdw4jScZdNUH2vWRfPMwBllNRieTvs2xkxuATaCz1g8JjQzbjWcox68eXQFS5gtWIYY0w7j-eBrKiNPigL6CoFHG--KRBpqknj7rxS-YJqNA"
    }
    
    public static func paginated_request(request_url: String, params: [String: Any] = [:]) -> [[String: Any]] {
        var data = [[String: Any]]()
        let request_url = self.url() + request_url
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
            request.setValue(String(format: "Bearer %@", self.access_key()), forHTTPHeaderField: "Authorization")
            request.httpMethod = "GET"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let task = URLSession.shared.dataTask(with: request as URLRequest) { (response_data, response, error) in
                if response_data != nil {
                    do {
                        print(String(format: "API request (page %d): %@", page, components.url?.description ?? request_url))
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
    
    public func update_world_skills_cache(season: Int = 173) -> Void {
        let semaphore = DispatchSemaphore(value: 0)
            
        let components = URLComponents(string: String(format:"https://www.robotevents.com/api/seasons/%d/skills", season))!
                    
        let request = NSMutableURLRequest(url: components.url! as URL)
        request.setValue(String(format: "Bearer %@", RobotEventsAPI.access_key()), forHTTPHeaderField: "Authorization")
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
                
    public func update_vrc_data_analysis_cache(data: Data) -> Void {
        var file: XLSXFile
        do {
            file = try XLSXFile(data: data)
        }
        catch {
            print("XLSX data is invalid")
            return
        }
        do {
            let wb = try file.parseWorkbooks()[0]
            let ws = try file.parseWorksheet(at: try file.parseWorksheetPathsAndNames(workbook: wb)[0].path)
            for row in ws.data?.rows ?? [] {
                if row.cells.count < 12 {
                    continue
                }
                self.vrc_data_analysis_cache[row.cells[3].value!] = [
                    "tsranking": row.cells[0].value!,
                    "tsranking_change": row.cells[1].value!,
                    "name": row.cells[4].value!,
                    "region": row.cells[5].value!,
                    "country": row.cells[6].value!,
                    "trueskill": row.cells[7].value!,
                    "ccwm": row.cells[8].value!,
                    "total_wins": row.cells[9].value!,
                    "total_losses": row.cells[10].value!,
                    "total_ties": row.cells[11].value!
                ]
            }
        } catch {
            print("Error opening worksheet")
        }
        print("Updated VRC Data Analysis cache")
    }
    
    public func vrc_data_analysis_for(team: Team) -> VRCDataAnalysis {
        if self.vrc_data_analysis_cache.count == 0 {
            return VRCDataAnalysis(team: team)
        }
        return VRCDataAnalysis(team: team, data: self.vrc_data_analysis_cache[team.number] as! [String : Any])
    }
    
}
        
public class VRCDataAnalysis {
    
    public var team: Team
    public var tsranking: Int
    public var tsranking_change: Int
    public var name: String
    public var region: String
    public var country: String
    public var trueskill: Double
    public var ccwm: Double
    public var total_wins: Int
    public var total_losses: Int
    public var total_ties: Int
    
    public init(team: Team, data: [String: Any] = [:]) {
        self.team = team
        self.tsranking = (data["tsranking"] != nil) ? Int(data["tsranking"] as! String)! : 0
        self.tsranking_change = (data["tsranking_change"] != nil) ? Int(data["tsranking_change"] as! String)! : 0
        self.name = (data["name"] != nil) ? data["name"] as! String : ""
        self.region = (data["region"] != nil) ? data["region"] as! String : ""
        self.country = (data["country"] != nil) ? data["country"] as! String : ""
        self.trueskill = (data["trueskill"] != nil) ? Double(data["trueskill"] as! String)! : 0.0
        self.ccwm = (data["ccwm"] != nil) ? Double(data["ccwm"] as! String)! : 0.0
        self.total_wins = (data["total_wins"] != nil) ? Int(data["total_wins"] as! String)! : 0
        self.total_losses = (data["total_losses"] != nil) ? Int(data["total_losses"] as! String)! : 0
        self.total_ties = (data["total_ties"] != nil) ? Int(data["total_ties"] as! String)! : 0
    }
    
    public func toString() -> String {
        return String(format: "%@ #%d - %f", self.team.toString(), self.tsranking, self.trueskill)
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
        let data = RobotEventsAPI.paginated_request(request_url: "/events/", params: self.id != 0 ? ["id": self.id] : ["sku": self.sku])
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
        let data = RobotEventsAPI.paginated_request(request_url: String(format: "/events/%d/teams", self.id))
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
        
        let data = RobotEventsAPI.paginated_request(request_url: "/teams", params: self.id != 0 ? ["id": self.id, "program": 1] : ["number": self.number, "program": 1])
        
        if data.count == 0 {
            return
        }
        
        self.id = data[0]["id"] as! Int
        self.name = data[0]["team_name"] as! String
        self.number = data[0]["number"] as! String
        self.organization = data[0]["organization"] as! String
        self.robot_name = data[0]["robot_name"] as! String
        self.city = (data[0]["location"] as! [String: Any])["city"] as! String
        self.region = (data[0]["location"] as! [String: Any])["region"] as! String
        self.country = (data[0]["location"] as! [String: Any])["country"] as! String
        self.grade = data[0]["grade"] as! String
        self.registered = data[0]["registered"] as! Bool
    }
    
    public func fetch_events(season: Int = 173) {
        let data = RobotEventsAPI.paginated_request(request_url: "/events/", params: ["team": self.id, "season": season])
        for event in data {
            self.events.append(Event(id: event["id"] as! Int, fetch: false, data: event))
        }
    }
    
    public func skills_at(event: Event) -> EventSkills {
        let data = RobotEventsAPI.paginated_request(request_url: String(format: "/events/%d/skills", event.id), params: ["team": self.id])
        
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
        let data = RobotEventsAPI.paginated_request(request_url: String(format: "/teams/%d/rankings/", self.id), params: ["season": season])
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
