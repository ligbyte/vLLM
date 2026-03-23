#!/bin/bash

# ==============================================================================
# 全局配置变量 (在此处修改模型和路径，其他用户无需修改即可使用)
# ==============================================================================

# 1. 模型标识 (ModelScope ID)
#    格式: "作者名/模型名"
MODEL_ID="deepseek-ai/DeepSeek-R1-Distill-Qwen-1.5B"

# 2. 缓存根目录
#    使用 $HOME 自动适配当前用户的主目录 (例如: /home/lime 或 /home/ubuntu)
#    模型将下载到此目录下的子文件夹中
CACHE_DIR="$HOME/AI/vllm/models/deepseekr1_1.5b"

# 3. Conda 环境名称
ENV_NAME="vllm"

# 4. Python 版本
PYTHON_VERSION="3.12.9"

# 5. Miniconda 安装路径 (默认安装在用户主目录下)
MINICONDA_PATH="$HOME/miniconda3"
MINICONDA_INSTALLER="$HOME/miniconda.sh"

# ==============================================================================
# 脚本逻辑开始 (通常无需修改下方代码)
# ==============================================================================

set -e # 遇到任何错误立即停止脚本

echo "=========================================="
echo "🚀 vLLM + DeepSeek 自动化部署脚本"
echo "=========================================="
echo "当前用户: $(whoami)"
echo "主目录: $HOME"
echo "模型 ID: $MODEL_ID"
echo "缓存目录: $CACHE_DIR"
echo "Conda 环境: $ENV_NAME"
echo "=========================================="

# --- 1. 检查并安装 Miniconda ---
if [ ! -d "$MINICONDA_PATH" ]; then
    echo "⏳ Miniconda 未检测到，开始下载并安装..."
    if [ ! -f "$MINICONDA_INSTALLER" ]; then
        wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O "$MINICONDA_INSTALLER"
    fi
    # -b: 批模式 (无交互), -p: 指定安装路径
    bash "$MINICONDA_INSTALLER" -b -p "$MINICONDA_PATH"
    echo "✅ Miniconda 安装完成"
else
    echo "✅ Miniconda 已存在 ($MINICONDA_PATH)"
fi

# 加载 Conda 函数到当前 Shell
source "$MINICONDA_PATH/etc/profile.d/conda.sh"

# --- 2. 创建/激活 Conda 环境 ---
if conda env list | grep -q "^$ENV_NAME "; then
    echo "✅ Conda 环境 '$ENV_NAME' 已存在"
else
    echo "⏳ 正在创建 Conda 环境 '$ENV_NAME' (Python $PYTHON_VERSION)..."
    conda create -n "$ENV_NAME" python=$PYTHON_VERSION -y
    echo "✅ 环境创建完成"
fi

echo "⏳ 激活环境: $ENV_NAME"
conda activate "$ENV_NAME"

# --- 3. 安装 Python 依赖 ---
echo "⏳ 正在安装 vllm 和 modelscope (使用清华源)..."
pip install vllm -i https://pypi.tuna.tsinghua.edu.cn/simple
pip install modelscope -i https://pypi.tuna.tsinghua.edu.cn/simple
echo "✅ 依赖安装完成"

# --- 4. 生成模型下载脚本 ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOWNLOAD_SCRIPT="$SCRIPT_DIR/down_model.py"

echo "⏳ 生成下载脚本: $DOWNLOAD_SCRIPT"
cat > "$DOWNLOAD_SCRIPT" <<EOF
from modelscope import snapshot_download
import os
import sys

model_id = "$MODEL_ID"
cache_dir = "$CACHE_DIR"

print(f"📥 开始下载模型: {model_id}")
print(f"📂 缓存路径: {cache_dir}")

try:
    # snapshot_download 会返回实际下载的完整路径
    model_dir = snapshot_download(
        model_id, 
        cache_dir=cache_dir, 
        revision='master'
    )
    print(f"✅ 下载成功！实际路径: {model_dir}")
except Exception as e:
    print(f"❌ 下载失败: {e}")
    sys.exit(1)
EOF

# --- 5. 执行模型下载 ---
echo "------------------------------------------"
echo "⏳ 开始下载模型 (这可能需要较长时间，取决于网速)"
echo "------------------------------------------"
mkdir -p "$CACHE_DIR"
python "$DOWNLOAD_SCRIPT"

# --- 6. 智能定位模型实际路径 ---
# ModelScope 下载后，路径通常是: CACHE_DIR/author_name/model_name
# 我们需要找到这个具体的子目录传给 vllm
echo "⏳ 正在定位模型实际路径..."

# 提取模型名的最后一部分 (例如: DeepSeek-R1-Distill-Qwen-1.5B)
MODEL_SUFFIX=$(basename "$MODEL_ID")

# 在缓存目录下查找匹配该名称的文件夹
FOUND_PATH=$(find "$CACHE_DIR" -type d -name "$MODEL_SUFFIX" | head -n 1)

if [ -z "$FOUND_PATH" ]; then
    echo "⚠️ 警告：未能通过名称自动找到模型子目录。"
    echo "   尝试直接使用缓存根目录: $CACHE_DIR"
    MODEL_PATH="$CACHE_DIR"
else
    MODEL_PATH="$FOUND_PATH"
    echo "✅ 找到模型路径: $MODEL_PATH"
fi

# 验证路径有效性 (检查关键文件)
if [ ! -f "$MODEL_PATH/config.json" ] && [ ! -f "$MODEL_PATH/model.safetensors" ]; then
    # 尝试再找一层 (有时 modelscope 结构可能更深)
    DEEPER_PATH=$(find "$MODEL_PATH" -maxdepth 2 -name "config.json" | head -n 1)
    if [ -n "$DEEPER_PATH" ]; then
        MODEL_PATH=$(dirname "$DEEPER_PATH")
        echo "✅ 修正后的模型路径: $MODEL_PATH"
    else
        echo "❌ 错误：在 $MODEL_PATH 下未找到有效的模型文件 (config.json 或 model.safetensors)。"
        echo "   请手动检查目录结构: ls -R $CACHE_DIR"
        exit 1
    fi
fi

# --- 7. 启动服务 ---
echo ""
echo "=========================================="
echo "🎉 环境准备与模型下载全部完成！"
echo "=========================================="
echo "📦 模型: $MODEL_ID"
echo "📂 路径: $MODEL_PATH"
echo "🔧 精度: half (FP16)"
echo ""
echo "🚀 正在启动 vLLM 服务..."
echo "   命令: vllm serve $MODEL_PATH --dtype=half"
echo "------------------------------------------"

# 启动 vLLM 服务
# 注意：此命令会占用当前终端，直到你按下 Ctrl+C 停止服务
vllm serve "$MODEL_PATH" --dtype=half