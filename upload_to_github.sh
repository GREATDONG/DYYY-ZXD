#!/bin/bash
# DYYY 优化包上传到 GitHub
# 使用方法: bash upload_to_github.sh

echo "=========================================="
echo "DYYY 优化包上传到 GitHub"
echo "=========================================="

# 检查 git 是否初始化
if [ ! -d ".git" ]; then
    echo "初始化 Git 仓库..."
    git init
fi

# 配置 git（如果需要）
# git config user.name "Your Name"
# git config user.email "[email protected]"

# 添加所有文件
echo "添加文件到 Git..."
git add -A

# 提交
echo "提交更改..."
git commit -m "DYYY v2.0 模块化重构 + Swift Hook 安全模式

✨ 新增功能:
- Swift Hook 安全模式管理器 (零崩溃降级)
- DYYY.xm 模块化拆分 (Video/Comment/Live/UI Hooks)
- API 接口优化 (支持新版抖音)
- Makefile 模块化支持

📁 新增文件:
- DYYYSwiftHookManager.h/m
- DYYYSwiftHooksSafe.m
- DYYYVideoHooks.xm
- DYYYCommentHooks.xm
- DYYYLiveHooks.xm
- DYYYUIHooks.xm
- Makefile.modular

🔧 优化内容:
- API: https://api.qsy.ink/api/douyin
- 重试机制: 最多3次
- 错误处理: 增强
- Swift Hook: 7个安全模式实现"

# 检查远程仓库
if ! git remote -v | grep -q "origin"; then
    echo "请设置远程仓库地址:"
    echo "git remote add origin https://github.com/YOUR_USERNAME/DYYY-optimized.git"
    echo ""
    echo "或者使用 SSH:"
    echo "git remote add origin [email protected]:YOUR_USERNAME/DYYY-optimized.git"
    exit 1
fi

# 推送到 GitHub
echo "推送到 GitHub..."
git push -u origin main

echo ""
echo "=========================================="
echo "上传完成！"
echo "=========================================="
