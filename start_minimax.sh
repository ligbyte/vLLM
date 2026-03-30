#!/bin/bash

# ==========================================
# vLLM 服务启动脚本 (自动推断模型路径版)
# ==========================================

# 1. 定义模型标识与缓存目录
# 模型标识 (ModelScope ID)
MODEL_ID="deepseek-ai/DeepSeek-R1-Distill-Qwen-1.5B"

# 缓存根目录 (使用 $HOME 自动适配当前用户)
CACHE_DIR="$HOME/AI/vllm/models/MiniMax_M2.1"

# 2. 自动推断 MODEL_PATH
# 拼接完整路径：缓存目录 + 模型ID
MODEL_PATH="${CACHE_DIR}/${MODEL_ID}"

# 3. 预检查：检查目录是否存在
if [ ! -d "$MODEL_PATH" ]; then
    echo "⚠️  警告: 未检测到模型文件"
    echo "   推断路径: $MODEL_PATH"
    echo "   原因: 目录不存在。请先使用 modelscope download 或 huggingface-cli 下载模型。"
    echo ""
    echo "   例如使用 modelscope 下载:"
    echo "   modelscope download $MODEL_ID --local_dir $MODEL_PATH"
    exit 1
fi

# 4. 检查 conda 命令是否存在
if ! command -v conda &> /dev/null; then
    echo "❌ 错误: 未找到 conda 命令，请确保已安装 Anaconda 或 Miniconda。"
    exit 1
fi

# 5. 激活 vllm 环境
echo "🔄 正在激活 conda 环境: vllm ..."
# 初始化 conda shell 钩子，确保在脚本中 activate 生效
source $(conda info --base)/etc/profile.d/conda.sh
conda activate vllm

# 检查激活是否成功
if [ $? -ne 0 ]; then
    echo "❌ 错误: 激活 conda 环境 'vllm' 失败，请检查环境是否存在。"
    exit 1
fi

# 6. 打印启动信息
echo "🚀 正在启动 vLLM 服务..."
echo "   模型: $MODEL_ID"
echo "   路径: $MODEL_PATH"
echo "   命令: vllm serve $MODEL_PATH --host 0.0.0.0 --port 8000 --trust-remote-code --gpu-memory-utilization 0.8 --max-model-len 2048"
echo "------------------------------------------"

# 7. 启动 vLLM 服务
vllm serve "$MODEL_PATH" --host 0.0.0.0 --port 8000 --gpu-memory-utilization 0.8 --reasoning-parser deepseek_r1 --max-model-len 1024 --enable-auto-tool-choice --tool-call-parser hermes  --quantization bitsandbytes --override-generation-config '{"temperature": 0.6, "top_p": 0.95, "top_k": 20}'