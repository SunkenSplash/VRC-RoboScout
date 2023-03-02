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
    
    @EnvironmentObject var favorites: FavoriteTeams
    
    var team: FavoriteTeam

    var body: some View {
        Menu(team.number) {
            Button("View Info") {
                
            }
            Button("Remove Favorite") {
                favorites.favorite_teams.removeAll(where: {
                    $0.number == team.number
                })
            }
        }
    }
}

class FavoriteTeams: ObservableObject {
    @Published var favorite_teams: [FavoriteTeam]
    
    init(favorite_teams: [FavoriteTeam]) {
        self.favorite_teams = favorite_teams
    }
    
    public func as_array() -> [String] {
        var out_list = [String]()
        for team in self.favorite_teams {
            out_list.append(team.number)
        }
        return out_list
    }
}

struct Favorites: View {
    
    @EnvironmentObject var favorites: FavoriteTeams
    
    var body: some View {
        NavigationStack {
            VStack {
                List($favorites.favorite_teams) { team in
                    FavoriteRow(team: team.wrappedValue)
                        .environmentObject(favorites)
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
                .toolbarBackground(Color.accentColor, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

struct Favorites_Previews: PreviewProvider {
    static var previews: some View {
        Favorites()
    }
}
