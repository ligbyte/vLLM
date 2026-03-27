# OpenClaw 切换到本地模型教程

## 背景与需求

在执行自动化任务时，为了保持流畅、避免卡顿和频繁触发上下文长度限制，选择一个合适的开源模型非常关键。

对于 OpenClaw 来说，模型需要具备：

- 良好的推理能力和语言理解能力
- 稳定的工具调用（Tool Calling）能力（在自动化任务中尤为重要）

## Ollama 的局限性

很多人在第一次尝试本地部署模型时会选择 Ollama，其优点是安装简单、配置方便。

但在 OpenClaw 这种自动化任务场景下，Ollama 存在以下问题：

1. 推理速度较慢
2. 上下文长度很容易被耗尽
3. 连续运行多个任务后经常出现上下文不够用的情况

## 推荐解决方案

### 部署场景与框架选择

- **远程集群/多 Agent 场景**：推荐使用 SGLang
- **单卡本地部署**：强烈推荐 vLLM

目前来看，vLLM 可以说是单机部署 OpenClaw 的最佳解决方案之一。

## vLLM 部署本地模型完整流程

### 准备工作

建议安装 Windows Terminal（一款新式、快速、高效、强大且高效的 Windows 终端程序），方便切换不同的系统。

### 安装步骤

#### 1. 安装 WSL2

在 PowerShell（管理员）执行：

```powershell
wsl --install
```

安装完成后重启电脑，然后安装 Ubuntu。

检查版本：

```bash
wsl -l -v
```

确保输出结果是：WSL2

#### 2. 配置 GPU 支持

先确认 Windows 已安装 NVIDIA 驱动。

检查：

```bash
nvidia-smi
```

然后在 WSL Ubuntu 里运行：

```bash
nvidia-smi
```

如果出现显卡信息说明 GPU 直通成功。

#### 3. 安装 Python 环境

更新系统：

```bash
sudo apt update && sudo apt upgrade -y
```

安装 Python：

```bash
sudo apt install python3 python3-pip python3-venv -y
```

创建虚拟环境：

```bash
python3 -m venv vllm-env
```

进入环境：

```bash
source vllm-env/bin/activate
```

#### 4. 安装 vLLM

安装命令：

```bash
pip install vllm
```

安装完成后测试：

```bash
python -c "import vllm; print('vLLM installed successfully')"
```

### 模型选择

**推荐模型**：Qwen/Qwen2.5-14B-Instruct-AWQ

**模型优点**：

- 中文能力强
- Agent 能力好
- 支持更全面的工具调用能力

> **显存提示**：本教程演示使用的是 24GB 显存显卡。如果你的显存更小，建议选择参数规模更小的模型，否则在加载模型时可能会出现显存不足（Out of Memory）的问题。
>
> 如果显存不够大，可以选择：
>
> - Qwen2.5-7B-Instruct-AWQ
> - Qwen2.5-4B 等更小的模型

### 启动 vLLM 服务

运行命令：

```bash
python -m vllm.entrypoints.openai.api_server \
    --model Qwen/Qwen2.5-14B-Instruct-AWQ \
    --served-model-name Qwen2.5-14B-Instruct-AWQ \
    --api-key 123456 \
    --max-model-len 8192 \
    --gpu-memory-utilization 0.9 \
    --enforce-eager \
    --disable-log-requests
```

成功后会看到：

```
INFO:     Started server process [1234]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
```

说明 API 已启动成功。

### 测试连接

在 Windows PowerShell 测试：

```powershell
curl http://127.0.0.1:8000/v1/models
```

返回模型信息：

```
Qwen/Qwen2.5-14B-Instruct-AWQ
```

说明连接正常。

## 配置 OpenClaw

### 安装 OpenClaw

在 WSL 子系统里执行安装命令：

先安装 Node.js：

```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
```

再执行安装 OpenClaw：

```bash
npm install -g openclaw@latest
```

### 配置模型

进入配置：

```bash
openclaw onboard
```

添加模型：

- **模型提供商**：必须选择自定义的
- **Base URL**：`http://127.0.0.1:8000/v1`
- **API Key**：123456（随便填写）
- **模型名称**：Qwen2.5-14B-Instruct-AWQ

最后保存即可！

## 优化配置建议

### OpenClaw 参数设置

为了避免卡顿：

- **Context length**：6000–8000
- **Temperature**：0.7
- **Max tokens**：2048

### vLLM 启动参数建议

```bash
--max-model-len 8192 \
--gpu-memory-utilization 0.9 \
--enforce-eager \
--disable-log-requests
```

> **注意**：这是 RTX 4090 显卡的配置，请根据你自己的显卡显存来适当修改 `max-model-len` 后面的参数。

### 效果优化

- **Prefix cache**：加速 prompt
- **GPU 利用率更高**

### 内存优化技巧

在 OpenClaw System Prompt 添加：

```
When the conversation becomes long, summarize previous messages into a short memory. Keep the memory under 200 tokens.
```

这样：8000 token → 200 token memory，速度不会下降。

## 总结

**Qwen2.5-14B-Instruct-AWQ** 本地模型跑 OpenClaw 就完全够用。
