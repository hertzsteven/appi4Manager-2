//
//  BlockingOverlayView.swift
//  appi4Manager
//
//  Created by Steven Hertz on 6/5/23.
//

import SwiftUI

struct BlockingOverlayView: View {
    @Binding var isBlocking: Bool

    var body: some View {
        ZStack {
            if isBlocking {
                Color.black.opacity(0.2)
                    .edgesIgnoringSafeArea(.all)
                ProgressView("Updating . . .")
                    
            }
        }
        .allowsHitTesting(isBlocking)
        .scaleEffect(2.0) // This disables user interaction when overlay is visible
    }
}

struct BlockingOverlayView_Previews: PreviewProvider {
    static var previews: some View {
        BlockingOverlayView(isBlocking: .constant(true))
    }
}
