//
//  ColorDisplay.swift
//  Simon
//
//  Created by Aiden Baker on 9/5/25.
//

import SwiftUI

struct ColorDisplay: View {
    let color: Color
    var body: some View {
        RoundedRectangle(cornerRadius: 25.0)
            .fill(color)
            .frame(width: 100, height: 100, alignment: .center)
            .padding()
    }
}
