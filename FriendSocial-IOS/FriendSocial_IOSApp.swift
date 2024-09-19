//
//  FriendSocial_IOSApp.swift
//  FriendSocial-IOS
//
//  Created by Mitchell Zinck on 2024-09-04.
//

import SwiftUI
extension Font {
    static func poppins(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        return Font.custom("Poppins-\(weight)", size: size)
    }
}

// Apply the font to the entire app
@main
struct FriendSocialApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(DataManager.shared)
                .font(.poppins(16)) // Set default font size to 16
        }
    }
}