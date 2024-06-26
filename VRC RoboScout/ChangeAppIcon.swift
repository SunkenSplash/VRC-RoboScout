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
    case delrin = "AppIcon-Delrin"
    case revision = "AppIcon-Revision"
    case sigbots = "AppIcon-SIGBots"
    case p = "AppIcon-P"
    case purple = "AppIcon-Purple"
    case aqua = "AppIcon-Aqua"
    case blue = "AppIcon-Blue"
    case cute = "AppIcon-Cute"
    case century = "AppIcon-Century"
    case pt = "AppIcon-PT"
    case twenty11 = "AppIcon-2011"
    case launch = "AppIcon-LAUNCH"
    case leopard = "AppIcon-Leopard"
    case tempest = "AppIcon-Tempest"
    case kauz = "AppIcon-Kauz"
    case banga = "AppIcon-Banga"
    case tv = "AppIcon-TV"
    case tigris = "AppIcon-Tigris"
    case lum = "AppIcon-Lum"
    case ki = "AppIcon-KI"
    case rvv = "AppIcon-RVV"
    case cw = "AppIcon-CW"
    case saurus = "AppIcon-Saurus"
    case rsnet = "AppIcon-RSnet"
    case num = "AppIcon-Num"
    case riptide = "AppIcon-Riptide"
    case straitis = "AppIcon-Straitis"
    case canes = "AppIcon-Canes"
    case boogie = "AppIcon-Boogie"
    case mmtm = "AppIcon-Mmtm"
    case balls = "AppIcon-Balls"
    case sketchy = "AppIcon-Sketchy"
    case siege = "AppIcon-Siege"
    case chunger = "AppIcon-Chunger"
    case bull = "AppIcon-Bull"
    case circuits = "AppIcon-Circuits"
    case gear = "AppIcon-Gear"
    case ss = "AppIcon-SS"
    case cans = "AppIcon-CANs"
    case ranch = "AppIcon-Ranch"
    case bagel = "AppIcon-Bagel"
    case autumn = "AppIcon-Autumn"
    case canada = "AppIcon-Canada"
    case uk = "AppIcon-UK"
    case india = "AppIcon-India"
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
        case .delrin:
            return "Delrin/ACE Robotics 229V"
        case .revision:
            return "Revision/Revision 515R"
        case .sigbots:
            return "Purdue SIGBots"
        case .p:
            return "Parker/Parker 9364C"
        case .purple:
            return "Purple/Angela 2029C"
        case .aqua:
            return "Aqua/Angela 2029C"
        case .blue:
            return "Blue/Angela 2029C"
        case .cute:
            return "Cute/Angela 2029C"
        case .century:
            return "Century/Keily 8838B"
        case .pt:
            return "Pronounce This/Pronounce This 2654P"
        case .twenty11:
            return "2011"
        case .launch:
            return "LAUNCH/2011"
        case .leopard:
            return "Curious Leopard/26275A"
        case .tempest:
            return "Tempest/Patrick 6104G"
        case .kauz:
            return "ROBOKAUZ/ROBOKAUZ 21417A"
        case .banga:
            return "Bangarang/Ailey 5956F"
        case .tv:
            return "Terminal Velocity/Bryce 53171D"
        case .tigris:
            return "Tigris/Davis 98377G"
        case .lum:
            return "Luminous/VEXMEN: Luminous 91U"
        case .ki:
            return "Killer Instinct/Arnay 6842K"
        case .rvv:
            return "RVV/Emily 1082R"
        case .cw:
            return "Colorwave/Alex Y 877K"
        case .saurus:
            return "RoboSaurus/Selma 8079M"
        case .rsnet:
            return "RoboSource.net/Gencu 1051X"
        case .num:
            return "Numeric/Dennis 3110D"
        case .riptide:
            return "Riptide/Yuvi 7405R"
        case .straitis:
            return "Straitis/Nooz 2088S"
        case .canes:
            return "RoboCanes/Henry 1970Y"
        case .boogie:
            return "Boogie/Chase 99904B"
        case .mmtm:
            return "MOMENTUM/Ivan 1064M"
        case .balls:
            return "Balls/Nathaniel 643A"
        case .sketchy:
            return "Sketchy/Arnay 6842K"
        case .siege:
            return "Siege/Gencu 1051X"
        case .chunger:
            return "Chunger/Jason Chungus 8889A"
        case .bull:
            return "929HZR/Leah 929T"
        case .circuits:
            return "Circuits/Nathaniel 643A"
        case .gear:
            return "Knights/Ajaya R 8568A"
        case .ss:
            return "Sunset/Andrew 4610C"
        case .cans:
            return "CANs/Zen 2158Z"
        case .ranch:
            return "RanchScout/Will BLRS"
        case .bagel:
            return "Bagel/Chase 99904B"
        case .autumn:
            return "Autumn/Nathaniel 643A"
        case .canada:
            return "Canada/Abdur-Rahman 540W"
        case .uk:
            return "UK/Abhi 3327H"
        case .india:
            return "India/Dharm 79267V"
        case .ll:
            return "LemLib/Lem 1010N"
        case .ww:
            return "Worldwide/Maksym 8995B"
        case .gs:
            return "Grayscale/Abhi 3327H"
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
            Link("Submit your own!", destination: URL(string: "https://discord.gg/dae3Brb43N")!).padding()
        }
        .background(.clear)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("App Icon")
                    .fontWeight(.medium)
                    .font(.system(size: 19))
                    .foregroundColor(settings.topBarContentColor())
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
