#!/bin/bash

# ==============================================================================
# 全局配置变量 (在此处修改模型和路径)
# ==============================================================================

# 1. 模型标识 (ModelScope ID)
MODEL_ID="deepseek-ai/DeepSeek-R1-Distill-Qwen-1.5B"

# 2. 缓存根目录 (使用 $HOME 自动适配当前用户)
CACHE_DIR="$HOME/AI/vllm/models/deepseekr1_1.5b"

# 3. Conda 环境名称
ENV_NAME="vllm"

# 4. Python 版本
PYTHON_VERSION="3.12.9"

# 5. Miniconda 默认安装路径 (仅在需要自动安装时使用)
DEFAULT_MINICONDA_PATH="$HOME/miniconda3"
MINICONDA_INSTALLER="$HOME/miniconda.sh"

# ==============================================================================
# 脚本逻辑开始
# ==============================================================================

set -e # 遇到错误立即退出

echo "=========================================="
echo "🚀 vLLM + DeepSeek 自动化部署脚本"
echo "=========================================="
echo "当前用户: $(whoami)"
echo "主目录: $HOME"
echo "模型 ID: $MODEL_ID"
echo "缓存目录: $CACHE_DIR"
echo "=========================================="

# --- 1. 检测并初始化 Conda 环境 ---
CONDA_FOUND=false
CONDA_SH_PATH=""

# 检查 conda 命令是否在全局路径中可用
if command -v conda &> /dev/null; then
    echo "✅ 检测到 'conda' 命令已在全局环境中可用。"
    CONDA_FOUND=true
    
    # 尝试获取 conda 的基础路径以便 source conda.sh
    # 方法：运行 conda info --base
    CONDA_BASE=$(conda info --base 2>/dev/null)
    
    if [ -n "$CONDA_BASE" ] && [ -f "$CONDA_BASE/etc/profile.d/conda.sh" ]; then
        CONDA_SH_PATH="$CONDA_BASE/etc/profile.d/conda.sh"
        echo "   找到 Conda 基础路径: $CONDA_BASE"
    else
        echo "⚠️ 警告: 虽然找到了 conda 命令，但无法自动定位 profile.d/conda.sh。"
        echo "   尝试使用默认路径: $DEFAULT_MINICONDA_PATH"
        if [ -f "$DEFAULT_MINICONDA_PATH/etc/profile.d/conda.sh" ]; then
            CONDA_SH_PATH="$DEFAULT_MINICONDA_PATH/etc/profile.d/conda.sh"
        fi
    fi
else
    echo "⏳ 未检测到 'conda' 命令，准备安装 Miniconda..."
    CONDA_FOUND=false
fi

# 如果需要安装，则执行安装流程
if [ "$CONDA_FOUND" = false ]; then
    if [ ! -d "$DEFAULT_MINICONDA_PATH" ]; then
        echo "📥 正在下载 Miniconda 安装器..."
        if [ ! -f "$MINICONDA_INSTALLER" ]; then
            wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O "$MINICONDA_INSTALLER"
        fi
        
        echo "🔧 正在静默安装 Miniconda 到 $DEFAULT_MINICONDA_PATH ..."
        bash "$MINICONDA_INSTALLER" -b -p "$DEFAULT_MINICONDA_PATH"
        
        CONDA_SH_PATH="$DEFAULT_MINICONDA_PATH/etc/profile.d/conda.sh"
        echo "✅ Miniconda 安装完成。"
    else
        echo "⚠️ Miniconda 目录已存在 ($DEFAULT_MINICONDA_PATH)，但未在 PATH 中找到 conda 命令。"
        echo "   尝试直接使用该目录的配置..."
        CONDA_SH_PATH="$DEFAULT_MINICONDA_PATH/etc/profile.d/conda.sh"
        if [ ! -f "$CONDA_SH_PATH" ]; then
            echo "❌ 错误: 在 $DEFAULT_MINICONDA_PATH 下未找到 conda.sh，安装可能已损坏。"
            exit 1
        fi
    fi
fi

# 加载 Conda 环境
if [ -n "$CONDA_SH_PATH" ] && [ -f "$CONDA_SH_PATH" ]; then
    echo "⚡ 正在加载 Conda 环境配置..."
    source "$CONDA_SH_PATH"
else
    echo "❌ 错误: 无法找到 conda.sh 脚本，无法激活环境。"
    exit 1
fi

# --- 2. 创建/激活 Conda 环境 ---
if conda env list | grep -q "^$ENV_NAME "; then
    echo "✅ Conda 环境 '$ENV_NAME' 已存在，跳过创建。"
else
    echo "⏳ 正在创建 Conda 环境 '$ENV_NAME' (Python $PYTHON_VERSION)..."
    conda create -n "$ENV_NAME" python=$PYTHON_VERSION -y
    echo "✅ 环境创建完成。"
fi

echo "⚡ 激活环境: $ENV_NAME"
conda activate "$ENV_NAME"

# --- 3. 安装 Python 依赖 ---
echo "⏳ 正在安装 vllm 和 modelscope (使用清华源)..."
pip install vllm -i https://pypi.tuna.tsinghua.edu.cn/simple
pip install modelscope -i https://pypi.tuna.tsinghua.edu.cn/simple
echo "✅ 依赖安装完成。"

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
echo "⏳ 正在定位模型实际路径..."
MODEL_SUFFIX=$(basename "$MODEL_ID")
FOUND_PATH=$(find "$CACHE_DIR" -type d -name "$MODEL_SUFFIX" | head -n 1)

if [ -z "$FOUND_PATH" ]; then
    echo "⚠️ 警告：未能通过名称自动找到模型子目录，尝试使用缓存根目录。"
    MODEL_PATH="$CACHE_DIR"
else
    MODEL_PATH="$FOUND_PATH"
    echo "✅ 找到模型路径: $MODEL_PATH"
fi

# 验证路径有效性
if [ ! -f "$MODEL_PATH/config.json" ] && [ ! -f "$MODEL_PATH/model.safetensors" ]; then
    DEEPER_PATH=$(find "$MODEL_PATH" -maxdepth 2 -name "config.json" | head -n 1)
    if [ -n "$DEEPER_PATH" ]; then
        MODEL_PATH=$(dirname "$DEEPER_PATH")
        echo "✅ 修正后的模型路径: $MODEL_PATH"
    else
        echo "❌ 错误：在 $MODEL_PATH 下未找到有效的模型文件。"
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
vllm serve "$MODEL_PATH" --dtype=half