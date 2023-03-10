//
//  Favorites.swift
//  VRC RoboScout
//
//  Created by William Castro on 2/9/23.
//

import SwiftUI

struct FavoriteTeam: Identifiable {
    let id = UUID()
    let number: String
}

struct FavoriteRow: View {
    
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var favorites: FavoriteTeams
    
    var team: String

    var body: some View {
        Menu(team) {
            /*Button("View Info") {
                
            }*/
            Button("Remove Favorite") {
                favorites.favorite_teams.removeAll(where: {
                    $0 == team
                })
                favorites.sort()
                defaults.set(favorites.favorite_teams, forKey: "favorite_teams")
            }
        }
    }
}

class FavoriteTeams: ObservableObject {
    @Published var favorite_teams: [String]
    
    init(favorite_teams: [String]) {
        self.favorite_teams = favorite_teams.sorted()
    }
    
    public func as_array() -> [String] {
        var out_list = [String]()
        for team in self.favorite_teams {
            out_list.append(team)
        }
        return out_list
    }
    
    public func sort() {
        self.favorite_teams = self.favorite_teams.sorted()
    }
}

struct Favorites: View {
    
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var favorites: FavoriteTeams
        
    var body: some View {
        NavigationStack {
            Form {
                Section("Favorite Teams") {
                    List($favorites.favorite_teams) { team in
                        FavoriteRow(team: team.wrappedValue)
                            .environmentObject(favorites)
                    }
                }
            }.background(.clear)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("Favorites")
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

struct Favorites_Previews: PreviewProvider {
    static var previews: some View {
        Favorites()
    }
}
