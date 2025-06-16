//
//  The_DarkApp.swift
//  The Dark
//
//  Created by Shivansh Gaur on 13/06/25.
//

import SwiftUI

@main
struct The_DarkApp: App {
    @State private var showSplash = true
    
    var body: some Scene {
        WindowGroup {
            Group {
                if showSplash {
                    SplashScreenView(showSplash: $showSplash)
                } else {
                    MainInteractionView()
                }
            }
            .preferredColorScheme(.light)
        }
    }
}
