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
    @State private var timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    @State private var sequence: [Int] = []
    @State private var index = 0
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
        .onReceive(timer) { _ in
            if index < sequence.count {
                flashColorDisplay(index: sequence[index])
                index += 1
            } else {
                index = 0
                let next = Int.random(in: 0...3)
                sequence.append(next)
            }
        }
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
