#!/usr/bin/env python3
"""
格式化播客转录结果
- 按说话人分段
- 超过300字自动分段
- 添加时间戳
"""

import json
import sys
import re

def ms_to_timestamp(ms):
    """毫秒转时间戳 HH:MM:SS"""
    seconds = ms // 1000
    h = seconds // 3600
    m = (seconds % 3600) // 60
    s = seconds % 60
    return f"{h:02d}:{m:02d}:{s:02d}"

def detect_speaker(text, current_speaker):
    """通过内容特征检测说话人"""
    speaker_markers = {
        '刘一鸣': ['我是刘一鸣', '我是特约研究员刘一鸣', '我是一鸣'],
        '知县': ['我是知县', '大家好我是知线', '我是知线', '大家好，我是知县'],
        '华祯豪': ['我是郑豪', '我是真豪', 'Hello大家好我是郑豪', '我是华祯豪'],
        '叶天奇': ['我是天奇', '我是叶天奇', '大家好，我是天奇'],
    }
    
    for speaker, markers in speaker_markers.items():
        for marker in markers:
            if marker in text:
                return speaker
    return current_speaker

def format_transcript(json_path, output_path, max_chars=300):
    """格式化转录结果"""
    with open(json_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    # 检查数据结构
    if 'transcripts' not in data or not data['transcripts']:
        print("错误: JSON 中没有 transcripts 字段", file=sys.stderr)
        sys.exit(1)
    
    transcript = data['transcripts'][0]
    
    # 优先使用 sentences，否则用 text
    if 'sentences' in transcript and transcript['sentences']:
        sentences = transcript['sentences']
    else:
        # 如果没有 sentences，按标点分割 text
        text = transcript.get('text', '')
        sentences = [{'text': s, 'begin_time': 0} for s in re.split(r'[。！？]', text) if s.strip()]
    
    output_lines = []
    current_speaker = "主持人"
    segment_text = ""
    segment_start = 0
    char_count = 0
    
    for i, sent in enumerate(sentences):
        text = sent.get('text', '')
        begin_time = sent.get('begin_time', 0)
        
        # 检测说话人切换
        new_speaker = detect_speaker(text, current_speaker)
        if new_speaker != current_speaker:
            # 先输出之前积累的内容
            if segment_text.strip():
                output_lines.append(f"\n**{current_speaker}** [{ms_to_timestamp(segment_start)}]\n")
                output_lines.append(segment_text.strip() + "\n")
            current_speaker = new_speaker
            segment_text = ""
            segment_start = begin_time
            char_count = 0
        
        segment_text += text
        char_count += len(text)
        
        # 超过 max_chars 字自动分段
        if char_count >= max_chars:
            output_lines.append(f"\n**{current_speaker}** [{ms_to_timestamp(segment_start)}]\n")
            output_lines.append(segment_text.strip() + "\n")
            segment_text = ""
            if i + 1 < len(sentences):
                segment_start = sentences[i + 1].get('begin_time', begin_time)
            char_count = 0
    
    # 输出最后一段
    if segment_text.strip():
        output_lines.append(f"\n**{current_speaker}** [{ms_to_timestamp(segment_start)}]\n")
        output_lines.append(segment_text.strip() + "\n")
    
    with open(output_path, 'w', encoding='utf-8') as f:
        f.writelines(output_lines)
    
    print(f"✅ 格式化完成: {len(sentences)} 个句子 → {output_path}", file=sys.stderr)
    return len(sentences)

def main():
    if len(sys.argv) < 3:
        print("用法: python3 format_transcript.py <输入JSON> <输出MD>", file=sys.stderr)
        print("示例: python3 format_transcript.py /tmp/raw.json /tmp/formatted.md", file=sys.stderr)
        sys.exit(1)
    
    json_path = sys.argv[1]
    output_path = sys.argv[2]
    max_chars = int(sys.argv[3]) if len(sys.argv) > 3 else 300
    
    format_transcript(json_path, output_path, max_chars)

if __name__ == '__main__':
    main()
