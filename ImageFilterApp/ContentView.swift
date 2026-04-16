//
//  ContentView.swift
//  ImageFilterApp
//
//  Created by Takayuki Sakamoto on 2026/04/11.
//

import SwiftUI

struct ContentView: View {
    @State private var image: UIImage? = UIImage(named: "sample")
    @State private var selectedFilter: FilterType = .grayscale
    @State private var intensity: Float = 0.5
    @State private var showOriginal = false
    @State private var splitPosition: Float = 0.5
    @State private var renderer = Renderer()
    @State private var showSaveMessage = false
    
    var body: some View {
        VStack {
            if let image = image {
                MetalView(image: image,
                    filter: selectedFilter,
                    intensity: intensity,
                    showOriginal: showOriginal,
                    splitPosition: splitPosition,
                    renderer: renderer
                )
                    .frame(height: 300)
            }
            
            
            Picker("Filter", selection: $selectedFilter) {
                ForEach(FilterType.allCases.filter { $0 != .normal }, id: \.self) { filter in
                    Text(filter.rawValue)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            Text(selectedFilter.rawValue)
            
            VStack {
                Spacer()
                
                Image(uiImage: image!)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 250)
                
                Spacer()
                
                Button {
                } label: {
                    Label("画像を変更", systemImage: "photo")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Toggle("Before / After", isOn: $showOriginal)
                
                VStack(spacing: 16) {
                    VStack {
                        Text("Intensity")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                        Slider(value: Binding(
                            get: { Double(intensity) },
                            set: { intensity = Float($0) }
                        ), in: 0...1)
                        
                        Text(String(format: "%.2f", intensity))
                            .font(.subheadline)
                    }

                    
                        Text("Before ← → After")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.gray)
                
                        Slider(value: Binding (
                            get: { Double(splitPosition)},
                            set: { splitPosition = Float($0) }
                        ), in: 0...1)
                        
                        .onChange(of: selectedFilter) {
                            intensity = 0.5
                        }
                }
                .padding(.horizontal)
                
            }
            
            Button {
                renderer.saveCurrentFrame()
                
                showSaveMessage = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showSaveMessage = false
                }
            } label: {
                Label("保存", systemImage: "square.and.arrow.down")
            }
             
        }
        .overlay(
            VStack {
                if showSaveMessage {
                    Text("保存しました")
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .transition(.opacity)
                }
            }
                .animation(.easeInOut(duration: 0.3), value: showSaveMessage),
        )
    }
}

/*
#Preview {
    ContentView()
}
*/
