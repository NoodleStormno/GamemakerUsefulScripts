/// @function layer_get_tilemap_id_fixed(_layer)
/// @description 安全获取指定图层上的 Tilemap ID，防止图层元素类型不匹配报错
/// @param {String|Id.Layer} _layer 瓦片图层名称或 ID
/// @returns {Id.TileMapElement|Real} 返回 Tilemap ID，如果未找到则返回 -1
function layer_get_tilemap_id_fixed(_layer) {
    var _els = layer_get_all_elements(_layer);
    var _n = array_length(_els);
    for (var i = 0; i < _n; i++) {
        var _el = _els[i];
        if (layer_get_element_type(_el) == layerelementtype_tilemap) {
            return _el;
        }
    }
    return -1;
}

/// @function tplace_meeting_tilemap(_x, _y, _layer_id, _tile_size, _solid_min, _solid_max)
/// @description 瓦片地图矩形碰撞检测核心模块（替代 place_meeting）
/// @param {Real} _x 预测的 X 坐标
/// @param {Real} _y 预测的 Y 坐标
/// @param {String|Id.Layer} _layer_id 瓦片图层名称或 ID
/// @param {Real} _tile_size 瓦片的像素尺寸 (例如 16 或 32)
/// @param {Real} _solid_min 实心图块的最小 Index (例如 1)
/// @param {Real} _solid_max 实心图块的最大 Index (例如 50)
/// @returns {Bool} 如果触碰到实心瓦片则返回 true
function tplace_meeting_tilemap(_x, _y, _layer_id, _tile_size, _solid_min, _solid_max) {
    var _tm = layer_get_tilemap_id_fixed(_layer_id);
    if (_tm == -1) return false;
    
    // 计算位移偏差
    var _nx = _x - x;
    var _ny = _y - y;
    
    // 将包围盒像素坐标转换为瓦片网格坐标
    // bbox_left 等是 GameMaker 原生的实例变量，代表当前对象的碰撞盒边界
    var _x1 = floor((bbox_left + _nx) / _tile_size);
    var _x2 = floor((bbox_right + _nx) / _tile_size);
    var _y1 = floor((bbox_top + _ny) / _tile_size);
    var _y2 = floor((bbox_bottom + _ny) / _tile_size);
    
    // 遍历包围盒覆盖的所有网格
    for (var _grid_x = _x1; _grid_x <= _x2; _grid_x++) {
        for (var _grid_y = _y1; _grid_y <= _y2; _grid_y++) {
            var _ind = tile_get_index(tilemap_get(_tm, _grid_x, _grid_y));
            
            // 判断获取到的瓦片 ID 是否在定义的实心范围内
            if (_ind >= _solid_min && _ind <= _solid_max) {
                return true;
            }
        }
    }
    return false;
}

/// @function scr_move_and_collide_tilemap(_layer_id, _tile_size, _solid_min, _solid_max, _step_height)
function scr_move_and_collide_tilemap(_layer_id, _tile_size, _solid_min, _solid_max, _step_height) {
    var _precision = 0.2; 
    
    // ==========================================
    // 水平移动与斜坡 (直接操作实例变量 hsp)
    // ==========================================
    if (tplace_meeting_tilemap(x + ceil(hsp), y, _layer_id, _tile_size, _solid_min, _solid_max) || 
        tplace_meeting_tilemap(x + hsp, y, _layer_id, _tile_size, _solid_min, _solid_max)) {
        
        if (tplace_meeting_tilemap(x, y + _step_height, _layer_id, _tile_size, _solid_min, _solid_max) && 
            !tplace_meeting_tilemap(x + ceil(hsp), y - _step_height, _layer_id, _tile_size, _solid_min, _solid_max) && 
            !tplace_meeting_tilemap(x + hsp, y - _step_height, _layer_id, _tile_size, _solid_min, _solid_max)) {
            
            x += hsp;
            var _n = 0;
            while (tplace_meeting_tilemap(x, y, _layer_id, _tile_size, _solid_min, _solid_max) && _n < 64) { 
                _n++; y -= _precision; 
            }
            
        } else if (tplace_meeting_tilemap(x, y - (_step_height - 0.5), _layer_id, _tile_size, _solid_min, _solid_max) && 
                   !tplace_meeting_tilemap(x + ceil(hsp), y + _step_height, _layer_id, _tile_size, _solid_min, _solid_max) && 
                   !tplace_meeting_tilemap(x + hsp, y + _step_height, _layer_id, _tile_size, _solid_min, _solid_max)) {
            
            x += hsp;
            var _n = 0;
            while (tplace_meeting_tilemap(x, y, _layer_id, _tile_size, _solid_min, _solid_max) && _n < 64) { 
                _n++; y += _precision; 
            }
            
        } else {
            var _dir = sign(hsp);
            var _n = 0;
            while (!tplace_meeting_tilemap(x + _dir * _precision, y, _layer_id, _tile_size, _solid_min, _solid_max) && _n < 64) { 
                _n++; x += _dir * _precision; 
            }
            // 真实清零角色的水平速度
            hsp = 0; 
        }
    } else {
        x += hsp;
    }
    
    // ==========================================
    // 垂直移动与上下碰撞 (直接操作实例变量 vsp)
    // ==========================================
    if (tplace_meeting_tilemap(x, y + ceil(vsp), _layer_id, _tile_size, _solid_min, _solid_max) || 
        tplace_meeting_tilemap(x, y + vsp, _layer_id, _tile_size, _solid_min, _solid_max)) {
        
        var _dir = sign(vsp);
        var _n = 0;
        while (!tplace_meeting_tilemap(x, y + _dir, _layer_id, _tile_size, _solid_min, _solid_max) && _n < 32) { 
            _n++; y += _dir; 
        }
        // 关键修复：真实清零角色的垂直速度，彻底切断重力累加！
        vsp = 0; 
    }
    y += vsp;
}


//----------------------------------------使用方法示例--------------------------------------
// 1. 获取输入
//var _key_right = keyboard_check(vk_right);
//var _key_left  = keyboard_check(vk_left);
//var _key_jump  = keyboard_check_pressed(vk_space); // 按下空格键跳跃

// 2. 计算水平移动
//var _move_dir = _key_right - _key_left;
//hsp = _move_dir * move_spd;

// 3. 施加重力
//vsp += grav;

// 探测脚底正下方 1 像素的位置，看看有没有实心瓦片（假设图块 ID 1~50 是实心的）
//var _on_ground = tplace_meeting_tilemap(x, y + 1, "Tiles_Solid", 16, 1, 50);

// 如果按下了跳跃键，并且当前踩在地上
//if (_key_jump && _on_ground) {
//    vsp = jump_spd; // 瞬间给予向上的速度
//}


// 4. 终端速度限制（防止下落过快穿模）
//if (vsp > 12) vsp = 12;

// 5. 调用核心碰撞脚本（直接接管 hsp 和 vsp，处理移动和撞墙）
//scr_move_and_collide_tilemap("Tiles_Solid", 16, 1, 50, 4);




//----------------------------------------------项目结构------------------------------------------

//layer_get_tilemap_id_fixed(_layer):

//底层辅助：安全地获取图层中的瓦片地图 ID。它能防止因图层名写错或图层中包含非瓦片元素而导致的引擎报错。

//tplace_meeting_tilemap(_x, _y, _layer_id, _tile_size, _solid_min, _solid_max):

//碰撞雷达：替代原生的 place_meeting。它将角色的包围盒（Bounding Box）转换为网格坐标，检查所触及的网格内是否存在指定 ID 范围内的实心瓦片。

//scr_move_and_collide_tilemap(_hsp, _vsp, _layer_id, _tile_size, _solid_min, _solid_max, _step_height):

//物理主控：这是你在玩家对象的 Step 事件中唯一需要调用的函数。它接收速度，并在内部调用“碰撞雷达”来推演坐标。如果遇到斜坡，它会以 0.2 像素的极小步长进行顺滑贴合。