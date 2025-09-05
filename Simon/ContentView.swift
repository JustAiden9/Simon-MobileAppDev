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
    @State private var flash = [false, false, false, false]
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
                    .opacity(flash[0] ? 1 : 0.4)
                    .onTapGesture {
                        flashColorDisplay(index: 0)
                    }
                
                colorDisplay[1]
                    .opacity(flash[1] ? 1 : 0.4)
                    .onTapGesture {
                        flashColorDisplay(index: 1)
                    }
            }
            HStack {
                colorDisplay[2]
                    .opacity(flash[2] ? 1 : 0.4)
                    .onTapGesture {
                        flashColorDisplay(index: 2)
                    }
                colorDisplay[3]
                    .opacity(flash[3] ? 1 : 0.4)
                    .onTapGesture {
                        flashColorDisplay(index: 3)
                    }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    func flashColorDisplay(index: Int) {
        flash[index].toggle()
        withAnimation(.easeInOut(duration: 0.5)) {
            flash[index].toggle()
        }
    }
}

#Preview {
    ContentView()
}
