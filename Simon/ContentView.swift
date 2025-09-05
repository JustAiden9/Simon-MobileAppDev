//
//  ContentView.swift
//  Simon
//
//  Created by Aiden Baker on 9/5/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            Text("Simon")
                .font(.system(size: 72, weight: .bold))
                .foregroundColor(.white)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
