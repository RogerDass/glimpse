//
//  ContentView.swift
//  ShaderExample
//
//  Created by Roger D on 2025-07-07.
//

import SwiftUI


struct ContentView: View {
	@StateObject private var vm = ShaderEditorViewModel()

	var body: some View {
		HStack(spacing: 0) {

			// Left half: Metal view
			MetalView(renderer: vm.renderer)
				.frame(maxWidth: .infinity, maxHeight: .infinity)

			// Right half: editor + button
			VStack(alignment: .leading, spacing: 8) {
				Text("Shader Source")
					.font(.headline)
					.padding(.top, 8)
					.padding(.horizontal, 8)

				TextEditor(text: $vm.shaderCode)
					.font(.system(.body, design: .monospaced))
					.frame(maxWidth: .infinity, maxHeight: .infinity)
					.scrollContentBackground(.hidden)
					.background(RoundedRectangle(cornerRadius: 4).fill(Color(white: 0.2)))
					.overlay(RoundedRectangle(cornerRadius: 4)
					.stroke(Color.secondary, lineWidth: 1))
					.padding(.horizontal, 8)

				Button("Compile & Apply") {
					vm.compileAndApplyShader()
				}
				.padding(.bottom, 8)
				.frame(maxWidth: .infinity)
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.background(Color(white: 0.4))
		}
		.onAppear {
			vm.compileAndApplyShader() // compile and swap in shader/PSO on first appearance of view
		}
#if os(iOS) || os(tvOS)
		.toolbar {
			ToolbarItemGroup(placement: .keyboard) {
				Spacer()
				Button("Done") {
					// dismiss
					UIApplication.shared.sendAction(
						#selector(UIResponder.resignFirstResponder),
						to: nil, from: nil, for: nil
					)
				}
			}
		}
#endif
	}
}
