//
//  Renderer.swift
//  ImageFilterApp
//
//  Created by Takayuki Sakamoto on 2026/04/11.
//

import Foundation
import MetalKit

class Renderer: NSObject, MTKViewDelegate {
    var device: MTLDevice!
    var commandQueue: MTLCommandQueue!
    var pipelineState: MTLRenderPipelineState!
    var pipelineStates: [FilterType: MTLRenderPipelineState] = [:]
    var currentFilter: FilterType = .grayscale
    var intensity: Float = 0.5
    var splitPosition: Float = 0.5
    var snapshotPipeline: MTLRenderPipelineState!
    var adjustedIntensity: Float = 1.0
    
    var image: UIImage? {
        didSet {
            loadTexture()
            createIntermediateTexture(size: imageSize)
        }
    }
    
    var texture: MTLTexture?
    weak var mtkView: MTKView?
    
    var imageSize: CGSize = .zero
    
    var blurHorizontalPipeline: MTLRenderPipelineState!
    var blurVerticalPipeline: MTLRenderPipelineState!
    var intermediateTexture: MTLTexture?
    
    var showOriginal: Bool = false
    
    var lastTexture: MTLTexture?
    var outputTexture: MTLTexture?
    
    override init() {
        super.init()
        device = MTLCreateSystemDefaultDevice()
        commandQueue = device.makeCommandQueue()
        setupPipeline()
    }
    
    let fullVertices: [Float] = [
        // x, y, z, w, u, v
        -1, -1, 0, 1, 0, 1,
         1, -1, 0, 1, 1, 1,
         -1,  1, 0, 1, 0, 0,
         1,  1, 0, 1, 1, 0,
    ]
    
    func setupPipeline() {
        let pixelFormat = mtkView?.colorPixelFormat ?? .bgra8Unorm
        let library = device.makeDefaultLibrary()
        let vertexFunc = library?.makeFunction(name: "vertexShader")
        
        let vertexDescriptor = MTLVertexDescriptor()
        
        // position(float4)
        vertexDescriptor.attributes[0].format = .float4
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0
        
        // texCoord(float2)
        vertexDescriptor.attributes[1].format = .float2
        vertexDescriptor.attributes[1].offset = MemoryLayout<Float>.size * 4
        vertexDescriptor.attributes[1].bufferIndex = 0
        
        // layout
        vertexDescriptor.layouts[0].stride = MemoryLayout<Float>.size * 6
        vertexDescriptor.layouts[0].stepFunction = .perVertex
        
        let hFunc = library?.makeFunction(name: "blurHorizontal")
        let vFunc = library?.makeFunction(name: "blurVertical")
        
        let desc = MTLRenderPipelineDescriptor()
        desc.vertexFunction = vertexFunc
        desc.fragmentFunction = hFunc
        desc.colorAttachments[0].pixelFormat = pixelFormat

        
        blurHorizontalPipeline = try! device.makeRenderPipelineState(descriptor: desc)
        
        desc.fragmentFunction = vFunc
        desc.fragmentFunction = hFunc
        
        blurVerticalPipeline = try! device.makeRenderPipelineState(descriptor: desc)
        
        
        for filter in FilterType.allCases {
            let fragmentName: String
            
            switch filter {
            case .grayscale:
                fragmentName = "grayscaleFragment"
            case .sepia:
                fragmentName = "sepiaFragment"
            case .blur:
                fragmentName = "blurFragment"
            case .normal:
                fragmentName = "normalFragment"
            }
            
            let fragmentfunc = library?.makeFunction(name: fragmentName)
            
            
            let descriptor = MTLRenderPipelineDescriptor()
            descriptor.vertexFunction = vertexFunc
            descriptor.fragmentFunction = fragmentfunc
            descriptor.colorAttachments[0].pixelFormat = pixelFormat
          
            
            desc.fragmentFunction = hFunc
            
            let state = try! device.makeRenderPipelineState(descriptor: descriptor)
            pipelineStates[filter] = state
            
            let snapshotDesc = MTLRenderPipelineDescriptor()
            snapshotDesc.vertexFunction = vertexFunc
            snapshotDesc.fragmentFunction = library?.makeFunction(name: "normalFragment")
            
            snapshotDesc.colorAttachments[0].pixelFormat = .bgra8Unorm
            
            snapshotPipeline = try! device.makeRenderPipelineState(descriptor: snapshotDesc)
            
        }
    }
    
    func loadTexture() {
        guard let image = image,
              let cgImage = image.cgImage else { return }
        
        imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        
        let loader = MTKTextureLoader(device: device)
        
        let options: [MTKTextureLoader.Option: Any] = [
            .SRGB: false
        ]
        
        texture = try? loader.newTexture(cgImage: cgImage, options: options)
    }
    
    func createIntermediateTexture(size: CGSize) {
        
        guard size.width > 0, size.height > 0 else {
            return
        }
        
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm,
            width: Int(size.width),
            height: Int(size.height),
            mipmapped: false
        )
        descriptor.usage = [.renderTarget, .shaderRead]
        
        intermediateTexture = device.makeTexture(descriptor: descriptor)
    }
    
    func draw(in view: MTKView) {
        
        guard let drawable = view.currentDrawable,
              let texture = texture else { return }
        
        let commandBuffer = commandQueue.makeCommandBuffer()!
        
        // 保存用テクスチャ
        let descripor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm,
            width: Int(view.drawableSize.width),
            height: Int(view.drawableSize.height),
            mipmapped: false
        )
        
        descripor.usage = [.renderTarget, .shaderRead]
        
        guard let outputTexture = device.makeTexture(descriptor: descripor) else { return }
        
        // 描画先(outputTexture)
        let pass = MTLRenderPassDescriptor()
        pass.colorAttachments[0].texture = outputTexture
        pass.colorAttachments[0].loadAction = .clear
        pass.colorAttachments[0].storeAction = .store
        
        let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: pass)!
        
        let filterToUse: FilterType = showOriginal ? .normal : currentFilter
        encoder.setRenderPipelineState(pipelineStates[filterToUse]!)
        
        encoder.setFragmentTexture(texture, index: 0)
        
        // 最小頂点
        let vertices: [Float] = [
            -1, -1, 0, 1, 0, 1,
             1, -1, 0, 1, 1, 1,
            -1,  1, 0, 1, 0, 0,
             1,  1, 0, 1, 1, 0
        ]
        
        encoder.setVertexBytes(vertices,
                               length: MemoryLayout<Float>.size * vertices.count,
                               index: 0)
        
        var intensity: Float = adjustedIntensity
        var split: Float = splitPosition
        
        encoder.setFragmentBytes(&split,
                                 length: MemoryLayout<Float>.size,
                                 index: 1)
        
        //encoder.setFragmentBytes(&intensity, length: 4, index: 0)
        var intensityValue = adjustedIntensity
        encoder.setFragmentBytes(&intensityValue,
                                 length: MemoryLayout<Float>.size,
                                 index: 0)
        
        encoder.setFragmentBytes(&split, length: 4, index: 1)
        
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        
        // 重要（無いと紫）
        encoder.setViewport(MTLViewport(
            originX: 0,
            originY: 0,
            width: Double(outputTexture.width),
            height: Double(outputTexture.height),
            znear: 0,
            zfar: 1
        ))
       
        encoder.setVertexBytes(vertices,
            length: MemoryLayout<Float>.size * vertices.count,
            index: 0)
        
        encoder.setFragmentBytes(&intensity, length: 4, index: 0)
        encoder.setFragmentBytes(&split, length: 4, index: 1)
        
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        encoder.endEncoding()
        
        // 保存用に保持
        lastTexture = outputTexture
        
        // 画面表示用（別でコピー）
        let blit = commandBuffer.makeBlitCommandEncoder()!
        blit.copy(from: outputTexture,
                  sourceSlice: 0,
                  sourceLevel: 0,
                  sourceOrigin: MTLOriginMake(0, 0, 0),
                  sourceSize: MTLSizeMake(outputTexture.width, outputTexture.height, 1),
                  to: drawable.texture,
                  destinationSlice: 0,
                  destinationLevel: 0,
                  destinationOrigin: MTLOriginMake(0, 0, 0))
        blit.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        createIntermediateTexture(size: view.drawableSize)
    }
    
    func snapshot() -> UIImage? {
        guard let texture = lastTexture else {
            print("no texture")
            return nil
        }
        
        let width = texture.width
        let height = texture.height
        
        let bytesPerRow = width * 4
        var bgraBytes = [UInt8](repeating: 0, count: Int(bytesPerRow * height))
        
        let region = MTLRegionMake2D(0, 0, width, height)
        texture.getBytes(&bgraBytes,
                         bytesPerRow: bytesPerRow,
                         from: region,
                         mipmapLevel: 0)
        
        let context = CGContext(data: &bgraBytes,
                                width: width,
                                height: height,
                                bitsPerComponent: 8,
                                bytesPerRow: bytesPerRow,
                                space: CGColorSpaceCreateDeviceRGB(),
                                bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue |
                                            CGBitmapInfo.byteOrder32Little.rawValue)
        
        guard let cgImage = context?.makeImage() else { return nil }
        
        return UIImage(cgImage: cgImage)
    }
    
    func saveCurrentFrame() {
        guard let image = snapshot() else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        print("保存完了")
    }
}
