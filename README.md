# vLLM


conda remove --name vllm --all;rm -rfv models/;rm -rfv down_model.py

conda remove --name vllm --all

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

nvm install --lts    # 安装最新的LTS版本

nvm list  # Windows
nvm ls    # macOS/Linux

nvm use 18.19.0  # 切换到指定版本
nvm use --lts    # 切换到LTS版本

nvm alias default 18.19.0




node -v

## claude-code 安装
npm install -g @anthropic-ai/claude-code
claude -v

## codex安装
npm install -g @openai/codex
codex -V

## gemini安装
npm install -g @google/gemini-cli
gemini -v


## opencode安装
cargo install opencode


## openclaw 安装
sudo npm install -g openclaw@latest
openclaw onboard
openclaw configure






# 清除现有配置
conda config --remove-key channels

# 添加清华源
conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main/
conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free/
conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/pytorch/
conda config --set show_channel_urls yes


```shell



#下载
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh
#安装，该操作会下载800m 的文件
bash miniconda.sh 


conda create --name vllm python=3.12.9

conda activate vllm

pip install vllm -i https://pypi.tuna.tsinghua.edu.cn/simple
pip install modelscope -i https://pypi.tuna.tsinghua.edu.cn/simple

```






## 7.启动模型

vllm serve /home/lime/AI/vllm/models/deepseekr1_1.5b/deepseek-ai/DeepSeek-R1-Distill-Qwen-1.5B --dtype=half


## 8.访问模型

curl http://127.0.0.1:8000/v1/models



## 9. 常见问题与解决方案

- **显存不足**：若显存不足，尝试量化（如 AWQ）或减少 `max-model-len`。
- **Tokenization 错误**：确保转换脚本中使用 `trust_remote_code=True`，并验证 `config.json` 中的 `auto_map` 配置。
- **API 调用失败**：检查服务端口是否被占用，或防火墙设置是否允许访问。

## 10. 优化建议

- **量化部署**：使用 AWQ 量化可将显存需求降至 10GB 以下，适合消费级显卡。
- **参数调整**：根据文档推荐，设置 `temperature=0.6`、`top_p=0.95` 以平衡创造力与稳定性。

通过以上步骤，即可在本地环境中高效部署 GLM-Z1-9B 模型，并通过 API 进行推理。
	
	
	
	
	
	
	
	
	
______________________________________________________________________________________________________________________________________________________________________________	
	
	
https://www.cnblogs.com/yisheng163/p/19048799
	
conda config --add channels https://mirrors.aliyun.com/anaconda/pkgs/main/
conda config --add channels https://mirrors.aliyun.com/anaconda/pkgs/free/
conda config --add channels https://mirrors.aliyun.com/anaconda/pkgs/r/
conda config --add channels https://mirrors.aliyun.com/anaconda/pkgs/msys2/
conda config --add channels https://mirrors.aliyun.com/anaconda/cloud/conda-forge/
conda config --add channels https://mirrors.aliyun.com/anaconda/cloud/pytorch/




conda create -n vllm_numpy_pytorch python=3.10 numpy=1.26.4 pytorch=2.1.0 torchvision=0.16.0 cudatoolkit=12.1
conda activate vllm_numpy_pytorch   #激活，激活后，终端前缀会显示 (vllm_numpy_pytorch)，表示环境已启用。


conda deactivate  退出
conda remove -n vllm_env --all   删除　


conda install pytorch torchvision torchaudio cudatoolkit=12.1

pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

python -c "import torch; print('PyTorch版本:', torch.__version__); print('CUDA可用:', torch.cuda.is_available()); print('CUDA版本:', torch.version.cuda); print('GPU设备:', torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'None')"

python -c "import vllm; print(vllm.__version__)"

pip install vllm==0.9.0   # 已知稳定版本

modelscope download --model Qwen/Qwen2.5-0.5B-Instruct

vllm serve /home/admin1/.cache/modelscope/hub/models/Qwen/Qwen2.5-0.5B-Instruct --port 8000 --gpu-memory-utilization 0.3


pip install "transformers==4.51.0" --upgrade

curl http://localhost:8000/v1/models


用curl调用测试模型问答：

curl -X POST "http://localhost:8000/v1/chat/completions" \
-H "Content-Type: application/json" \
-d '{
  "model": "/home/admin1/.cache/modelscope/hub/models/Qwen/Qwen2.5-0.5B-Instruct",
  "messages": [{"role": "user", "content": "介绍下杭州"}]
}'