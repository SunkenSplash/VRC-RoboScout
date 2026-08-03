//
//  ChangeAppIcon.swift
//  VRC RoboScout
//
//  Created by William Castro on 9/6/23.
//

import SwiftUI

enum AppIcon: String, CaseIterable, Identifiable {
    case primary = "AppIcon"
    case light = "AppIcon-Light"
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
    case cuties = "AppIcon-Cuties"
    case carbonfiber = "AppIcon-CarbonFiber"
    case century = "AppIcon-Century"
    case gremlin = "AppIcon-Gremlin"
    case illini = "AppIcon-ILLINI"
    case pt = "AppIcon-PT"
    case twenty11 = "AppIcon-2011"
    case launch = "AppIcon-LAUNCH"
    case photon = "AppIcon-Photon"
    case pinkhavoc = "AppIcon-PinkHavoc"
    case leopard = "AppIcon-Leopard"
    case tempest = "AppIcon-Tempest"
    case simple = "AppIcon-Simple"
    case pandascout = "AppIcon-PandaScout"
    case trash = "AppIcon-Trash"
    case kauz = "AppIcon-Kauz"
    case banga = "AppIcon-Banga"
    case phaseshift = "AppIcon-PhaseShift"
    case tv = "AppIcon-TV"
    case gulfracing = "AppIcon-GulfRacing"
    case gulfrobotics = "AppIcon-GulfRobotics"
    case blackout = "AppIcon-Blackout"
    case tigris = "AppIcon-Tigris"
    case blaze = "AppIcon-Blaze"
    case lum = "AppIcon-Lum"
    case alterego = "AppIcon-AlterEgo"
    case ki = "AppIcon-KI"
    case rvv = "AppIcon-RVV"
    case cw = "AppIcon-CW"
    case wonderland = "AppIcon-Wonderland"
    case saurus = "AppIcon-Saurus"
    case rsnet = "AppIcon-RSnet"
    case cartridge = "AppIcon-Cartridge"
    case inverted = "AppIcon-Inverted"
    case wakeup = "AppIcon-WakeUp"
    case nebula = "AppIcon-Nebula"
    case num = "AppIcon-Num"
    case amirite = "AppIcon-Amirite"
    case purble = "AppIcon-Purble"
    case riptide = "AppIcon-Riptide"
    case straitis = "AppIcon-Straitis"
    case plattifornia = "AppIcon-Plattifornia"
    case canes = "AppIcon-Canes"
    case roboreo = "AppIcon-Roboreo"
    case boogie = "AppIcon-Boogie"
    case mmtm = "AppIcon-Mmtm"
    case balls = "AppIcon-Balls"
    case fluid = "AppIcon-Fluid"
    case metal = "AppIcon-Metal"
    case sketchy = "AppIcon-Sketchy"
    case darkred = "AppIcon-DarkRed"
    case siege = "AppIcon-Siege"
    case kings = "AppIcon-Kings"
    case chunger = "AppIcon-Chunger"
    case bull = "AppIcon-Bull"
    case circuits = "AppIcon-Circuits"
    case gear = "AppIcon-Gear"
    case zigzag = "AppIcon-ZigZag"
    case ss = "AppIcon-SS"
    case cans = "AppIcon-CANs"
    case ranch = "AppIcon-Ranch"
    case bagel = "AppIcon-Bagel"
    case bigcheese = "AppIcon-BigCheese"
    case technapwn = "AppIcon-Technapwn"
    case minimater = "AppIcon-MiniMater"
    case avengineers = "AppIcon-Avengineers"
    case autumn = "AppIcon-Autumn"
    case canada = "AppIcon-Canada"
    case china = "AppIcon-China"
    case uk = "AppIcon-UK"
    case india = "AppIcon-India"
    case ll = "AppIcon-LL"
    case ww = "AppIcon-WW"
    case tesseract = "AppIcon-Tesseract"
    case gs = "AppIcon-GS"
    case tastefulgradient = "AppIcon-TastefulGradient"
    case havoc = "AppIcon-Havoc"
    case peak = "AppIcon-Peak"

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
            return "Liquid Glass/Adjusts to Home Screen"
        case .light:
            return "Light"
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
        case .cuties:
            return "Cuties/Henry 3142C"
        case .carbonfiber:
            return "Carbon Fiber/Jackpot 99904E"
        case .century:
            return "Century/Keily 8838B"
        case .gremlin:
            return "Gremlin/Gremlin 5203G"
        case .illini:
            return "ILLINI/Owen ILLINI"
        case .pt:
            return "Pronounce This/Pronounce This 2654P"
        case .twenty11:
            return "2011"
        case .launch:
            return "LAUNCH/2011"
        case .photon:
            return "Photon/Waluigi 1554P"
        case .pinkhavoc:
            return "Pink Havoc/Alex 98377H"
        case .leopard:
            return "Curious Leopard/26275A"
        case .tempest:
            return "Tempest/Patrick 6104G"
        case .simple:
            return "simple./Jonathan 293T"
        case .pandascout:
            return "PandaScout/Orange Chicken FRC 3792"
        case .trash:
            return "Trash/Caleb 106X"
        case .kauz:
            return "ROBOKAUZ/ROBOKAUZ 21417A"
        case .banga:
            return "Bangarang/Ailey 5956F"
        case .phaseshift:
            return "Phase Shift/Dane 1166P"
        case .tv:
            return "Terminal Velocity/Bryce 53171D"
        case .gulfracing:
            return "Gulf Racing/Thomas 74074X"
        case .gulfrobotics:
            return "Gulf Robotics/Thomas 74074X"
        case .blackout:
            return "Blackout/Neil 7405B"
        case .tigris:
            return "Tigris/Davis 98377G"
        case .blaze:
            return "Exothermic Blaze/Pepper 10B"
        case .lum:
            return "Luminous/VEXMEN: Luminous 91U"
        case .alterego:
            return "Alter Ego/Tyler Harpster"
        case .ki:
            return "Killer Instinct/Arnay 6842K"
        case .rvv:
            return "RVV/Emily 1082R"
        case .cw:
            return "Colorwave/Alex Y 877K"
        case .wonderland:
            return "Winter Wonderland/Sourya G"
        case .saurus:
            return "RoboSaurus/Selma 8079M"
        case .rsnet:
            return "RoboSource.net/Gencu 1051X"
        case .cartridge:
            return "Cartridge/Joseph 1970Y/RVRSE"
        case .inverted:
            return "Inverted/Derek 393Y"
        case .wakeup:
            return "Wake Up/Jack 5069W"
        case .nebula:
            return "Nebula/Neil 7405B"
        case .num:
            return "Numeric/Dennis 3110D"
        case .amirite:
            return "Amirite/Priyaan 8838D"
        case .purble:
            return "Purble Alliance/Leah 929T"
        case .riptide:
            return "Riptide/Yuvi 7405R"
        case .straitis:
            return "Straitis/Nooz 2088S"
        case .plattifornia:
            return "Plattifornia/Alex PLATT2"
        case .canes:
            return "RoboCanes/Henry 1970Y"
        case .roboreo:
            return "Roboreo/Asteri 1082E"
        case .boogie:
            return "Boogie/Chase 99904B"
        case .mmtm:
            return "MOMENTUM/Ivan 1064M"
        case .balls:
            return "Balls/Nathaniel 643A"
        case .fluid:
            return "Fluid/Catherine 20541B"
        case .metal:
            return "Metal/Catherine 20541B"
        case .sketchy:
            return "Sketchy/Arnay 6842K"
        case .darkred:
            return "Dark Red/Noah 19379B"
        case .siege:
            return "Siege/Gencu 1051X"
        case .kings:
            return "King's Robotics/Kevin 1831D"
        case .chunger:
            return "Chunger/Jason Chungus 8889A"
        case .bull:
            return "929HZR/Leah 929T"
        case .circuits:
            return "Circuits/Nathaniel 643A"
        case .gear:
            return "Knights/Ajaya R 8568A"
        case .zigzag:
            return "ZigZag/Quincy 68561Z"
        case .ss:
            return "Sunset/Andrew 4610C"
        case .cans:
            return "CANs/Zen 2158Z"
        case .ranch:
            return "RanchScout/Will BLRS"
        case .bagel:
            return "Bagel/Chase 99904B"
        case .bigcheese:
            return "Big Cheese/Isaac 96671A"
        case .technapwn:
            return "Technapwn/Adrian 2135A"
        case .minimater:
            return "MiniMater/Brayolay 94517A"
        case .avengineers:
            return "Avengineers/Praneeth 1155V"
        case .autumn:
            return "Autumn/Nathaniel 643A"
        case .canada:
            return "Canada/Abdur-Rahman 540W"
        case .china:
            return "China/Henry 62880A"
        case .uk:
            return "UK/Abhi 3327H"
        case .india:
            return "India/Dharm 79267V"
        case .ll:
            return "LemLib/Lem 1010N"
        case .ww:
            return "Worldwide/Maksym 8995B"
        case .tesseract:
            return "Tesseract/Jimmy 1166A"
        case .gs:
            return "Grayscale/Abhi 3327H"
        case .tastefulgradient:
            return "Tasteful Gradient/Neil 7405B"
        case .havoc:
            return "Havoc/ND 7405V"
        case .peak:
            return "Peak/Joseph 1970Y/RVRSE"
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
                print("Updating icon to \(String(describing: icon.iconName)) failed: \(error)")
                selectedAppIcon = previousAppIcon
            }
        }
    }
}

struct ChangeAppIcon: View {
    
    @EnvironmentObject var settings: UserSettings
    
    @StateObject var viewModel = ChangeAppIconModel()

    var body: some View {
        ZStack {
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
                                    Text(appIcon.description.split(separator: "/").dropFirst().joined(separator: "/")).foregroundColor(.secondary)
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
            VStack {
                Link("Submit your own!", destination: URL(string: "https://discord.gg/dae3Brb43N")!)
                    .padding()
                    .modify{ view in
                        if #available(iOS 26.0, *) {
                            view.buttonStyle(.glass)
                        }
                        else {
                            view.background(Color(UIColor.systemBackground).opacity(0.5), in: RoundedRectangle(cornerRadius: 100))
                        }
                    }
            }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding()
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
