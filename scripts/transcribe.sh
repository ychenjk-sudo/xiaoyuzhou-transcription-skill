#!/usr/bin/env bash
# 小宇宙播客音频转录脚本
# 使用 Qwen ASR (qwen3-asr-flash-filetrans) 异步转录
#
# 用法: ./transcribe.sh <xiaoyuzhou_url_or_audio_url> [output_file]
# 环境变量: QWEN_API_KEY (必需)

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $*" >&2; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# 检查依赖
check_deps() {
    local missing=()
    for cmd in curl jq; do
        if ! command -v "$cmd" &> /dev/null; then
            missing+=("$cmd")
        fi
    done
    if [ ${#missing[@]} -gt 0 ]; then
        log_error "缺少依赖: ${missing[*]}"
        log_error "请先安装: apt-get install ${missing[*]}"
        exit 1
    fi
}

# 从小宇宙页面提取音频URL
extract_audio_url() {
    local page_url="$1"
    log_info "提取音频URL: $page_url"
    
    local html
    html=$(curl -sL "$page_url")
    
    local audio_url
    audio_url=$(echo "$html" | grep -oE 'https://media\.xyzcdn\.net/[^"]+\.(mp3|m4a)' | head -1)
    
    if [ -z "$audio_url" ]; then
        audio_url=$(echo "$html" | grep -oE '"enclosureUrl":"[^"]+"' | head -1 | sed 's/"enclosureUrl":"//;s/"$//')
    fi
    
    if [ -z "$audio_url" ]; then
        log_error "无法提取音频URL，请检查链接是否有效"
        exit 1
    fi
    
    echo "$audio_url"
}

# 提交转录任务
submit_task() {
    local audio_url="$1"
    log_info "提交转录任务 (qwen3-asr-flash-filetrans)..."
    
    local response
    response=$(curl -s --location --request POST 'https://dashscope.aliyuncs.com/api/v1/services/audio/asr/transcription' \
        --header "Authorization: Bearer $QWEN_API_KEY" \
        --header "Content-Type: application/json" \
        --header "X-DashScope-Async: enable" \
        --data "{
            \"model\": \"qwen3-asr-flash-filetrans\",
            \"input\": {
                \"file_url\": \"$audio_url\"
            },
            \"parameters\": {
                \"channel_id\": [0],
                \"language\": \"zh\",
                \"enable_itn\": true
            }
        }")
    
    local task_id
    task_id=$(echo "$response" | jq -r '.output.task_id // empty')
    
    if [ -z "$task_id" ]; then
        log_error "提交任务失败:"
        echo "$response" | jq . >&2 2>/dev/null || echo "$response" >&2
        exit 1
    fi
    
    log_info "任务ID: $task_id"
    echo "$task_id"
}

# 轮询任务状态
poll_task() {
    local task_id="$1"
    local max_wait=3600
    local interval=10
    local elapsed=0
    
    log_info "等待转录完成..."
    
    while [ $elapsed -lt $max_wait ]; do
        local response
        response=$(curl -s --location --request GET "https://dashscope.aliyuncs.com/api/v1/tasks/$task_id" \
            --header "Authorization: Bearer $QWEN_API_KEY" \
            --header "Content-Type: application/json")
        
        local status
        status=$(echo "$response" | jq -r '.output.task_status // empty')
        
        case "$status" in
            SUCCEEDED)
                log_info "转录完成!"
                local result_url
                result_url=$(echo "$response" | jq -r '.output.result.transcription_url // empty')
                if [ -z "$result_url" ]; then
                    log_error "无法获取结果URL"
                    exit 1
                fi
                echo "$result_url"
                return 0
                ;;
            FAILED)
                log_error "转录失败:"
                echo "$response" | jq '.output' >&2 2>/dev/null || echo "$response" >&2
                exit 1
                ;;
            PENDING|RUNNING)
                local minutes=$((elapsed / 60))
                local seconds=$((elapsed % 60))
                printf "\r${YELLOW}[等待]${NC} 状态: %s, 已等待: %02d:%02d" "$status" "$minutes" "$seconds" >&2
                sleep $interval
                elapsed=$((elapsed + interval))
                ;;
            *)
                log_error "未知状态: $status"
                echo "$response" | jq . >&2 2>/dev/null || echo "$response" >&2
                exit 1
                ;;
        esac
    done
    
    log_error "超时: 转录任务未在 $max_wait 秒内完成"
    exit 1
}

# 下载结果
fetch_result() {
    local result_url="$1"
    local output_file="$2"
    
    log_info "下载转录结果..."
    curl -sL "$result_url" > "$output_file"
    log_info "已保存到: $output_file"
}

# 主函数
main() {
    if [ $# -lt 1 ]; then
        echo "用法: $0 <xiaoyuzhou_url_or_audio_url> [output_file]" >&2
        echo "示例: $0 'https://www.xiaoyuzhoufm.com/episode/xxxxx' output.json" >&2
        exit 1
    fi
    
    local input_url="$1"
    local output_file="${2:-/tmp/transcript_raw.json}"
    
    if [ -z "${QWEN_API_KEY:-}" ]; then
        log_error "请设置环境变量 QWEN_API_KEY"
        exit 1
    fi
    
    check_deps
    
    # Step 1: 确定音频URL
    local audio_url
    if [[ "$input_url" == *"xiaoyuzhoufm.com"* ]]; then
        audio_url=$(extract_audio_url "$input_url")
    elif [[ "$input_url" == *".mp3"* ]] || [[ "$input_url" == *".m4a"* ]] || [[ "$input_url" == *".wav"* ]]; then
        audio_url="$input_url"
    else
        log_error "无法识别的URL格式"
        exit 1
    fi
    log_info "音频URL: $audio_url"
    
    # Step 2: 提交任务
    local task_id
    task_id=$(submit_task "$audio_url")
    
    # Step 3: 轮询结果
    echo "" >&2
    local result_url
    result_url=$(poll_task "$task_id")
    echo "" >&2
    
    # Step 4: 下载结果
    fetch_result "$result_url" "$output_file"
    
    # 输出纯文本预览
    log_info "转录文本预览:"
    jq -r '.transcripts[0].text' "$output_file" 2>/dev/null | head -c 500
    echo "..."
}

main "$@"
