---
name: xiaoyuzhou-transcription
description: 将小宇宙播客音频转录为文字，并生成内容总结和逐字稿。输入小宇宙链接，自动提取音频、调用Qwen ASR转录、生成核心要点和格式化逐字稿。
---

# 小宇宙播客转录与总结

将小宇宙播客链接转录为文字，生成结构化总结和逐字稿。

## 环境变量

- `QWEN_API_KEY`：阿里云 DashScope API Key（必需）

## 模型配置

| 步骤 | 模型 | 说明 |
|------|------|------|
| ASR 转录 | `qwen3-asr-flash-filetrans` | 阿里云语音识别，支持 8 小时长音频 |
| 核心要点生成 | OpenClaw 当前会话模型 | 由 Agent 直接生成 |
| 关键问答生成 | OpenClaw 当前会话模型 | 由 Agent 直接生成 |
| 逐字稿格式化 | 无需模型 | Python 脚本处理 |

## 完整工作流程

### Step 1: 转录音频

```bash
export QWEN_API_KEY="sk-xxx"
./scripts/transcribe.sh "https://www.xiaoyuzhoufm.com/episode/xxxxx" /tmp/transcript_raw.json
```

脚本会：
1. 从小宇宙页面提取音频 URL
2. 提交异步转录任务（qwen3-asr-flash-filetrans）
3. 轮询等待完成（通常 2-5 分钟）
4. 下载完整 JSON 结果

### Step 2: 格式化逐字稿

```bash
python3 ./scripts/format_transcript.py /tmp/transcript_raw.json /tmp/transcript_formatted.md
```

输出格式：
```markdown
**说话人** [HH:MM:SS]
段落内容...（超过300字自动分段）
```

### Step 3: AI 生成总结（由 Agent 执行）

读取转录文本后，Agent 使用当前会话模型生成总结。

**Prompt 模板：**

```
请基于以下播客转录内容，生成一份结构化笔记：

## 要求
1. **核心要点**：提炼 5-8 个最重要的观点或信息
2. **关键 Q&A**：生成 8-10 个问答对，覆盖核心内容
3. 使用中文，保持简洁专业

## 输出格式

# [播客标题]

## 📌 核心要点

1. **要点一**：简要说明
2. **要点二**：简要说明
...

## ❓ 关键问答

### Q1: 问题一？
A: 回答...

### Q2: 问题二？
A: 回答...

---

转录内容：
[粘贴转录文本]
```

### Step 4: 整合输出

将总结 + 逐字稿整合成完整 Markdown 文件，保存到 `/workspace/podcasts/[播客名称].md`

**最终输出格式：**

```markdown
# [播客标题]

**播客链接**: [URL]
**时长**: XX 分钟

## 嘉宾
- 嘉宾1
- 嘉宾2

---

## 📌 核心要点
...

## ❓ 关键问答
...

---

## 📝 逐字稿

**说话人** [00:00:00]
内容...
```

## 脚本说明

### transcribe.sh

```bash
# 基本用法
./scripts/transcribe.sh <小宇宙URL或音频URL> [输出文件]

# 示例
./scripts/transcribe.sh "https://www.xiaoyuzhoufm.com/episode/xxxxx" output.json
./scripts/transcribe.sh "https://media.xyzcdn.net/xxx.mp3" output.json
```

### format_transcript.py

```bash
# 格式化转录结果
python3 ./scripts/format_transcript.py <输入JSON> <输出MD> [最大字数]

# 示例
python3 ./scripts/format_transcript.py /tmp/raw.json /tmp/formatted.md 300
```

## 技术细节

- **ASR 模型**: `qwen3-asr-flash-filetrans`（支持 8 小时长音频）
- **异步转录**: 使用 X-DashScope-Async 头
- **轮询间隔**: 10 秒
- **超时**: 1 小时
- **说话人识别**: 通过内容特征（"我是XXX"）识别，非模型 diarization

## 注意事项

1. 长音频（1小时+）转录需要 2-10 分钟
2. 当前模型不支持说话人分离，通过内容特征识别说话人
3. 需要安装 `jq` 和 `python3`
4. 核心要点和 Q&A 质量取决于 OpenClaw 当前会话使用的模型
