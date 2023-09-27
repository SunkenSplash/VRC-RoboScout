//
//  ChangeAppIcon.swift
//  VRC RoboScout
//
//  Created by William Castro on 9/6/23.
//

import SwiftUI

enum AppIcon: String, CaseIterable, Identifiable {
    case primary = "AppIcon"
    case dark = "AppIcon-Dark"
    case ace = "AppIcon-ACE"
    case revision = "AppIcon-Revision"
    case p = "AppIcon-P"
    case cw = "AppIcon-CW"
    case ss = "AppIcon-SS"
    case canada = "AppIcon-Canada"
    case ll = "AppIcon-LL"
    case ww = "AppIcon-WW"
    case gs = "AppIcon-GS"

    var id: String { rawValue }
    var iconName: String? {
        switch self {
        case .primary:
            return nil
        default:
            return rawValue
        }
    }

    var description: String {
        switch self {
        case .primary:
            return "Default"
        case .dark:
            return "Dark"
        case .ace:
            return "ACE/ACE Robotics 229V"
        case .revision:
            return "Revision/Revision 515R"
        case .p:
            return "Parker/Parker 9364C"
        case .cw:
            return "Colorwave/Alex Y 877K"
        case .ss:
            return "Sunset/Andrew 4610C"
        case .canada:
            return "Canada/Abdur-Rahman 540W"
        case .ll:
            return "LemLib/Lem 1010N"
        case .ww:
            return "Worldwide/Maksym 8995B"
        case .gs:
            return "Grayscale/leader 3327H"
        }
    }

    var preview: UIImage {
        UIImage(named: rawValue + "-Preview") ?? UIImage()
    }
}

final class ChangeAppIconModel: ObservableObject {

    @Published private(set) var selectedAppIcon: AppIcon

    init() {
        if let iconName = UIApplication.shared.alternateIconName, let appIcon = AppIcon(rawValue: iconName) {
            selectedAppIcon = appIcon
        } else {
            selectedAppIcon = .primary
        }
    }

    func updateAppIcon(to icon: AppIcon) {
        let previousAppIcon = selectedAppIcon
        selectedAppIcon = icon

        Task { @MainActor in
            guard UIApplication.shared.alternateIconName != icon.iconName else {
                return
            }

            do {
                try await UIApplication.shared.setAlternateIconName(icon.iconName)
            } catch {
                print("Updating icon to \(String(describing: icon.iconName)) failed.")
                selectedAppIcon = previousAppIcon
            }
        }
    }
}

struct ChangeAppIcon: View {
    
    @EnvironmentObject var settings: UserSettings
    
    @StateObject var viewModel = ChangeAppIconModel()

    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 11) {
                    ForEach(AppIcon.allCases) { appIcon in
                        HStack(spacing: 16) {
                            Image(uiImage: appIcon.preview)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 60, height: 60)
                                .cornerRadius(12)
                            VStack(alignment: .leading) {
                                Text(appIcon.description.split(separator: "/")[0])
                                if appIcon.description.contains("/") {
                                    Text(appIcon.description.split(separator: "/")[1]).foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            if viewModel.selectedAppIcon == appIcon {
                                Image(systemName: "checkmark")
                            }
                        }
                        .padding(EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16))
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(20)
                        .onTapGesture {
                            withAnimation {
                                viewModel.updateAppIcon(to: appIcon)
                            }
                        }
                    }
                }.padding(.horizontal)
                    .padding(.vertical, 40)
            }
            Link("Submit your own!", destination: URL(string: "https://discord.gg/7b9qcMhVnW")!).padding()
        }
        .background(.clear)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("App Icon")
                    .fontWeight(.medium)
                    .font(.system(size: 19))
                    .foregroundColor(settings.navTextColor())
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(settings.tabColor(), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

struct ChangeAppIcon_Previews: PreviewProvider {
    static var previews: some View {
        ChangeAppIcon()
    }
}
