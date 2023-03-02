//
//  TrueSkill.swift
//  VRC RoboScout
//
//  Created by William Castro on 2/27/23.
//

import SwiftUI
import UniformTypeIdentifiers

struct TrueSkill: View {
    
    @State private var showImporter = false
    
    @EnvironmentObject var favorites: FavoriteTeams
    
    var body: some View {
        NavigationStack {
            VStack {
                Button("Import TrueSkill Data") {
                    showImporter = true
                }.fileImporter(
                    isPresented: $showImporter,
                    allowedContentTypes: [UTType("org.openxmlformats.spreadsheetml.sheet")!],
                    allowsMultipleSelection: false,
                    onCompletion: { result in
                        if let urls = try? result.get() {
                            do {
                                let url = urls[0]
                                guard url.startAccessingSecurityScopedResource() else { return }
                                API.update_vrc_data_analysis_cache(data: try Data(contentsOf: url))
                                url.stopAccessingSecurityScopedResource()
                            }
                            catch {
                                print("Invalid file at url \(urls[0])")
                            }
                        }
                    }
                  )
            }.background(.clear)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text("TrueSkill")
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

struct TrueSkill_Previews: PreviewProvider {
    static var previews: some View {
        TrueSkill()
    }
}

