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