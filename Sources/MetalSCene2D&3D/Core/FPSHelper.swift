//
//  FPSHelper.swift
//  MetalScene2Dor3D
//
//  Created by Miguel Carlos Elizondo Mrtinez on 15/10/25.
//

import Foundation
import QuartzCore

public final class FPSMeter {
    private var last: CFTimeInterval = CACurrentMediaTime()
    private var frames: Int = 0
    private var acc: CFTimeInterval = 0
    public init() {}
    /// Devuelve FPS cada ~0.25s o nil si aún no toca
    public func tick() -> Double? {
        let now = CACurrentMediaTime()
        frames += 1; acc += now - last; last = now
        if acc >= 0.25 {
            let fps = Double(frames) / acc
            frames = 0; acc = 0
            return fps
        }
        return nil
    }
}

