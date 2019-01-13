//
//  HLView.swift
//  OpenGLES004
//
//  Created by 于洪礼 on 2019/1/12.
//  Copyright © 2019 yuhongli. All rights reserved.
//

import UIKit
import GLKit

let kBrushOpacity:CGFloat    =    (1.0 / 2.0)
let NUM_PROGRAMS = 1
let NUM_ATTRIBS = 1
let NUM_UNIFORMS = 4
let PROGRAM_POINT = 0
let UNIFORM_TEXTURE = 3
let UNIFORM_MVP = 0
let UNIFORM_POINT_SIZE = 1
let kBrushScale = 2
let UNIFORM_VERTEX_COLOR = 2
let kBrushPixelStep:Float = 2
let ATTRIB_VERTEX = 0

class HLView: UIView {
    
    var backingWidth:GLint = 0
    var backingHeight:GLint = 0
    var context:EAGLContext? = EAGLContext(api: .openGLES3)
    var viewRenderBuffer:GLuint = 0
    var viewFrameBuffer:GLuint = 0
    var brushTexture:textureInfo_t!
    var brushColor:[GLfloat] = [GLfloat](repeating: 0, count: 4)
    
    var firstTouch:Bool = false
    var initialized = false
    
    var needsErase = false
    
    var vertexShader:GLuint = 0
    var fragmentShader:GLuint = 0
    var shaderProgram:GLuint = 0
    
    var vboId:GLuint = 0
    var CCArr = [HLPoint]()
    var vertexMax = 64
    var vertexBuffer = [GLfloat](repeating: 0, count: 64 * 2)
    
    lazy var program:[programInfo_t] = {
        return [programInfo_t( "point.vsh", "point.fsh")]
        
    }()
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    deinit {
        for p in program{
            free(p.uniform)
        }
        
    }
    
    
    override class var layerClass: AnyClass {
        return CAEAGLLayer.self
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        let eaglLayer = self.layer as! CAEAGLLayer
        eaglLayer.isOpaque = true
        eaglLayer.drawableProperties = [kEAGLDrawablePropertyRetainedBacking:NSNumber(value: false),kEAGLDrawablePropertyColorFormat:kEAGLColorFormatRGBA8]
        if !EAGLContext.setCurrent(context){
            print("init context error")
        }
        self.contentScaleFactor = UIScreen.main.scale
        needsErase = true
        
    }
    
    override func layoutSubviews() {
        if !initialized{
            initialized = initGL()
        }else{
            resizeFromLayer(self.layer as! CAEAGLLayer)
        }
        
        if needsErase {
            erase()
            needsErase = false
        }
        
        
    }
    
    func erase()  {
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), viewFrameBuffer)
        glClearColor(0, 0, 0, 1.0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), viewFrameBuffer)
        context?.presentRenderbuffer(Int(GL_RENDERBUFFER))
    }
    
    func resizeFromLayer(_ eaglLayer:CAEAGLLayer) ->Bool {
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), viewRenderBuffer)
        context?.renderbufferStorage(Int(GL_RENDERBUFFER), from: eaglLayer)
        glGetRenderbufferParameteriv(GLenum(GL_RENDERBUFFER), GLenum(GL_RENDERBUFFER_WIDTH), &backingWidth)
        glGetRenderbufferParameteriv(GLenum(GL_RENDERBUFFER), GLenum(GL_RENDERBUFFER_HEIGHT), &backingHeight)
        if glCheckFramebufferStatus(GLenum(GL_FRAMEBUFFER)) != GL_FRAMEBUFFER_COMPLETE{
            return false
        }
        
        let projectionMatrix = GLKMatrix4MakeOrtho(0, Float(backingWidth), 0, Float(backingHeight), -1, 1)
        let modelViewMatrix = GLKMatrix4Identity
        let MVPMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix)
        let arr = Mirror(reflecting: MVPMatrix.m).children.compactMap { (child:(label: String?, value: Any))-> Float?  in
            if let v = child.value as? Float{
                return v
            }
            return nil
        }
        glUniformMatrix4fv(program[PROGRAM_POINT].uniform[UNIFORM_MVP], 1, GLboolean(GL_FALSE), arr.withUnsafeBufferPointer {$0.baseAddress!})
        glViewport(0, 0, backingWidth, backingHeight)
        return true
    }
    
    func initGL()->Bool  {
        glGenFramebuffers(1, &viewFrameBuffer)
        glGenRenderbuffers(1, &viewRenderBuffer)
        context?.renderbufferStorage(Int(GL_RENDERBUFFER), from: layer as! CAEAGLLayer)
        glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), GLenum(GL_RENDERBUFFER), viewRenderBuffer)
        glGetRenderbufferParameteriv(GLenum(GL_RENDERBUFFER), GLenum(GL_RENDERBUFFER_WIDTH), &backingWidth)
        glGetRenderbufferParameteriv(GLenum(GL_RENDERBUFFER), GLenum(GL_RENDERBUFFER_HEIGHT), &backingHeight)
        if glCheckFramebufferStatus(GLenum(GL_FRAMEBUFFER)) != GL_FRAMEBUFFER_COMPLETE{
            return false
        }
        
        glViewport(0, 0, backingWidth, backingHeight)
        glGenBuffers(1, &vboId)
        brushTexture = textureFromName("Particle.png")
        setupShaders()
        glEnable(GLenum(GL_BLEND))
        glBlendFunc(GLenum(GL_ONE), GLenum(GL_ONE_MINUS_SRC_ALPHA))
        let path = Bundle.main.path(forResource: "abc", ofType: "string")
        let str = try? String(contentsOfFile: path!, encoding: .utf8)
        
        let jsonArr = try! JSONSerialization.jsonObject(with: str!.data(using: .utf8)!, options: .allowFragments) as! [Any]
        for dic in jsonArr {
            if let dict = dic as? NSDictionary{
                let x = dict.object(forKey: "mX") as! Double
                let y = dict.object(forKey: "mY") as! Double
                CCArr.append(HLPoint(CGPoint(x: x, y: y)))
            }
        }
        
        self.perform(#selector(paint), with: nil, afterDelay: 0.5)
        return true
    }
    
    @objc func paint()  {
        
        
        for i in stride(from: 0, to: CCArr.count-1, by: 2) {
            let cp1 = CCArr[i]
            let cp2 = CCArr[i+1]
            
            let p1 = CGPoint(x: cp1.mX.doubleValue, y: cp1.mY.doubleValue)
            let p2 = CGPoint(x: cp2.mX.doubleValue, y: cp2.mY.doubleValue)
            renderLine(p1, p2)
        }
    }
    
    func renderLine(_ start:CGPoint,_ end:CGPoint)  {
        let scale = self.contentScaleFactor
        let startX:Float = Float(start.x*scale)
        let startY:Float = Float(start.y*scale)
        let endX:Float = Float(end.x*scale)
        let endY:Float = Float(end.y*scale)
        var vertexCount = 0
        let seq = sqrtf((endX-startX)*(endX-startX)+(endY-startY)*(endY-startY))
        let pointCount = ceilf(seq/kBrushPixelStep)
        let count = Int(max(pointCount,1))
        
        for i in 0..<count{
            if vertexCount == vertexMax{
                vertexMax = vertexCount*2
                vertexBuffer.append(contentsOf: [GLfloat](repeating: 0, count: vertexCount*2))
            }
            vertexBuffer[2 * vertexCount + 0] = startX+(endX-startX)*(Float(i)/Float(count))
            vertexBuffer[2 * vertexCount + 1] = startY + (endY - startY) * (Float(i)/Float(count))
            vertexCount+=1
        }
        glBindBuffer(GLenum(GL_ARRAY_BUFFER),vboId)
        glBufferData(GLenum(GL_ARRAY_BUFFER), vertexCount*2*MemoryLayout<GLfloat>.size, vertexBuffer, GLenum(GL_DYNAMIC_DRAW))
        
        
        glEnableVertexAttribArray(GLuint(ATTRIB_VERTEX))
        glVertexAttribPointer(GLuint(ATTRIB_VERTEX), 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(2*MemoryLayout<GLfloat>.size), nil)
        glUseProgram(program[PROGRAM_POINT].id)
        glDrawArrays(GLenum(GL_POINTS), 0, GLsizei(vertexCount))
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), viewRenderBuffer)
        context?.presentRenderbuffer(Int(GL_RENDERBUFFER))
    }
    
    func setupShaders()  {
        for i in 0..<NUM_PROGRAMS{
            let vsrc = program[i].vert
            let frag = program[i].frag
            var attribCt:GLsizei = 0
            var attribUsed = [String](repeating: "", count: NUM_ATTRIBS)
            var attrib = [GLint](repeating: 0, count: NUM_ATTRIBS)
            var attribName = ["inVertex"]
            var uniformName = ["MVP","pointSize","vertexColor","texture"]
            for j in 0..<NUM_ATTRIBS{
                if vsrc.contains(attribName[j]){
                    attrib[Int(attribCt)] = GLint(j)
                    attribUsed[Int(attribCt)] = attribName[j]
                    attribCt += 1
                }
            }
            var attrName:UnsafePointer<GLchar>? = attribUsed[0].withCString{$0}
            var uniformn:UnsafePointer<GLchar>? = uniformName[0].withCString{$0}
            
            glueCreateProgram(vsrc.withCString{$0}, frag.withCString{$0}, attribCt, &attrName, &attrib, GLsizei(NUM_UNIFORMS), &uniformn, program[i].uniform, &program[i].id)
            if i == PROGRAM_POINT{
                glUseProgram(program[PROGRAM_POINT].id)
                glUniform1i(program[PROGRAM_POINT].uniform[UNIFORM_TEXTURE], 0)
                let projectionMatrix = GLKMatrix4MakeOrtho(0, Float(backingWidth), 0, Float(backingHeight), -1, 1)
                let modelViewMatrix = GLKMatrix4Identity
                var MVPMatrix = GLKMatrix4Multiply(projectionMatrix, modelViewMatrix)
                let arr = Mirror(reflecting: MVPMatrix.m).children.compactMap { (child:(label: String?, value: Any))-> Float?  in
                    if let v = child.value as? Float{
                        return v
                    }
                    return nil
                }
                
                glUniformMatrix4fv(program[PROGRAM_POINT].uniform[UNIFORM_MVP], 1, GLboolean(GL_FALSE), arr.withUnsafeBufferPointer {$0.baseAddress!})
                glUniform1f(program[PROGRAM_POINT].uniform[UNIFORM_POINT_SIZE], GLfloat(brushTexture.width/GLsizei(kBrushScale)))
                glUniform4fv(program[PROGRAM_POINT].uniform[UNIFORM_VERTEX_COLOR], 1, brushColor.withUnsafeBufferPointer{$0.baseAddress})
                
                
            }
            
        }
    }
    
    func textureFromName(_ name:String)->textureInfo_t?  {
        guard let image = UIImage(named: name)?.cgImage else{
            print("纹理加载失败")
            return nil
        }
        let width = image.width
        let height = image.height
        
        //        CGImageAlphaInfo.premultipliedLast
        let imagePtr = UnsafeMutableRawPointer.allocate(byteCount: width*height*4, alignment: MemoryLayout<GLbyte>.size)
        defer {
            free(imagePtr)
        }
        let cgcontext = CGContext(data: imagePtr, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width*4, space: image.colorSpace!, bitmapInfo: image.alphaInfo.rawValue)
        cgcontext?.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        var texId:GLuint = 0
        glGenTextures(1, &texId)
        glBindTexture(GLenum(GL_TEXTURE_2D), texId)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR)
        
        glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_RGBA, GLsizei(width), GLsizei(height), 0, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), imagePtr)
        return textureInfo_t(width: GLsizei(width), height: GLsizei(height), id: texId)
        

    }
    
    
    func setBrushColor(_ red:CGFloat,_ green:CGFloat,_ blue:CGFloat )  {
        
        brushColor[0] = GLfloat(red*kBrushOpacity)
        brushColor[1] = GLfloat(green*kBrushOpacity)
        brushColor[2] = GLfloat(blue*kBrushOpacity)
        brushColor[3] = GLfloat(kBrushOpacity)
//        if initialized {
//            glUseProgram(program.id)
//        }
    }

}


struct programInfo_t {
    var vert:String
    var frag:String
    var uniform = UnsafeMutablePointer<GLint>.allocate(capacity: NUM_UNIFORMS)
    var id:GLuint = 0
    init(_ v:String,_ f:String) {
        vert = v
        frag = f
    }
}

struct textureInfo_t {
    var width:GLsizei
    var height:GLsizei
    var id:GLuint
}

struct HLPoint {
    let mY:NSNumber
    let mX:NSNumber
    init(_ point:CGPoint) {
        
        mY = NSNumber(value: Double(point.y))
        mX = NSNumber(value: Double(point.x))
    }
}

