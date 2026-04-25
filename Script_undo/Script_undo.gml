// 初始化Undo栈，在游戏开始或控制器对象的 Create 事件中调用一次即可
function undo_init() {
    global.undo_stack = [];
}

// 记录当前状态
function undo_save_state() {
    // 创建一个结构体来保存这一步的状态
    var _state = {
        player_x: obj_player.x,
        player_y: obj_player.y,
        boxes: []
    };
    
    // 遍历所有箱子，记录它们的实例ID和坐标
    with (obj_block) {
        array_push(_state.boxes, {
            inst_id: id,
            x: x,
            y: y
        });
    }
    
    // 将这个状态压入栈中
    array_push(global.undo_stack, _state);
}

// 执行撤销操作
function undo_execute() {
    // 检查栈里是否有历史记录
    if (array_length(global.undo_stack) > 0) {
        // 弹出最后一次保存的状态
        var _state = array_pop(global.undo_stack);
        
        // 恢复玩家位置
        if (instance_exists(obj_player)) {
            obj_player.x = _state.player_x;
            obj_player.y = _state.player_y;
        }
        
        // 恢复所有箱子位置
        var _box_count = array_length(_state.boxes);
        for (var i = 0; i < _box_count; i++) {
            var _box_data = _state.boxes[i];
            var _inst = _box_data.inst_id;
            
            if (instance_exists(_inst)) {
                _inst.x = _box_data.x;
                _inst.y = _box_data.y;
            }
        }
    }
}