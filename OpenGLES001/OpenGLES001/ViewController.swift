//
//  ViewController.swift
//  OpenGLES001
//
//  Created by 于洪礼 on 2018/12/21.
//  Copyright © 2018年 yuhongli. All rights reserved.
//

import UIKit
import GLKit

class ViewController: GLKViewController {

    lazy var context:EAGLContext? = {
        guard let cont = EAGLContext(api: .openGLES3) else{return nil}
        return cont
    }()
    var myView:GLKView{
        return self.view as! GLKView
    }
    var mEffect:GLKBaseEffect = GLKBaseEffect()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        //配置
        setUpConfig()
        //加载定点数据
        uploadVertexArray()
        uploadTexture()
        
    }
    //MARK:加载纹理
    func uploadTexture()  {
        guard let path = Bundle.main.path(forResource: "yejing", ofType: "jpg"),
            let textureInfo = try? GLKTextureLoader.texture(withContentsOfFile: path, options: [GLKTextureLoaderOriginBottomLeft:NSNumber.init(integerLiteral: 1)] ) else {
            return
        }
        
        mEffect.texture2d0.enabled = GLboolean(GL_TRUE)
        mEffect.texture2d0.name = textureInfo.name
    }
    
    func uploadVertexArray()  {
        
        var vertexData:[GLfloat] = [0.5,-0.5,0.0,1.0,0.0,
                                    0.5,0.5,-0.0,1.0,1.0,
                                    -0.5,0.5,0.0,0.0,1.0,
                                    
                                    0.5,-0.5,0.0,1.0,0.0,
                                    -0.5,0.5,0.0,0.0,1.0,
                                    -0.5,-0.5,0.0,0.0,0.0]
        var buffer:GLuint = 0
        glGenBuffers(1, &buffer)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), buffer)
        glBufferData(GLenum(GL_ARRAY_BUFFER), MemoryLayout<GLfloat>.size*vertexData.count, &vertexData, GLenum(GL_STATIC_DRAW))
        
        
        glEnableVertexAttribArray(GLuint(GLKVertexAttrib.position.rawValue))
         glVertexAttribPointer(GLuint(GLKVertexAttrib.position.rawValue), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.stride*5), nil)
        
        glEnableVertexAttribArray(GLuint(GLKVertexAttrib.texCoord0.rawValue))
        
        
        glVertexAttribPointer(GLuint(GLKVertexAttrib.texCoord0.rawValue), 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<GLfloat>.stride*5), UnsafeMutableRawPointer(bitPattern: 3*MemoryLayout<GLfloat>.stride))
        
        
        
        
        
    }
    
    func setUpConfig()  {
        guard let context = self.context else {
            return
        }
        myView.context = context
        myView.drawableColorFormat = .RGBA8888
        myView.drawableDepthFormat = .format24
        EAGLContext.setCurrent(context)
        glEnable(GLenum(GL_DEPTH_TEST))
        
        glClearColor(0.1, 0.2, 0.3, 0.1)
    }

    override func glkView(_ view: GLKView, drawIn rect: CGRect) {
        glClearColor(0.3, 0.6, 1.0, 1.0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT))
        mEffect.prepareToDraw()
        
        glDrawArrays(GLenum(GL_TRIANGLES), 0, 6)
    }

}

