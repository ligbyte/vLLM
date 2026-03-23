#!/bin/bash

# ==========================================
# 全局配置变量 (在此处修改模型和路径)
# ==========================================

# 模型标识 (ModelScope ID)
MODEL_ID="deepseek-ai/DeepSeek-R1-Distill-Qwen-1.5B"

# 缓存根目录 (模型将下载到此目录下的子文件夹中)
# 注意：脚本会自动创建此目录
CACHE_DIR="/home/lime/AI/vllm/models/deepseekr1_1.5b"

# Conda 环境名称
ENV_NAME="vllm"

# Python 版本
PYTHON_VERSION="3.12.9"

# Miniconda 安装路径
MINICONDA_PATH="$HOME/miniconda3"
MINICONDA_INSTALLER="$HOME/miniconda.sh"

# ==========================================
# 脚本逻辑开始
# ==========================================

set -e # 遇到错误立即退出

echo "=========================================="
echo "配置确认:"
echo "  模型 ID: $MODEL_ID"
echo "  缓存目录: $CACHE_DIR"
echo "  Conda 环境: $ENV_NAME"
echo "=========================================="

# 1. 初始化 Conda
if [ ! -d "$MINICONDA_PATH" ]; then
    echo "Miniconda 未检测到，开始下载并安装..."
    if [ ! -f "$MINICONDA_INSTALLER" ]; then
        wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O "$MINICONDA_INSTALLER"
    fi
    bash "$MINICONDA_INSTALLER" -b -p "$MINICONDA_PATH"
fi

# 加载 Conda 环境
source "$MINICONDA_PATH/etc/profile.d/conda.sh"

# 2. 创建/激活 Conda 环境
if conda env list | grep -q "^$ENV_NAME "; then
    echo "环境 $ENV_NAME 已存在。"
else
    echo "正在创建环境 $ENV_NAME (Python $PYTHON_VERSION)..."
    conda create -n "$ENV_NAME" python=$PYTHON_VERSION -y
fi

echo "激活环境: $ENV_NAME"
conda activate "$ENV_NAME"

# 3. 安装依赖
echo "正在安装 vllm 和 modelscope..."
pip install vllm -i https://pypi.tuna.tsinghua.edu.cn/simple
pip install modelscope -i https://pypi.tuna.tsinghua.edu.cn/simple

# 4. 创建模型下载脚本
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOWNLOAD_SCRIPT="$SCRIPT_DIR/down_model.py"

echo "生成下载脚本: $DOWNLOAD_SCRIPT"
cat > "$DOWNLOAD_SCRIPT" <<EOF
from modelscope import snapshot_download
import os

model_id = "$MODEL_ID"
cache_dir = "$CACHE_DIR"

print(f"开始下载模型: {model_id}")
print(f"缓存路径: {cache_dir}")

try:
    model_dir = snapshot_download(
        model_id, 
        cache_dir=cache_dir, 
        revision='master'
    )
    print(f"下载成功！实际路径: {model_dir}")
except Exception as e:
    print(f"下载失败: {e}")
    exit(1)
EOF

# 5. 执行下载
echo "------------------------------------------"
echo "开始下载模型 (这可能耗时较长，请耐心等待)..."
echo "------------------------------------------"
mkdir -p "$CACHE_DIR"
python "$DOWNLOAD_SCRIPT"

# 6. 自动定位模型实际路径
# ModelScope 通常在 cache_dir 下创建 "作者名/模型名" 的嵌套结构
# 我们需要找到那个包含模型文件的具体文件夹
echo "正在定位模型实际路径..."

# 策略：在 CACHE_DIR 中递归查找包含 "DeepSeek-R1-Distill-Qwen-1.5B" 的目录
# 如果模型名改变，这里依赖的是 MODEL_ID 的后半部分
MODEL_SUFFIX=$(basename "$MODEL_ID")
FOUND_PATH=$(find "$CACHE_DIR" -type d -name "$MODEL_SUFFIX" | head -n 1)

if [ -z "$FOUND_PATH" ]; then
    echo "警告：未能通过名称自动找到模型路径。尝试使用缓存目录作为默认路径..."
    MODEL_PATH="$CACHE_DIR"
else
    MODEL_PATH="$FOUND_PATH"
fi

# 验证路径是否有效 (检查是否存在 config.json 或类似的核心文件)
if [ ! -f "$MODEL_PATH/config.json" ] && [ ! -f "$MODEL_PATH/model.safetensors" ]; then
    echo "错误：在路径 $MODEL_PATH 下未找到有效的模型文件。"
    echo "请手动检查 $CACHE_DIR 目录结构。"
    exit 1
fi

echo "模型路径确认为: $MODEL_PATH"

# 7. 启动提示
echo ""
echo "=========================================="
echo "✅ 环境准备与模型下载完成！"
echo "=========================================="
echo ""
echo "即将启动 vLLM 服务..."
echo "模型: $MODEL_ID"
echo "路径: $MODEL_PATH"
echo "精度: half (FP16)"
echo ""
echo "执行命令:"
echo "vllm serve $MODEL_PATH --dtype=half"
echo ""
echo "------------------------------------------"

# 8. 启动服务
# 如果希望脚本在执行完下载后自动挂起并运行服务，取消下面一行的注释
vllm serve "$MODEL_PATH" --dtype=half