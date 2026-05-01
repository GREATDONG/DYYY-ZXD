# DYYY 抖音插件 - 优化版 v2.0

> 针对抖音 38.4+ 版本的优化插件

## 📋 功能特性

### 🔐 Swift Hook 安全模式
- **零崩溃降级**: 如果 Swift 类不存在，功能自动降级，不会导致 App 闪退
- **状态监控**: 实时监控哪些功能不可用
- **优雅处理**: 用户体验更好，功能失效时静默禁用

### 🎬 模块化架构
将原来巨大的 `DYYY.xm` 拆分为 4 个模块：
- **DYYYVideoHooks.xm** - 视频相关 Hooks
- **DYYYCommentHooks.xm** - 评论相关 Hooks
- **DYYYLiveHooks.xm** - 直播相关 Hooks
- **DYYYUIHooks.xm** - 界面相关 Hooks

### ⚡ 性能优化
- API 接口更新
- 自动重试机制（最多3次）
- 增强的错误处理
- 文件格式检测优化

## 🚀 使用方法

### 方式一：手动应用
1. 下载本仓库的优化文件
2. 参考 `apply_optimization.md` 手动应用

### 方式二：GitHub Actions 自动构建
1. Fork 本仓库
2. 推送代码到 main 分支
3. GitHub Actions 自动构建

## 📁 文件说明

```
dyyy_optimized/
├── DYYYSwiftHookManager.h/m     ← Swift Hook 安全管理器
├── DYYYSwiftHooksSafe.m          ← Swift Hook 安全实现
├── DYYYVideoHooks.xm             ← 视频相关 Hooks
├── DYYYCommentHooks.xm           ← 评论相关 Hooks
├── DYYYLiveHooks.xm             ← 直播相关 Hooks
├── DYYYUIHooks.xm               ← 界面相关 Hooks
├── Makefile.modular             ← 模块化构建配置
├── Makefile.optimized           ← 优化构建配置
├── DYYYManager_optimized.m       ← API 接口优化
├── build.yml                    ← GitHub Actions
└── README.md                    ← 本文件
```

## 🔧 构建

```bash
# 安装依赖
make

# 构建
make package

# 构建并安装
make package install
```

## 📝 更新日志

### v2.0 (2026-05-01)
- ✅ Swift Hook 安全模式管理器
- ✅ 模块化拆分 DYYY.xm
- ✅ API 接口优化
- ✅ Makefile 模块化支持

## ⚠️ 注意事项

- 本项目仅供学习交流
- 请遵守相关法律法规
- 使用前请备份原文件

## 📜 许可证

MIT License

## 👤 作者

DYYY 优化团队

## 🙏 致谢

- 原始 DYYY 插件开发者
- DeepSeek-V4-Flash 代码分析支持
