/// @function draw_arc_width(x, y, radius, thickness, angle_start, angle_end, steps)
/// @description 绘制一段具有特定粗细的圆弧
/// @param {real} x             圆心 X 坐标
/// @param {real} y             圆心 Y 坐标
/// @param {real} radius        弧的中心半径
/// @param {real} thickness     弧的粗细（像素）
/// @param {real} angle_start   起始角度 (0 为右侧, 逆时针增加)
/// @param {real} angle_end     结束角度
/// @param {real} steps         分段精度 (数值越大弧线越圆滑，通常 24 到 64 足够)
function draw_arc_width(_x, _y, _radius, _thickness, _angle_start, _angle_end, _steps) {
    // 计算内圈和外圈的半径
    var _r_inner = _radius - (_thickness / 2);
    var _r_outer = _radius + (_thickness / 2);
    
    // 计算每次循环需要增加的角度跨度
    var _angle_step = (_angle_end - _angle_start) / _steps;

    // 开始绘制三角形带
    draw_primitive_begin(pr_trianglestrip);

    for (var i = 0; i <= _steps; i++) {
        var _current_angle = _angle_start + (i * _angle_step);
        
        // 计算内边缘顶点的 X 和 Y 坐标
        var _ix = _x + lengthdir_x(_r_inner, _current_angle);
        var _iy = _y + lengthdir_y(_r_inner, _current_angle);
        
        // 计算外边缘顶点的 X 和 Y 坐标
        var _ox = _x + lengthdir_x(_r_outer, _current_angle);
        var _oy = _y + lengthdir_y(_r_outer, _current_angle);

        // 提交两个顶点，图元系统会自动将它们与前一组顶点连成三角形
        draw_vertex(_ix, _iy);
        draw_vertex(_ox, _oy);
    }

    // 结束并渲染图元
    draw_primitive_end();
}