//
//  ContentView.swift
//  TriangleExample
//
//  Created by Roger D on 2025-03-13.
//

import SwiftUI

struct ContentView: View {
	var body: some View {
		// Simply embed MetalView and let it fill the screen
		MetalView()
			.ignoresSafeArea()  // Make it full-screen, if desired
	}
}

