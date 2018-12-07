//
//  ViewDraw.swift
//  AVPlayerVideo
//
//  Created by Hoang Le on 12/5/18.
//  Copyright © 2018 Hoang Le. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class ViewDraw: UIView {

    var path:UIBezierPath!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.isMultipleTouchEnabled = false
        self.backgroundColor = UIColor.clear
        path = UIBezierPath()
        path.lineWidth = 2.0
    }
    
    
    override func draw(_ rect: CGRect) {
        UIColor.red.setStroke()
        path.stroke()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!
        let location = touch.location(in: self)
        path.move(to: location)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!
        let location = touch.location(in: self)
        path.addLine(to: location)
        self.setNeedsDisplay()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
       self.touchesMoved(touches, with: event)
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
       self.touchesEnded(touches, with: event)
    }

}
