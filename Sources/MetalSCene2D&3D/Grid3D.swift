import Metal
import simd
import MetalKit

public final class Grid3D {
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
                                 length: MemoryLayout<Vtx>.stride * verts.count,
                                 options: [.storageModeShared])!
    }

    public func draw(encoder: MTLRenderCommandEncoder, mvp: simd_float4x4) {
        encoder.setRenderPipelineState(pipeline)
        encoder.setDepthStencilState(depthState)
        encoder.setVertexBuffer(vbuf, offset: 0, index: 0)

        var u = Uniforms(mvp: mvp)
        encoder.setVertexBytes(&u, length: MemoryLayout<Uniforms>.stride, index: 1)
        encoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: vertexCount)
    }

    private static func buildVertices(spacing: Float, half: Int, axisLength: Float) -> [Vtx] {
        var v: [Vtx] = []
        let n = half
        let s = spacing

        let gridColor  = simd_float4(0.35, 0.35, 0.35, 1.0)
        let majorColor = simd_float4(0.55, 0.55, 0.55, 1.0)

        // Líneas paralelas al eje X (variando Z)
        for i in -n...n {
            let z = Float(i) * s
            let c = (i % 5 == 0) ? majorColor : gridColor
            v.append(Vtx(simd_float4(-Float(n)*s, 0, z, 1), c))
            v.append(Vtx(simd_float4( Float(n)*s, 0, z, 1), c))
        }

        // Líneas paralelas al eje Z (variando X)
        for i in -n...n {
            let x = Float(i) * s
            let c = (i % 5 == 0) ? majorColor : gridColor
            v.append(Vtx(simd_float4(x, 0, -Float(n)*s, 1), c))
            v.append(Vtx(simd_float4(x, 0,  Float(n)*s, 1), c))
        }

        // Ejes (X rojo, Y verde, Z azul)
        let xColor = simd_float4(1, 0.2, 0.2, 1)
        let yColor = simd_float4(0.2, 1, 0.2, 1)
        let zColor = simd_float4(0.2, 0.6, 1, 1)

        v.append(Vtx(simd_float4(-axisLength, 0, 0, 1), xColor))
        v.append(Vtx(simd_float4( axisLength, 0, 0, 1), xColor))

        v.append(Vtx(simd_float4(0, 0, -axisLength, 1), zColor))
        v.append(Vtx(simd_float4(0, 0,  axisLength, 1), zColor))

        v.append(Vtx(simd_float4(0, -axisLength*0.1, 0, 1), yColor))
        v.append(Vtx(simd_float4(0,  axisLength*0.1,  0, 1), yColor))

        return v
    }
}

