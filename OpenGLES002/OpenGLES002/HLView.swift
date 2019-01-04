//
//  HLView.swift
//  OpenGLES002
//
//  Created by yunfu on 2019/1/2.
//  Copyright © 2019 yunfu. All rights reserved.
//

import UIKit

class HLView: UIView {
    
    var myEagLayer:CAEAGLLayer!
    var myContext:EAGLContext!
    
    var myColorRenderBuffer:GLuint = 0
    var myColorFrameBuffer:GLuint = 0
    var myPrograme:GLuint = 0
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.setUpLayer()
        self.setupContext()
        self.deleteRenderAndFrameBuffer()
        self.setupRenderBuffer()
        self.setupFrameBuffer()
        self.renderLayer()
    }
    
    func setUpLayer()  {
        myEagLayer = self.layer as? CAEAGLLayer
        self.contentScaleFactor = UIScreen.main.scale
        myEagLayer.isOpaque = true
        myEagLayer.drawableProperties = [kEAGLDrawablePropertyRetainedBacking:NSNumber(value: false),kEAGLDrawablePropertyColorFormat:kEAGLColorFormatRGBA8]
        
    }
    
    
    func setupContext()  {
        guard let context = EAGLContext(api: .openGLES3),EAGLContext.setCurrent(context) else {
            return
        }
        myContext = context
    }
    
    func deleteRenderAndFrameBuffer()  {
        glDeleteBuffers(1, &myColorRenderBuffer)
        myColorRenderBuffer = 0
        glDeleteBuffers(1, &myColorFrameBuffer)
        myColorFrameBuffer = 0
    }
    
    func setupRenderBuffer()  {
        glGenRenderbuffers(1, &myColorRenderBuffer)
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), myColorRenderBuffer)
        myContext.renderbufferStorage(Int(GL_RENDERBUFFER), from: myEagLayer)
    }
    
    func setupFrameBuffer()  {
        glGenRenderbuffers(1, &myColorFrameBuffer)
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), myColorFrameBuffer)
        glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), GLenum(GL_RENDERBUFFER), myColorRenderBuffer)
        
    }
    
    func renderLayer()  {
        glClearColor(0.0, 1.0, 0.0, 1.0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
        let scale = UIScreen.main.scale
        glViewport(GLint(frame.origin.x*scale), GLint(frame.origin.y*scale), GLsizei(frame.size.width*scale), GLsizei(frame.size.height*scale))
        
        let vertFile = Bundle.main.path(forResource: "shaderv", ofType: "vsh")
        let fragFile = Bundle.main.path(forResource: "shaderf", ofType: "fsh")
        print("vertFile===\(vertFile),fragFile===\(fragFile)")
        myPrograme = loadShaders(vertFile!, fragFile!)
        glLinkProgram(myPrograme)
        
        var linkStatus:GLint = -1
        
        glGetProgramiv(myPrograme, GLenum(GL_LINK_STATUS), &linkStatus)
        if linkStatus == GL_FALSE{
            print("linkStatus === \(linkStatus)myPrograme  error")
            return
        }
        glUseProgram(myPrograme)
        var attrArr:[GLfloat] = [
            0.5, -0.5, -1.0,     1.0, 0.0,
            -0.5, 0.5, -1.0,     0.0, 1.0,
            -0.5, -0.5, -1.0,    0.0, 0.0,
            0.5, 0.5, -1.0,      1.0, 1.0,
            -0.5, 0.5, -1.0,     0.0, 1.0,
            0.5, -0.5, -1.0,     1.0, 0.0
        ]
        var attrBuffer:GLuint = 0
        glGenBuffers(1, &attrBuffer)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), attrBuffer)
        glBufferData(GLenum(GL_ARRAY_BUFFER), MemoryLayout<GLfloat>.size*attrArr.count, &attrArr, GLenum(GL_DYNAMIC_DRAW))
        let positionPtr = "position".utf8CString.withUnsafeBufferPointer { (ptr:UnsafeBufferPointer<CChar>)  in
            return ptr.baseAddress!
        }
        let position:GLuint = GLuint(glGetAttribLocation(myPrograme, positionPtr))
        glEnableVertexAttribArray(position)
        glVertexAttribPointer(position, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size*5), nil)
        let textCoorName = "textCoordinate".utf8CString.withUnsafeBufferPointer { (ptr:UnsafeBufferPointer<CChar>)  in
            return ptr.baseAddress!
        }
        let textCoor = glGetAttribLocation(myPrograme, textCoorName)
        glEnableVertexAttribArray(GLuint(textCoor))
        glVertexAttribPointer(GLuint(textCoor), 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size*5), UnsafeRawPointer(bitPattern: MemoryLayout<GLfloat>.size*3))
        setupTexture("timg-3")
        let rotateName = "rotateMatrix".utf8CString.withUnsafeBufferPointer { (ptr:UnsafeBufferPointer<CChar>)  in
            return ptr.baseAddress!
        }
        let rotate:GLuint = GLuint(glGetUniformLocation(myPrograme, rotateName))
        let radians:Float = 10 * 3.14159/180.0
        let s = sin(radians)
        
        let c = cos(radians)
        var zRotation:[GLfloat] = [
            c, -s, 0, 0,
            s, c, 0, 0,
            0, 0, 1.0, 0,
            0.0, 0, 0, 1.0
        ]
        glUniformMatrix4fv(GLint(rotate), 1, GLboolean(GL_FALSE), &zRotation)
        glDrawArrays(GLenum(GL_TRIANGLES), 0, 6)
        myContext.presentRenderbuffer(Int(GL_RENDERBUFFER))
    }
    
    func setupTexture(_ filename:String)  {
        guard let spriteImage = UIImage(named: filename)?.cgImage else {
            return
        }
        let raw = UnsafeMutableRawPointer.allocate(byteCount: spriteImage.width*spriteImage.height*4, alignment: MemoryLayout<GLubyte>.stride)
        
        var spriteContext = CGContext(data: raw, width: spriteImage.width, height: spriteImage.height, bitsPerComponent: 8, bytesPerRow: spriteImage.width*4, space: spriteImage.colorSpace!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        let rect = CGRect(x: 0, y: 0, width: spriteImage.width, height: spriteImage.height)
        spriteContext?.draw(spriteImage, in: rect)
        spriteContext = nil
        glBindTexture(GLenum(GL_TEXTURE_2D), 0)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR)
        glTexParameteri( GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GL_LINEAR )
        glTexParameteri( GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_CLAMP_TO_EDGE)
        glTexParameteri( GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_CLAMP_TO_EDGE)
        let width = spriteImage.width
        let height = spriteImage.height
        glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_RGBA, GLsizei(width), GLsizei(height), 0, GLenum(GL_RGBA), GLenum(GL_UNSIGNED_BYTE), raw)
        glBindTexture(GLenum(GL_TEXTURE_2D), 0)
        free(raw)
    }
    
    
    func loadShaders(_ vert:String,_ frag:String)->GLuint  {
        var verShader:GLuint = 0
        var fragShader:GLuint = 0
        
        let program = glCreateProgram()
        compileShader(&verShader, GLenum(GL_VERTEX_SHADER), vert)
        compileShader(&fragShader, GLenum(GL_FRAGMENT_SHADER), frag)
        print("verShader===\(verShader),fragShader===\(fragShader)")
        glAttachShader(program, verShader)
        glAttachShader(program, fragShader)
        glDeleteShader(verShader)
        glDeleteShader(fragShader)
        return program
    }
    
    func compileShader(_ shader:inout GLuint,_ type:GLenum, _ file:String)  {
        guard let content = try? String(contentsOfFile: file) else{return}
        let source = content.utf8CString
        var sourcePtr = source.withUnsafeBufferPointer { (ptr:UnsafeBufferPointer<CChar>) in
            return ptr.baseAddress
        }
        shader = glCreateShader(type)
        glShaderSource(shader, 1, &sourcePtr, nil)
        glCompileShader(shader)
    }
    
    override class var layerClass: AnyClass{
        return CAEAGLLayer.self
    }

}
