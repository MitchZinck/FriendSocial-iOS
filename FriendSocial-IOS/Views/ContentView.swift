//
//  ContentView.swift
//  FriendSocial-iOS
//
//  Created by Mitchell Zinck on 2024-09-04.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var dataManager = DataManager.shared
    var body: some View {
        HomeView()
        .environmentObject(dataManager)
    }
}

#Preview {
    ContentView()
}
