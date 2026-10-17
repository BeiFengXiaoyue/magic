extends Node

## 事件总线（契约 02 §4.1）。app 层唯一允许 extends Node 的文件，只放信号声明。

signal action_requested(action: String, payload: Dictionary)
signal panel_requested(panel: String, params: Dictionary)
signal cue_requested(cue: String, params: Dictionary)
signal state_changed(scope: String, payload: Dictionary)
