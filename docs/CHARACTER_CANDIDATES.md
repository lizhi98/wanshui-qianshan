# 人物方案的实际筛选记录

记录日期：2026-10-21。每项按已完成操作描述，不将网页筛选等同于成功游戏导入。

| 比较维度 | MPFB 2.0.18（采用） | Human Base Meshes v1.4.1（未采用） | Blender Studio Rex（仅网页筛选） |
| --- | --- | --- | --- |
| 官方来源 | MakeHuman Community MPFB GitHub | Blender官方Demo Files / Asset Bundles | Blender Studio官方角色页 |
| 许可 | 生成图形CC0；工具GPLv3 | CC0 | 官方角色页CC BY |
| 本次实际操作 | 下载、生成三人、绑骨、43段动作重定向、Godot运行 | 实际下载bundle；Blender检查；选定头部静态导出GLB并在Godot渲染 | 页面说明支持Blender 3.3–3.6；本次下载页返回402，未下载、未绕过 |
| 人体比例 | 成年自然比例，可调脸型/年龄/身高 | 有真实头部基础网格；不是本次可直接用的人物成品 | 风格化成品，未实际测量 |
| 骨骼 | game_engine 53骨骼已运行 | 所选真实头部0 Armature | 未测试 |
| 动画 | 43段；AnimationTree、IK、个性动作、完整输入回放 | 所选网格0 Action，无走跑可比较 | 未测试 |
| 制服适配 | 系统服装CC0改制，另加领片/口袋/连续军帽/背包 | 需要从零做全身、服装和骨骼 | 未进行制服改制 |
| Godot可用性 | 实际E触发对话、握持、攀索和发布程序 | 静态头部成功导入，见 `test_evidence/remaster/candidate_static_head.png` | 未验证 |
| 后续制作成本 | 当前已闭合的可编辑工作流 | 基础网格更适合作为继续雕刻的起点 | 引擎导出与版本适配仍需评估 |

因此本次采用MPFB。Human Base Meshes只做了静态导入比较，没有伪造该候选的走跑或骨骼截图；Rex没有成为游戏依赖。本轮没有完成第二套现成人物的全动画对照，这项筛选深度仍有限。

官方链接：
- https://github.com/makehumancommunity/mpfb2
- https://www.blender.org/download/demo-files/
- https://download.blender.org/demo/asset-bundles/human-base-meshes/
- https://studio.blender.org/characters/rex/v1/
