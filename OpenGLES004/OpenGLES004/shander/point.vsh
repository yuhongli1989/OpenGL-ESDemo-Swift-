//顶点
attribute vec4 inVertex;

//矩阵
uniform mat4 MVP;

//点的大小
uniform float pointSize;

//点的颜色
uniform lowp vec4 vertexColor;

//输出颜色
varying lowp vec4 color;

void main()
{
    //顶点计算 = 矩阵 * 顶点
    gl_Position = MVP * inVertex;
    
    //修改顶点大小
    gl_PointSize = pointSize;
    //    1 * 3.0;
    
    //将通过uniform 传递进来的颜色,从顶点着色器程序传递到片元着色器
    color = vertexColor;
}
