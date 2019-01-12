//
//  HLView.swift
//  OpenGLES003
//
//  Created by 于洪礼 on 2019/1/12.
//  Copyright © 2019 yuhongli. All rights reserved.
//

import UIKit

class HLView: UIView {
    var myTimer:Timer?
    var myEaglLayer:CAEAGLLayer!
    
    var myContext:EAGLContext!
    //color 缓存标记
    var myColorRenderBuffer:GLuint = 0
    var myColorFrameBuffer:GLuint = 0

    var myProgram:GLuint = 0
    
    var myVertices:GLuint = 0
    
    var xDegree:Float = 0
    var yDegree:Float = 0
    var zDegree:Float = 0
    var bX = false
    var bY = false
    var bZ = false
    override func layoutSubviews() {
        super.layoutSubviews()
        setuplayer()
        setupContext()
        deleteBuffer()
        setupRenderBuffer()
        setupFrameBuffer()
        render()
    }
    
    func setuplayer()  {
        myEaglLayer = self.layer as? CAEAGLLayer
        self.contentScaleFactor = UIScreen.main.scale
        myEaglLayer.isOpaque = true
        myEaglLayer.drawableProperties = [kEAGLDrawablePropertyRetainedBacking:NSNumber(value: false),kEAGLDrawablePropertyColorFormat:kEAGLColorFormatRGBA8]
    }
    
    func setupContext()  {
        guard let context = EAGLContext(api: .openGLES3),EAGLContext.setCurrent(context) else {
            return
        }
        myContext = context
    }
    
    func deleteBuffer()  {
        glDeleteBuffers(1, &myColorRenderBuffer)
        myColorRenderBuffer = 0
        glDeleteBuffers(1, &myColorFrameBuffer)
        myColorFrameBuffer = 0
    }
    
    func setupRenderBuffer()  {
        glGenRenderbuffers(1, &myColorRenderBuffer)
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), myColorRenderBuffer)
        myContext.renderbufferStorage(Int(GL_RENDERBUFFER), from: myEaglLayer)
        
    }
    func setupFrameBuffer()   {
        glGenFramebuffers(1, &myColorFrameBuffer)
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), myColorFrameBuffer)
        glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), GLenum(GL_RENDERBUFFER), myColorRenderBuffer)
        
    }
    
    func render()  {
        glClearColor(0, 0, 0, 1.0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
        let scale = UIScreen.main.scale
        glViewport(GLint(frame.origin.x*scale), GLint(frame.origin.y*scale), GLsizei(frame.size.width*scale), GLsizei(frame.size.height*scale))
        let vertFile = Bundle.main.path(forResource: "shaderv", ofType: "glsl")
        let fragFile = Bundle.main.path(forResource: "shaderf", ofType: "glsl")
        if myProgram != 0{
            glDeleteProgram(myProgram)
            myProgram = 0
        }
        
        myProgram = loadShader(vertFile!, fragFile!)
        
        glLinkProgram(myProgram)
        var successLink:GLint = 0
        glGetProgramiv(myProgram, GLenum(GL_LINK_STATUS), &successLink)
        if successLink == GL_FALSE {
//            let  UnsafeMutablePointer<GLsizei>.allocate(capacity: 1)
            let messagePtr = UnsafeMutablePointer<GLchar>.allocate(capacity: 256)
            glGetProgramInfoLog(myProgram, GLsizei(MemoryLayout<GLsizei>.size*256), nil, messagePtr)
            
            print("program error====\(String(cString: messagePtr))")
            free(messagePtr)
            return
        }else{
            glUseProgram(myProgram)
        }
        
        
        var indices:[GLuint] = [
            0, 3, 2,
            0, 1, 3,
            0, 2, 4,
            0, 4, 1,
            2, 3, 4,
            1, 4, 3,
        ]
        
        if myVertices == 0{
            glGenBuffers(1, &myVertices)
        }
        
        var attrArr:[GLfloat] = [
            -0.5, 0.5, 0.0,      1.0, 0.0, 0.0, //左上红
            0.5, 0.5, 0.0,       1.0, 0.0, 0.0, //右上红
            -0.5, -0.5, 0.0,     0.0, 0.0, 1.0, //左下蓝
            0.5, -0.5, 0.0,      0.0, 0.0, 1.0, //右下蓝
            0.0, 0.0, 1.0,       0.0, 1.0, 0.0, //顶点绿
        ]
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), myVertices)
        glBufferData(GLenum(GL_ARRAY_BUFFER), MemoryLayout<GLfloat>.size*attrArr.count, &attrArr, GLenum(GL_DYNAMIC_DRAW))
        
        let position:GLuint = GLuint(glGetAttribLocation(myProgram, "position".withCString{$0}))
        
        glVertexAttribPointer(position, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size*6), nil)
        glEnableVertexAttribArray(position)
        
        let positionColor:GLuint = GLuint(glGetAttribLocation(myProgram, "positionColor".withCString{$0}))
        glVertexAttribPointer(positionColor, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.size*6), UnsafeRawPointer(bitPattern: MemoryLayout<GLfloat>.size*3))
        glEnableVertexAttribArray(positionColor)
        
        let projectionMatrixSlot = glGetUniformLocation(myProgram, "projectionMatrix".withCString{$0})

        let modelViewMatrixSlot = glGetUniformLocation(myProgram, "modelViewMatrix".withCString{$0})
        
        let with = frame.width
        let height = frame.height
        let projectionMatrix = UnsafeMutablePointer<KSMatrix4>.allocate(capacity: 1)
        defer {
            free(projectionMatrix)
        }
        ksMatrixLoadIdentity(projectionMatrix)
        let aspect:CGFloat = with/height
        ksPerspective(projectionMatrix, 30, Float(aspect), 5.0, 20.0)
        glUniformMatrix4fv(projectionMatrixSlot, 1, GLboolean(GL_FALSE), &projectionMatrix.pointee.m.0.0)
        glEnable(GLenum(GL_CULL_FACE))
        let modelViewMatrix = UnsafeMutablePointer<KSMatrix4>.allocate(capacity: 1)
        defer {
            free(modelViewMatrix)
        }
        ksMatrixLoadIdentity(modelViewMatrix)
        ksTranslate(modelViewMatrix, 0, 0, -10)
        let rotationMatrix = UnsafeMutablePointer<KSMatrix4>.allocate(capacity: 1)
        defer {
            free(rotationMatrix)
        }
        ksMatrixLoadIdentity(rotationMatrix)
        ksRotate(rotationMatrix, xDegree, 1, 0, 0)
        ksRotate(rotationMatrix, yDegree, 0, 1, 0)
        ksRotate(rotationMatrix, zDegree, 0, 0, 1)
        ksMatrixMultiply(modelViewMatrix, rotationMatrix, modelViewMatrix)
        glUniformMatrix4fv(modelViewMatrixSlot, 1, GLboolean(GL_FALSE), &modelViewMatrix.pointee.m.0.0)
        
        glDrawElements(GLenum(GL_TRIANGLES), GLsizei(indices.count), GLenum(GL_UNSIGNED_INT), &indices)
        myContext?.presentRenderbuffer(Int(GL_RENDERBUFFER))
    }
    
    func loadShader(_ vert:String,_ frag:String) ->GLuint {
        var verShader:GLuint = 0
        var fragShader:GLuint = 0
        
        let program = glCreateProgram()
        compileShader(&verShader, GLenum(GL_VERTEX_SHADER), vert)
        compileShader(&fragShader, GLenum(GL_FRAGMENT_SHADER), frag)
        
        glAttachShader(program, verShader)
        glAttachShader(program, fragShader)
        glDeleteShader(verShader)
        glDeleteShader(fragShader)
        return program
        
    }
    
    func compileShader(_ shader:inout GLuint,_ type:GLenum,_ file:String)  {
        guard let content = try? String(contentsOfFile: file) else{return}
        let source = content.utf8CString
        var sourcePtr = source.withUnsafeBufferPointer { (ptr:UnsafeBufferPointer<GLchar>) in
            return ptr.baseAddress
        }
//
        shader = glCreateShader(type)
        glShaderSource(shader, 1, &sourcePtr, nil)
        glCompileShader(shader)
    }
    
    
    open override class var layerClass: AnyClass{
        return CAEAGLLayer.self
    }
    
    @IBAction func xClick(_ sender: Any) {
        if myTimer == nil {
            myTimer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(reDegree), userInfo: nil, repeats: true)
        }
        bX = !bX
    }
    
    @IBAction func yClick(_ sender: Any) {
        if myTimer == nil {
            myTimer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(reDegree), userInfo: nil, repeats: true)
        }
        bY = !bY
    }
    
    @IBAction func zClick(_ sender: Any) {
        if myTimer == nil {
            myTimer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(reDegree), userInfo: nil, repeats: true)
        }
        bZ = !bZ
    }
    
    @objc func reDegree(){
        let xx:Float = bX ? 1:0
        xDegree += xx*5.0
        let yy:Float = bY ? 1:0
        let zz:Float = bZ ? 1:0
        yDegree += yy*5.0
        zDegree += zz*5.0
        self.render()
    }
    
}
