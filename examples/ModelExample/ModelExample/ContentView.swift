//
//  ContentView.swift
//  ModelExample
//
//  Created by Roger D on 2025-04-29.
//

import SwiftUI

struct ContentView: View {
	var body: some View {
		// Simply embed MetalView and let it fill the screen
		MetalView()
			.ignoresSafeArea()  // Make it full-screen, if desired
	}
}
