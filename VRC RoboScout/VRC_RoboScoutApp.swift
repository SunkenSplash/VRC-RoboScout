//
//  VRC_RoboScoutApp.swift
//  VRC RoboScout
//
//  Created by William Castro on 2/9/23.
//

import SwiftUI

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
    private var selected_season_id: Int
    
    init() {
        self.colorString = defaults.object(forKey: "color") as? String ?? UIColor.StringFromUIColor(color: .systemRed)
        defaults.object(forKey: "minimalistic") as? Int ?? 1 == 1 ? (self.minimalistic = true) : (self.minimalistic = false)
        defaults.object(forKey: "adam_score") as? Int ?? 1 == 1 ? (self.adam_score = true) : (self.adam_score = false)
        self.selected_season_id = defaults.object(forKey: "selected_season_id") as? Int ?? 0
    }
    
    func readUserDefaults() {
        self.colorString = defaults.object(forKey: "color") as? String ?? UIColor.StringFromUIColor(color: .systemRed)
        defaults.object(forKey: "minimalistic") as? Int ?? 1 == 1 ? (self.minimalistic = true) : (self.minimalistic = false)
        defaults.object(forKey: "adam_score") as? Int ?? 1 == 1 ? (self.adam_score = true) : (self.adam_score = false)
        self.selected_season_id = defaults.object(forKey: "selected_season_id") as? Int ?? 0
    }
    
    func updateUserDefaults() {
        defaults.set(UIColor.StringFromUIColor(color: UIColor.UIColorFromString(string: self.colorString)), forKey: "color")
        defaults.set(self.minimalistic ? 1 : 0, forKey: "minimalistic")
        defaults.set(self.adam_score ? 1 : 0, forKey: "adam_score")
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
        defaults.set(self.adam_score ? 1 : 0, forKey: "adam_score")
    }

    func setSelectedSeasonID(id: Int) {
        self.selected_season_id = id
        defaults.set(self.selected_season_id, forKey: "selected_season_id")
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
            return Color(UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0))
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
    
    func getMinimalistic() -> Bool {
        return defaults.object(forKey: "minimalistic") as? Int ?? 1 == 1
    }
    
    func getAdamScore() -> Bool {
        return defaults.object(forKey: "adam_score") as? Int ?? 1 == 1
    }

    func getSelectedSeasonID() -> Int {
        return defaults.object(forKey: "selected_season_id") as? Int ?? 0
    }
}

@main
struct VRC_RoboScout: App {
    
    @StateObject var favorites = FavoriteStorage(favorite_teams: defaults.object(forKey: "favorite_teams") as? [String] ?? [String](), favorite_events: defaults.object(forKey: "favorite_events") as? [String] ?? [String]())
    @StateObject var settings = UserSettings()
    
    var body: some Scene {
        WindowGroup {
            Importer()
                .environmentObject(favorites)
                .environmentObject(settings)
                .tint(settings.accentColor())
        }
    }
}
