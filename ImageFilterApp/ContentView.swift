//
//  ContentView.swift
//  ImageFilterApp
//
//  Created by Takayuki Sakamoto on 2026/04/11.
//

import SwiftUI
import PhotosUI

struct ContentView: View {
    //@State private var image: UIImage? = UIImage(named: "sample")
    @State private var selectedFilter: FilterType = .grayscale
    @State private var intensity: Float = 0.5
    @State private var showOriginal = false
    @State private var splitPosition: Float = 0.5
    @State private var renderer = Renderer()
    @State private var showSaveMessage = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var image: UIImage?
    
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
                
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 250)
                }
                
                Spacer()
                
                /*
                if let image = image {
                    Image(uiImage: image)
                } else {
                    Text("画像を選択してください")
                }
                */
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Label("画像を選択してください", systemImage: "photo")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                .onChange(of: selectedItem) { newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            
                            image = uiImage.normalized()
                        }
                    }
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

extension UIImage {
    func normalized() -> UIImage {
        if imageOrientation == .up { return self }
        
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return normalizedImage ?? self
    }
}

/*
#Preview {
    ContentView()
}
*/
