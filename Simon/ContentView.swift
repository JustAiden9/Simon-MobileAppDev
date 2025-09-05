//
//  ContentView.swift
//  Simon
//
//  Created by Aiden Baker on 9/5/25.
//

import SwiftUI

struct ContentView: View {
    @State private var colorDisplay = [
        ColorDisplay(color: .green),
        ColorDisplay(color: .red),
        ColorDisplay(color: .yellow),
        ColorDisplay(color: .blue)
    ]
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            Text("simon")
                .font(.system(size: 72, weight: .bold))
                .foregroundColor(.white)
            
        }
        
        VStack {
            HStack {
                colorDisplay[0]
                colorDisplay[1]
            }
            HStack {
                colorDisplay[2]
                colorDisplay[3]
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
