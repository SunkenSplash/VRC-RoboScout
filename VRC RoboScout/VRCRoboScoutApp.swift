//
//  VRCRoboScoutApp.swift
//  VRC RoboScout
//
//  Created by William Castro on 2/9/23.
//

import SwiftUI

let API = RoboScoutAPI()
let activities = RoboScoutActivityController()
let defaults = UserDefaults.standard

#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif

func displayRoundedTenths(number: Double) -> String {
    return String(format: "%.1f", round(number * 10.0) / 10.0)
}

func displayRounded(number: Double) -> String {
    return String(format: "%.0f", round(number))
}

extension String: Identifiable {
    public typealias ID = Int
    public var id: Int {
        return hash
    }
}

extension String {
    private static let slugSafeCharacters = CharacterSet(charactersIn: "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-")

    public func convertedToSlug() -> String? {
        if let latin = self.applyingTransform(StringTransform("Any-Latin; Latin-ASCII; Lower;"), reverse: false) {
            let urlComponents = latin.components(separatedBy: String.slugSafeCharacters.inverted)
            let result = urlComponents.filter { $0 != "" }.joined(separator: "-")

            if result.count > 0 {
                return result
            }
        }

        return nil
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

/// Detect a Shake gesture in SwiftUI
/// Based on https://stackoverflow.com/a/60085784/128083
struct ShakableViewRepresentable: UIViewControllerRepresentable {
    let onShake: () -> ()

    class ShakeableViewController: UIViewController {
        var onShake: (() -> ())?

        override func motionBegan(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
            if motion == .motionShake {
                onShake?()
            }
        }
    }

    func makeUIViewController(context: Context) -> ShakeableViewController {
        let controller = ShakeableViewController()
        controller.onShake = onShake
        return controller
    }
    
    func updateUIViewController(_ uiViewController: ShakeableViewController, context: Context) {}
}

extension View {
    func onShake(_ block: @escaping () -> Void) -> some View {
        overlay(
            ShakableViewRepresentable(onShake: block).allowsHitTesting(false)
        )
    }
}

extension UIApplication {
    static var appVersion: String? {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }
    static var appBuildNumber: String? {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
    }
}

extension Collection where Indices.Iterator.Element == Index {
    public subscript(safe index: Index) -> Iterator.Element? {
        return (startIndex <= index && index < endIndex) ? self[index] : nil
    }
}

struct LazyView<Content: View>: View {
    private let build: () -> Content

    init(_ build: @escaping () -> Content) {
        self.build = build
    }

    var body: Content {
        build()
    }
}

struct BulletList: View {
    var listItems: [String]
    var listItemSpacing: CGFloat? = nil
    var bullet: String = "•"
    var bulletWidth: CGFloat? = nil
    var bulletAlignment: Alignment = .leading
    
    var body: some View {
        VStack(alignment: .leading,
               spacing: listItemSpacing) {
            ForEach(listItems, id: \.self) { data in
                HStack(alignment: .top) {
                    Text(bullet)
                        .frame(width: bulletWidth,
                               alignment: bulletAlignment)
                    Text(data)
                        .frame(maxWidth: .infinity,
                               alignment: .leading)
                }
            }
        }
    }
}

struct NoData: View {
    var body: some View {
        VStack {
            Image(systemName: "xmark.bin.fill").font(.system(size: 30)).foregroundColor(.secondary)
            Spacer().frame(height: 5)
            Text("No data").foregroundColor(.secondary)
        }
    }
}

struct ImportingData: View {
    var body: some View {
        ProgressView().font(.system(size: 30)).tint(.secondary)
        Spacer().frame(height: 5)
        Text("Importing Data").foregroundColor(.secondary)
    }
}

class UserSettings: ObservableObject {
    private var colorString: String
    private var minimalistic: Bool
    private var adam_score: Bool
    private var grade_level: String
    private var performance_ratings_calculation_option: String
    private var team_info_default_page: String
    private var match_team_default_page: String
    private var selected_season_id: Int
    
    static var keyIndex = Int.random(in: 0..<10)
    
    init() {
        self.colorString = defaults.object(forKey: "color") as? String ?? UIColor.StringFromUIColor(color: .systemRed)
        defaults.object(forKey: "minimalistic") as? Int ?? 1 == 1 ? (self.minimalistic = true) : (self.minimalistic = false)
        defaults.object(forKey: "adam_score") as? Int ?? 1 == 1 ? (self.adam_score = true) : (self.adam_score = false)
        self.grade_level = defaults.object(forKey: "grade_level") as? String ?? "High School"
        self.performance_ratings_calculation_option = defaults.object(forKey: "performance_ratings_calculation_option") as? String ?? "real"
        self.team_info_default_page = defaults.object(forKey: "team_info_default_page") as? String ?? "events"
        self.match_team_default_page = defaults.object(forKey: "match_team_default_page") as? String ?? "matches"
        self.selected_season_id = defaults.object(forKey: "selected_season_id") as? Int ?? 181
    }
    
    func readUserDefaults() {
        self.colorString = defaults.object(forKey: "color") as? String ?? UIColor.StringFromUIColor(color: .systemRed)
        defaults.object(forKey: "minimalistic") as? Int ?? 1 == 1 ? (self.minimalistic = true) : (self.minimalistic = false)
        defaults.object(forKey: "adam_score") as? Int ?? 1 == 1 ? (self.adam_score = true) : (self.adam_score = false)
        self.grade_level = defaults.object(forKey: "grade_level") as? String ?? "High School"
        self.performance_ratings_calculation_option = defaults.object(forKey: "performance_ratings_calculation_option") as? String ?? "real"
        self.team_info_default_page = defaults.object(forKey: "team_info_default_page") as? String ?? "events"
        self.match_team_default_page = defaults.object(forKey: "match_team_default_page") as? String ?? "matches"
        self.selected_season_id = defaults.object(forKey: "selected_season_id") as? Int ?? API.selected_season_id()
    }
    
    func updateUserDefaults() {
        defaults.set(UIColor.StringFromUIColor(color: UIColor.UIColorFromString(string: self.colorString)), forKey: "color")
        defaults.set(self.minimalistic ? 1 : 0, forKey: "minimalistic")
        defaults.set(self.adam_score ? 1 : 0, forKey: "adam_score")
        defaults.set(self.grade_level, forKey: "grade_level")
        defaults.set(self.performance_ratings_calculation_option, forKey: "performance_ratings_calculation_option")
        defaults.set(self.team_info_default_page, forKey: "team_info_default_page")
        defaults.set(self.match_team_default_page, forKey: "match_team_default_page")
        defaults.set(self.selected_season_id, forKey: "selected_season_id")
    }
    
    func setColor(color: SwiftUI.Color) {
        self.colorString = UIColor.StringFromUIColor(color: UIColor(color))
    }
    
    func setMinimalistic(state: Bool) {
        self.minimalistic = state
    }
    
    func setAdamScore(state: Bool) {
        self.adam_score = state
    }
    
    func setGradeLevel(grade_level: String) {
        self.grade_level = grade_level
    }
    
    func setPerformanceRatingsCalculationOption(option: String) {
        self.performance_ratings_calculation_option = option
    }
    
    func setTeamInfoDefaultPage(page: String) {
        self.team_info_default_page = page
    }
    
    func setMatchTeamDefaultPage(page: String) {
        self.match_team_default_page = page
    }
    
    func setSelectedSeasonID(id: Int) {
        self.selected_season_id = id
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
        if defaults.object(forKey: "minimalistic") as? Int ?? 1 == 1 {
            return Color(UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0))
        }
        else {
            return self.accentColor()
        }
    }
    
    func navTextColor() -> SwiftUI.Color {
        if defaults.object(forKey: "minimalistic") as? Int ?? 1 == 1 {
            return accentColor()
        }
        else {
            return .white
        }
    }
    
    static func getRobotEventsAPIKey() -> String? {
        var robotevents_api_key: String? {
            if let environmentAPIKey = ProcessInfo.processInfo.environment["ROBOTEVENTS_API_KEY"] {
                defaults.set(environmentAPIKey, forKey: "robotevents_api_key")
                return environmentAPIKey
            }
            else if let defaultsAPIKey = defaults.object(forKey: "robotevents_api_key") as? String, !defaultsAPIKey.isEmpty {
                return defaultsAPIKey
            }
            else if let path = Bundle.main.path(forResource: "Config", ofType: "plist"), let config = NSDictionary(contentsOfFile: path) as? [String: Any] {
                return config["key\(self.keyIndex)"] as? String
            }
            return nil
        }
        return robotevents_api_key
    }
    
    static func getMinimalistic() -> Bool {
        return defaults.object(forKey: "minimalistic") as? Int ?? 1 == 1
    }
    
    static func getAdamScore() -> Bool {
        return defaults.object(forKey: "adam_score") as? Int ?? 1 == 1
    }
    
    static func getGradeLevel() -> String {
        return defaults.object(forKey: "grade_level") as? String ?? "High School"
    }
    
    static func getPerformanceRatingsCalculationOption() -> String {
        return defaults.object(forKey: "performance_ratings_calculation_option") as? String ?? "real"
    }
    
    static func getTeamInfoDefaultPage() -> String {
        return defaults.object(forKey: "team_info_default_page") as? String ?? "events"
    }
    
    static func getMatchTeamDefaultPage() -> String {
        return defaults.object(forKey: "match_team_default_page") as? String ?? "matches"
    }

    static func getSelectedSeasonID() -> Int {
        return defaults.object(forKey: "selected_season_id") as? Int ?? 181
    }
}

@main
struct VRCRoboScout: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject var favorites = FavoriteStorage(favorite_teams: defaults.object(forKey: "favorite_teams") as? [String] ?? [String](), favorite_events: defaults.object(forKey: "favorite_events") as? [String] ?? [String]())
    @StateObject var settings = UserSettings()
    @StateObject var dataController = RoboScoutDataController()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(favorites)
                .environmentObject(settings)
                .environmentObject(dataController)
                .tint(settings.accentColor())
                .onAppear{
                    #if DEBUG
                    print("Debug configuration")
                    #else
                    print("Release configuration")
                    #endif
                    DispatchQueue.global(qos: .userInteractive).async {
                        API.generate_season_id_map()
                        API.update_world_skills_cache()
                        API.update_vrc_data_analysis_cache()
                    }
                }
        }
    }
}
