#!/bin/sh

usage(){
        echo "Usage:" >&2
        echo "- create: zfsbak DATASET [ROTATION_CNT]" >&2
        echo "- list: zfsbak -l|--list [DATASET|ID|DATASET ID...]" >&2
        echo "- delete: zfsbak -d|--delete [DATASET|ID|DATASET ID...]" >&2
        echo "- export: zfsbak -e|--export DATASET [ID]" >&2
        echo "- import: zfsbak -i|--import FILENAME DATASET" >&2
}

DEFAULT_ROTATION_CNT=12
SNAPSHOT_PREFIX="zfsbak_"

create_snapshot() {
    local dataset=$1 # dataset
    # 注意 dataset是zfs的邏輯分區，而非那個資料夾的路徑，因次mypool/public前面不用加/

    if [ "$2" -eq "$2" ] 2>/dev/null; then
        local rotation_cnt="$2"
    else
        local rotation_cnt="$DEFAULT_ROTATION_CNT"
    fi
    
    local timestamp=$(date +"%Y-%m-%d-%H:%M:%S")
    local snapshot_name="${dataset}@${SNAPSHOT_PREFIX}${timestamp}" # 前面是dataset名稱(mypool/...)，後面是snapshot名稱

    echo "Snap ${snapshot_name}"
    sudo zfs snapshot "$snapshot_name"


    # 刪除超過旋轉數量的舊快照
    # -t: type, -o: output, -s: sort(creation是照創造時間排序)
    local existing_snapshots=$(zfs list -t snapshot -o name -s creation | grep "^${dataset}@${SNAPSHOT_PREFIX}") # find about the dataset now
    local snapshot_count=$(echo "$existing_snapshots" | wc -l) # word count lines

    while [ "$snapshot_count" -gt "$rotation_cnt" ]; do
        local oldest_snapshot=$(echo "$existing_snapshots" | head -n 1) # find the first(oldest) and delet
        echo "Destroy $oldest_snapshot"                                                                                         sudo zfs destroy "$oldest_snapshot"
        existing_snapshots=$(zfs list -t snapshot -o name -s creation | grep "^${dataset}@  ${SNAPSHOT_PREFIX}") # find about the dataset now                                                                                                                         snapshot_count=$(echo "$existing_snapshots" | wc -l) # word count lines
        snapshot_count=$(echo "$existing_snapshots" | wc -l) # word count lines
        if [ -z "$existing_snapshots" ]; then
                break
        fi
    done
}

list_snapshots() {
    # 獲取所有快照的列表
    snapshots=$(zfs list -t snapshot -o name -s creation | grep "${SNAPSHOT_PREFIX}")

    local dataset = ""
    if [ "$1" -eq "$1" ] 2>/dev/null; then
        local id="$1"
    else
        dataset="$1"
        snapshots=$(echo "$snapshots" | grep "$1")
        local id="$2"
    fi
    

    # 檢查是否有快照
    if [ -z "$snapshots" ]; then
        echo "No snapshots found."
        return
    fi

    # 輸出標題
    printf "%-2s %-20s %-20s\n" "ID" "DATASET" "TIME"
    local index=1

    # 將快照逐行處理
    echo "$snapshots" | while read -r snapshot; do
        local snapshot_dataset=$(echo "$snapshot" | cut -d'@' -f1)
        local time=$(echo "$snapshot" | cut -d'_' -f2)

        # 如果指定了 ID，則檢查是否匹配
        if [ -n "$id" ] && [ "$index" -ne "$id" ]; then # if $id is non-zero len, and $index not equal to $id, next
            index=$((index + 1))
            continue
        fi

        # 如果指定了 DATASET，則檢查是否匹配
        if [ -n "$dataset" ] && [ "$snapshot_dataset" != "$dataset" ]; then # 避免用mypool會連到處理到mypool/public等等
            index=$((index + 1))
            continue
        fi

        # 輸出快照信息
        printf "%-2s %-20s %-20s\n" "$index" "$snapshot_dataset" "$time"
        index=$((index + 1))
    done
}

delete_snapshot() {
    local dataset=""
    local id=""
    local snapshots=$(zfs list -t snapshot -o name -s creation | grep "${SNAPSHOT_PREFIX}")
    
    if [ "$1" -eq "$1" ] 2>/dev/null; then
        id="$1"
    else
        dataset="$1"
        snapshots=$(echo "$snapshots" | grep "$1")
        id=$(echo "$2" | cut -d' ' -f3-)
    fi

    local index=1
    local flag=0

    echo "$snapshots" | while read -r snapshot; do

        local snapshot_dataset=$(echo "$snapshot" | cut -d'@' -f1)
        flag=0
        for num in $id; do
            if [ "$num" -eq "$index" ]; then
                flag=1
                break
            fi
        done

        if [ -n "$id" ] && [ "$flag" -eq 0 ]; then # if $id is non-zero len, and $index not in $id, next
            continue
        fi

        if [ -n "$dataset" ] && [ "$snapshot_dataset" != "$dataset" ]; then # 避免用mypool會連到處理到mypool/public等等
            continue
        fi

        # 輸出快照信息
        echo "Destroy $snapshot"
        sudo zfs destroy "$snapshot"
        index=$((index + 1))
    done
}

export_snapshot() {

    local DEFAULT_ZFSBAK_PASS="nijika"
    # 导出密码环境变量
    local EXPORT_PASS=${ZFSBAK_PASS:-$DEFAULT_ZFSBAK_PASS}  # 使用环境变量或默认值

    # 获取数据集和 ID
    local dataset="$1"
    local id="${2:-1}"  # 如果没有提供ID，则默认为1
    local snapshots=$(zfs list -t snapshot -o name -s creation | grep "${SNAPSHOT_PREFIX}")

    # 确认数据集是否提供
    if [ -z "$dataset" ] || [ "$dataset" -eq "$dataset" ] 2>/dev/null; then
        echo "Error: Dataset must be specified."
        exit 1
    fi

    local index=1
    local target_snapshot=""

    # 將快照逐行處理
    echo "$snapshots" | while read -r snapshot; do
        local snapshot_dataset=$(echo "$snapshot" | cut -d'@' -f1)
        local time=$(echo "$snapshot" | cut -d'_' -f2)

        # 如果指定了 DATASET，則檢查是否匹配
        if [ -n "$dataset" ] && [ "$snapshot_dataset" != "$dataset" ]; then # 避免用mypool會連到處理到mypool/public等等
            continue
        fi

        # 如果指定了 ID，則檢查是否匹配
        if [ -n "$id" ] && [ "$index" -ne "$id" ]; then # if $id is non-zero len, and $index not equal to $id, next
            index=$((index + 1))
            continue
        fi

        # 輸出快照信息
        target_snapshot="$snapshot"
        echo "$target_snapshot" > /tmp/snapshots.txt 
        break
    done

    target_snapshot=$(cat /tmp/snapshots.txt 2>/dev/null)
    rm /tmp/snapshots.txt 2>/dev/null

    # 定义导出文件名
    local snapshot_name=$(echo "$target_snapshot" | cut -d'@' -f1)
    local snapshot_back=$(echo "$target_snapshot" | cut -d'@' -f2)
    local snapshot_name1=$(echo "$snapshot_name" | cut -d'/' -f1)
    local snapshot_name2=$(echo "$snapshot_name" | cut -d'/' -f2)
    export_file="${snapshot_name1}_${snapshot_name2}@${snapshot_back}.zst.aes"

    if [ -z "$target_snapshot" ]; then
        exit 1
    fi
    # 导出快照
	local user_home=$(getent passwd | grep $SUDO_USER | cut -d: -f6)
    sudo zfs send "$target_snapshot" | zstd --compress --stdout | openssl enc -aes-256-cbc -salt -pbkdf2 -pass pass:"$EXPORT_PASS" -out "${user_home}/$export_file"

    # 检查导出是否成功
    if [ $? -eq 0 ]; then
        echo "Export $target_snapshot to ~/${target_snapshot}"
    else
        echo "Error: Export failed."
        exit 1
    fi
}

import_snapshot() {

    local filename="$1"
    filename=$(echo "$filename" | tr -d '"')
    local dataset="$2"

    if [ -z "$filename" ]; then
        echo "Error: You must specify both the filename and the dataset."
        exit 1
    fi

    local snapshot_file="/tmp/$(basename "$filename" .zst)"
    zstd -d "$filename" -o "$snapshot_file" # 把解壓縮的檔案存到snapshot_file
    zfs receive "$dataset" < "$snapshot_file"

    rm "$snapshot_file"
    echo "Import $filename to $dataset"

}

decrypt() {
    local filename="$1"
    local DEFAULT_ZFSBAK_PASS="nijika"
    local EXPORT_PASS=${ZFSBAK_PASS:-$DEFAULT_ZFSBAK_PASS}  # 使用环境变量或默认值


    # 設定臨時文件路徑（解密後文件）
    local decrypted_file="${HOME}/$(basename "$filename" .zst.aes).zst"
    echo "file_name: $filename"
    echo "decrypted: $decrypted_file"
    openssl enc -d -aes-256-cbc -pbkdf2 -pass pass:"$EXPORT_PASS" -in "$filename" -out "$decrypted_file"
    echo "decrypt $filename to $decrypted_file"

}

case "$1" in
    "")
        usage
        exit 1
        ;;
    -l|--list)
        list_snapshots "$2" "$3"
        ;;
    -d|--delete)
        delete_snapshot "$2" "$*"
        ;;
    -e|--export)
        export_snapshot "$2" "$3"
        ;;
    -i|--import)
        import_snapshot "$2"
        ;;
    -dec)
        decrypt "$2"
        ;;
    *)
        create_snapshot "$2" "$3"
        ;;
esac