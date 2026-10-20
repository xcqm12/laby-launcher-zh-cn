# Laby Launcher 简体中文语言包（一键汉化）

> 给 **LabyMod Launcher / Laby Launcher** 补上完整的简体中文界面 —— 一键脚本，可随时还原。

官方启动器里的简体中文长期只有 **8%** 的词条，而启动器的加载器有一道 **60% 覆盖率硬门槛**，达不到就直接丢弃整个语言包。结果就是：设置里**根本看不到「简体中文」这个选项**。
本项目把 4695 条文案全部翻译到位（100%），并附带一键汉化 / 一键还原脚本。

---

## ✨ 效果

| 项目 | 官方原状 | 打补丁后 |
|---|---|---|
| 简体中文词条 | 396 / 4695（8.37%） | **4695 / 4695（100%）** |
| 启动器语言列表 | ❌ 不出现（低于 60% 门槛） | ✅ 正常出现并可选中 |
| 界面语言 | 英文 | **简体中文** |
| 英文兜底残留 | — | 无 |

---

## 🚀 一键汉化

1. 点右上 **Code → Download ZIP**，解压到任意位置（勿放进启动器安装目录）。
2. **完全退出 Laby Launcher**（托盘也要退）。
3. 双击 **`一键汉化.cmd`**。
4. 启动器重新打开就是中文了。

脚本会自动：定位安装目录 → 备份原文件 → 写入语言包 → 把 `language` 设为 `zh-Hans` → 校验覆盖率。

---

## ↩️ 一键还原

双击 **`一键还原.cmd`**，恢复官方原始语言文件与配置，界面回到英文。

---

## 🔧 手动方式（脚本失败时）

1. 找到安装目录（含 `resources` 的那个文件夹）。
2. 把 `i18n/zh-Hans.json` 覆盖到：
   - `resources\app\.vite\i18n\zh-Hans.json` ← **实际生效的是这个**
   - `resources\i18n\zh-Hans.json`（回退目录，建议一并替换）
3. 打开 `%APPDATA%\LabyMod\launcher-config.json`，加入一行 `"language": "zh-Hans"`。
   若文件不存在（从没启动过启动器），启动后在 **启动器设置 → 启动器语言** 里选「简体中文」即可。

命令行等价：

```bat
powershell -ExecutionPolicy Bypass -File scripts\apply.ps1
powershell -ExecutionPolicy Bypass -File scripts\apply.ps1 -Path "D:\Games\Laby Launcher"   :: 自动定位失败时手动指定
powershell -ExecutionPolicy Bypass -File scripts\restore.ps1
```

---

## 🔍 原理（为什么以前没中文）

启动器主进程（`resources/app/.vite/build/app.js`）里的 i18n 加载器：

1. 优先读取 `resources/app/.vite/i18n/`，不存在才回退 `resources/i18n/`；
2. 每个 `*.json` 被**扁平化**为点号键（如 `launcher.settings.title`），以 `en` 为基准；
3. **硬门槛 `0.6`**：某语言的键覆盖率达到 `en` 的 60% 才注册进语言列表，**否则整份静默丢弃**；
4. 已注册但不完整时按 `{...英文, ...该语言}` 合并，缺词回落英文。

官方 `zh-Hans.json` 只有 396 条（8.37%）→ 被丢弃 → 语言列表里没有中文。本补丁把它补到 100%。

好消息：渲染层已内置 `"zh-Hans"` 的语言元数据（简体中文 + 国旗），`manifest.json` 里的 sha256 **启动时并不校验**，所以替换语言 JSON 是安全且不会触发修复的。

---

## ⚠️ 注意事项

- **启动器更新会覆盖 `resources/app/.vite/`**，汉化会失效。更新后重新跑一次 `一键汉化.cmd` 即可。
- 打补丁前务必**完全退出启动器**：它退出时会把内存中的配置写回 `launcher-config.json`，可能覆盖语言设置。
- 备份位置：`%APPDATA%\LabyMod\zh-patch-backup\`（原文两份 + 原配置），还原脚本就靠它。
- 只替换**语言文件与配置项**，不动任何可执行文件、不联网、不上传数据。

---

## ❓ 常见问题

**Q：脚本提示「未能自动找到 Laby Launcher 安装目录」？**
A：安装位置不常见。用 `一键汉化.cmd` 拖入路径，或手动指定：`-Path "你的安装目录"`。安装目录 = 含 `resources` 文件夹的那一级。

**Q：打完补丁界面还是英文？**
A：① 启动器没重启；② 语言被设置里覆盖了 —— 去 **启动器设置 → 启动器语言** 手动选「简体中文」；③ 启动器更新过，语言文件被覆盖 —— 重跑补丁。

**Q：语言列表里看不到「简体中文」？**
A：说明语言包覆盖率低于 60%（例如被旧版本残留覆盖）。重跑 `一键汉化.cmd`，脚本结尾会打印实际覆盖率。

**Q：界面里有少量英文？**
A：极少数纯品牌/技术名有意保留（`CPU`、`PvP`、`MOTD`、`OpenGL`、`H.264`、`Modrinth`、`Minecraft EULA` 等），共 71 条。

**Q：会被封号吗？**
A：不会。只替换静态语言资源，不修改游戏文件、不注入、不改网络通信。

---

## 📁 目录结构

```
一键汉化.cmd           双击打补丁
一键还原.cmd           双击还原
i18n/zh-Hans.json      语言包（4695 键，100% 覆盖）
scripts/apply.ps1      安装逻辑
scripts/restore.ps1    还原逻辑
scripts/Common.ps1     公共函数（定位/备份/校验）
tools/glossary.md      术语表（贡献翻译先看这里）
tools/audit.js         质量审计（需 Node）
tools/verify.js        复刻启动器注册逻辑校验（需 Node）
```

---

## 🧪 质量自检

```
覆盖率 4695/4695 = 100.00%   占位符一致性 0 处不一致
Markdown 粗体配对 0 处不一致  换行符数量 0 处不一致
疑似截断 0 条                 平均长度 英 28 → 中 11 字符
```

开发期校验（需要 Node.js）：

```bat
node tools\audit.js      :: 全量质量审计
node tools\verify.js     :: 复刻启动器 60% 注册判定
```

---

## 📌 版本对应

| 补丁 | 启动器版本 | en.json 键数 |
|---|---|---|
| v1.0 | 3.1.13（Electron 44.2.0） | 4695 |

启动器大版本更新后，`en.json` 可能新增词条。届时：把新 `en.json` 里新增的键补译进 `i18n/zh-Hans.json`（缺失的键会自动回落英文，不会坏）。

---

## 🙏 声明

- 本项目**非官方**，与 LabyMedia GmbH 无隶属关系。
- LabyMod / Laby Launcher 及其原始语言资源版权归 **LabyMedia GmbH** 所有（其 `package.json` 标注 MIT）；本仓库仅提供社区中文翻译补丁。
- 本仓库的脚本与译文同样以 MIT 协议发布，见 [LICENSE](LICENSE)。
- 使用风险自负：请自行保留官方安装包，必要时重装即可完全复原。
