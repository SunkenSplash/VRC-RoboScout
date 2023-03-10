//
//  Settings.swift
//  VRC RoboScout
//
//  Created by William Castro on 3/3/23.
//

import SwiftUI

struct Settings: View {
    
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var favorites: FavoriteTeams
    @State var selected_color = UserSettings().accentColor()
    @State var minimalistic = defaults.object(forKey: "minimalistic") as? Int ?? 0 == 1 ? true : false
    @State var adam_score = defaults.object(forKey: "adam_score") as? Int ?? 0 == 1 ? true : false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Data Analysis") {
                    Toggle("AdamScore™", isOn: $adam_score).onChange(of: adam_score) { _ in
                        settings.setAdamScore(state: adam_score)
                    }
                }
                Section("Appearance") {
                    ColorPicker("Color", selection: $selected_color, supportsOpacity: false).onChange(of: selected_color) { _ in
                        settings.setColor(color: selected_color)
                    }
                    Toggle("Minimalistic", isOn: $minimalistic).onChange(of: minimalistic) { _ in
                        settings.setMinimalistic(state: minimalistic)
                    }
                    Button("Restart to apply") {
                        settings.updateUserDefaults()
                        print("App Restarting")
                        exit(0)
                    }
                }
                Section("Danger") {
                    Button("Clear favorites") {
                        defaults.set([String](), forKey: "favorite_teams")
                        favorites.favorite_teams = [String]()
                        print("Favorites cleared")
                    }
                    Button("Reset all data") {
                        let domain = Bundle.main.bundleIdentifier!
                        UserDefaults.standard.removePersistentDomain(forName: domain)
                        UserDefaults.standard.synchronize()
                        print("UserDefaults cleared")
                        exit(0)
                    }
                }
            }.background(.clear)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("Settings")
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

struct Settings_Previews: PreviewProvider {
    static var previews: some View {
        Settings()
    }
}
