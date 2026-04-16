//
//  MetalView.swift
//  ImageFilterApp
//
//  Created by Takayuki Sakamoto on 2026/04/11.
//

import SwiftUI
import MetalKit

struct MetalView: UIViewRepresentable {
    var image: UIImage?
    var filter: FilterType
    var intensity: Float
    var showOriginal: Bool
    var splitPosition: Float
    var renderer: Renderer
    
    func makeCoordinator() -> Renderer {
        renderer
    }
    
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        
        mtkView.framebufferOnly = false
        
        mtkView.delegate = context.coordinator
        context.coordinator.mtkView = mtkView
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        context.coordinator.showOriginal = showOriginal
        context.coordinator.splitPosition = splitPosition
        
        context.coordinator.image = image
        context.coordinator.currentFilter = filter
        context.coordinator.adjustedIntensity = intensity
    }
    
    
    
}

/*
#Preview {
    MetalView()
}
*/
