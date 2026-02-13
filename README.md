# 小宇宙播客转录 Skill

将小宇宙播客链接自动转录为文字，生成结构化总结和逐字稿。

## 功能特性

- 🎙️ 自动提取小宇宙音频链接
- 🤖 使用 Qwen ASR (qwen3-asr-flash-filetrans) 转录，支持 8 小时长音频
- 👥 按说话人分段 + 时间戳
- 📝 超过 300 字自动分段
- 📌 AI 生成核心要点和 Q&A（按主题分组）

## 模型配置

| 步骤 | 模型 | 说明 |
|------|------|------|
| ASR 转录 | `qwen3-asr-flash-filetrans` | 阿里云语音识别 |
| 核心要点 | OpenClaw 当前会话模型 | 由 Agent 生成 |
| 关键问答 | OpenClaw 当前会话模型 | 由 Agent 生成 |
| 逐字稿格式化 | 无需模型 | Python 脚本处理 |

## 安装

```bash
git clone https://github.com/ychenjk-sudo/xiaoyuzhou-transcription-skill.git
cp -r xiaoyuzhou-transcription-skill /path/to/openclaw/skills/xiaoyuzhou-transcription
```

## 环境变量

```bash
export QWEN_API_KEY="sk-xxx"  # 阿里云 DashScope API Key
```

## 使用方法

### 方式一：直接发送链接给 OpenClaw

发送小宇宙链接，OpenClaw 会自动识别并执行转录流程。

### 方式二：手动执行脚本

```bash
# Step 1: 转录音频
./scripts/transcribe.sh "https://www.xiaoyuzhoufm.com/episode/xxxxx" /tmp/raw.json

# Step 2: 格式化逐字稿
python3 ./scripts/format_transcript.py /tmp/raw.json /tmp/formatted.md

# Step 3: 由 Agent 生成核心要点和 Q&A
```

## 输出格式

```markdown
# [播客名称] [期号]｜[标题]

**播客链接**: https://www.xiaoyuzhoufm.com/episode/xxxxx  
**主播**: [主播名]（[身份介绍]）  
**嘉宾**: [嘉宾名]（[身份介绍]）

---

## 📌 核心要点

### 1. [主题一]
- 要点内容
- 要点内容

### 2. [主题二]
- 要点内容

...

---

## ❓ 关键问答

### Q1: [问题]？
[回答内容]

### Q2: [问题]？
[回答内容]

...

---

## 📝 逐字稿

**说话人** [00:00:00]
段落内容...

**说话人** [00:01:23]
段落内容...
```

## 文件结构

```
xiaoyuzhou-transcription/
├── SKILL.md                    # OpenClaw 技能说明
├── README.md                   # 本文件
└── scripts/
    ├── transcribe.sh          # 转录脚本
    └── format_transcript.py   # 格式化脚本
```

## 依赖

- `curl`
- `jq`
- `python3`

## License

MIT
