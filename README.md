# 小宇宙播客转录 Skill

将小宇宙播客链接自动转录为文字，生成结构化总结和逐字稿。

## 功能特性

- 🎙️ 自动提取小宇宙音频链接
- 🤖 使用 Qwen ASR (qwen3-asr-flash-filetrans) 转录，支持 8 小时长音频
- 👥 按说话人分段 + 时间戳
- 📝 超过 300 字自动分段
- 📌 AI 生成核心要点和 Q&A

## 安装

将此目录复制到你的 OpenClaw skills 目录：

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
```

## 输出格式

```markdown
# [播客标题]

## 📌 核心要点
1. **要点一**：简要说明
2. **要点二**：简要说明
...

## ❓ 关键问答
### Q1: 问题？
A: 回答...

---

## 📝 逐字稿

**说话人** [00:00:00]
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
