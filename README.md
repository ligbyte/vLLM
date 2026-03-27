# vLLM



conda remove --name vllm --all

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

nvm install --lts    # 安装最新的LTS版本

nvm list  # Windows
nvm ls    # macOS/Linux

nvm use 18.19.0  # 切换到指定版本
nvm use --lts    # 切换到LTS版本

nvm alias default 18.19.0

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


#创建下载文件
touch down_model.py

vim down_model.py

#touch down_model.py 文件中添加 下载代码
from modelscope import snapshot_download
model_dir = snapshot_download('deepseek-ai/DeepSeek-R1-Distill-Qwen-1.5B', 
                              cache_dir='/home/lime/AI/vllm/models/deepseekr1_1.5b', 
                              revision='master')
#执行下载
python down_model.py


7.启动模型

vllm serve /home/lime/AI/vllm/models/deepseekr1_1.5b/deepseek-ai/DeepSeek-R1-Distill-Qwen-1.5B --dtype=half


8.访问模型



import requests
import json

def stream_chat_response():
    response = requests.post(
        "http://localhost:8000/v1/chat/completions",
        json={
            "model": "/root/deepseekr1_1.5b/deepseek-ai/DeepSeek-R1-Distill-Qwen-1.5B",
            "messages": [{"role": "user", "content": "写一篇关于AI安全的短论文"}],
            "stream": True,
            "temperature": 0.7
        },
        stream=True
    )

    print("AI: ", end="", flush=True)  # 初始化输出前缀
    full_response = []

    try:
        for chunk in response.iter_lines():
            if chunk:
                # 处理数据帧
                decoded_chunk = chunk.decode('utf-8').strip()
                if decoded_chunk.startswith('data: '):
                    json_data = decoded_chunk[6:]  # 去除"data: "前缀

                    try:
                        data = json.loads(json_data)
                        if 'choices' in data and len(data['choices']) > 0:
                            delta = data['choices'][0].get('delta', {})

                            # 提取内容片段
                            content = delta.get('content', '')
                            if content:
                                print(content, end='', flush=True)  # 实时流式输出
                                full_response.append(content)

                            # 检测生成结束
                            if data['choices'][0].get('finish_reason'):
                                print("\n")  # 生成结束时换行

                    except json.JSONDecodeError:
                        pass  # 忽略不完整JSON数据

    except KeyboardInterrupt:
        print("\n\n[用户中断了生成]")

    return ''.join(full_response)

# 执行对话
if __name__ == "__main__":
    result = stream_chat_response()
    print("\n--- 完整响应 ---")
    print(result)
	
	
	
	
	
	
	
	
	
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