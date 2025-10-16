//
//  Grid3D.swift
//  MetalSCene2D&3D
//
//  Created by Miguel Carlos Elizondo Mrtinez on 15/10/25.
//

// Grid3D.swift
import Metal
import simd
import MetalKit

public struct GridUniforms {
    public var mvp: simd_float4x4
    public init(mvp: simd_float4x4) { self.mvp = mvp }
}

public final class Grid3D {
    private let device: MTLDevice
    private let pipeline: MTLRenderPipelineState
    private let depthState: MTLDepthStencilState
    private var vbuf: MTLBuffer
    private var vertexCount: Int = 0

    public var spacing: Float
    public var halfLines: Int
    public var axisLength: Float

    public init(device: MTLDevice,
                library: MTLLibrary,
                spacing: Float = 1.0,
                halfLines: Int = 10,
                axisLength: Float = 50.0) throws
    {
        self.device = device
        self.spacing = spacing
        self.halfLines = halfLines
        self.axisLength = axisLength

        // pipeline simple con color por vértice
        let desc = MTLRenderPipelineDescriptor()
        desc.vertexFunction = library.makeFunction(name: "vtx_color3d")
        desc.fragmentFunction = library.makeFunction(name: "frag_color")
        desc.colorAttachments[0].pixelFormat = .bgra8Unorm
        desc.depthAttachmentPixelFormat = .depth32Float
        pipeline = try device.makeRenderPipelineState(descriptor: desc)

        let depthDesc = MTLDepthStencilDescriptor()
        depthDesc.isDepthWriteEnabled = false
        depthDesc.depthCompareFunction = .lessEqual
        depthState = device.makeDepthStencilState(descriptor: depthDesc)!

        // construimos el buffer de líneas
        let verts = Grid3D.buildVertices(spacing: spacing, half: halfLines, axisLength: axisLength)
        vertexCount = verts.count
        vbuf = device.makeBuffer(bytes: verts,
                                 length: MemoryLayout<Vertex>.stride * verts.count,
                                 options: [.storageModeShared])!
    }

    public func draw(encoder: MTLRenderCommandEncoder, mvp: simd_float4x4) {
        encoder.setRenderPipelineState(pipeline)
        encoder.setDepthStencilState(depthState)
        encoder.setVertexBuffer(vbuf, offset: 0, index: 0)

        var u = GridUniforms(mvp: mvp)
        encoder.setVertexBytes(&u, length: MemoryLayout<GridUniforms>.stride, index: 1)
        encoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: vertexCount)
    }

    // MARK: - Internos

    private struct Vertex {
        var position: simd_float3
        var color: simd_float4
    }

    private static func buildVertices(spacing: Float, half: Int, axisLength: Float) -> [Vertex] {
        var v: [Vertex] = []
        let n = half
        let s = spacing

        // color grid tenue
        let gridColor = simd_float4(0.35, 0.35, 0.35, 1.0)
        let majorColor = simd_float4(0.55, 0.55, 0.55, 1.0)

        // Líneas paralelas al eje X (variando Z)
        for i in -n...n {
            let z = Float(i) * s
            let c = (i % 5 == 0) ? majorColor : gridColor
            v.append(Vertex(position: [ -Float(n)*s, 0, z ], color: c))
            v.append(Vertex(position: [  Float(n)*s, 0, z ], color: c))
        }

        // Líneas paralelas al eje Z (variando X)
        for i in -n...n {
            let x = Float(i) * s
            let c = (i % 5 == 0) ? majorColor : gridColor
            v.append(Vertex(position: [ x, 0, -Float(n)*s ], color: c))
            v.append(Vertex(position: [ x, 0,  Float(n)*s ], color: c))
        }

        // Ejes (más brillantes)
        let xColor = simd_float4(1, 0.2, 0.2, 1)   // X rojo
        let yColor = simd_float4(0.2, 1, 0.2, 1)   // Y verde
        let zColor = simd_float4(0.2, 0.6, 1, 1)   // Z azul

        // Eje X
        v.append(Vertex(position: [-axisLength, 0, 0], color: xColor))
        v.append(Vertex(position: [ axisLength, 0, 0], color: xColor))

        // Eje Z
        v.append(Vertex(position: [0, 0, -axisLength], color: zColor))
        v.append(Vertex(position: [0, 0,  axisLength], color: zColor))

        // Eje Y (vertical)
        v.append(Vertex(position: [0, -axisLength*0.1, 0], color: yColor))
        v.append(Vertex(position: [0,  axisLength*0.1,  0], color: yColor))

        return v
    }
}
