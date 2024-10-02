#!/bin/sh

usage(){
        echo "hw2.sh -p TASK_ID -t TASK_TYPE [-h]" >&2
        echo "" >&2
        echo "Available Options:" >&2
        echo "" >&2
        echo "-p: Task id" >&2
        echo "-t JOIN_NYCU_CSIT|MATH_SOLVER|CRACK_PASSWORD: Task type" >&2
        echo "-h: Show the script usage" >&2
}

URL="http://10.113.0.253"

task_id=""
task_type=""

while getopts ":p:t:h" OPT; do
        case "$OPT" in
                p) task_id=$OPTARG ;;
                t) task_type=$OPTARG ;;
                h) usage;;
                \?) usage; exit 1;;
        esac
done

echo "Task ID: $task_id"
echo "Task Type: $task_type"

id_response=$(curl -s "$URL/tasks/$task_id" -X GET)
echo "ID Response: $id_response"
server_task_type=$(echo "$id_response" | awk -F '"' '{print $8}')

if [ "$task_type" != "JOIN_NYCU_CSIT" ] &&  [ "$task_type" != "MATH_SOLVER" ] &&  [ "$task_type" != "CRACK_PASSWORD" ]; then
        echo 'Invalid task type' >&2
        exit 1
fi

if [ "$task_type" != "$server_task_type" ]; then
        echo 'Task type not match' >&2
        exit 1
fi

love(){

        love_id="$task_id"

        love_submit_response=$(curl -s "$URL/tasks/$love_id/submit" -X POST \
        -H 'Content-Type: application/json' \
        -d '{"answer": "I Love NYCU CSIT"}'
        )
        echo ""
        echo "Love Result: $love_submit_response"
}


math(){

        math_id="$task_id"
        math_response="$id_response"

        math_prob=$(echo "$math_response" | awk -F '"' '{print $12}')
        first_num=$(echo "$math_prob" | awk -F ' ' '{print $1}')
        second_num=$(echo "$math_prob" | awk -F ' ' '{print $3}')
        operator=$(echo "$math_prob" | awk -F ' ' '{print $2}')
        formula=$(echo "$math_prob" | awk -F ' ' '{print $1 " " $2 " " $3}')

        math_result=$(( "$formula" ))

        if [ "$math_result" -lt "-20000" ] || [ "$math_result" -gt "20000" ]; then
                math_result="Invalid problem"
        fi

        if [ "$operator" != "+" ] && [ "$operator" != "-" ]; then
                math_result="Invalid problem"
        fi

        if [ "$first_num" -lt "-10000" ] || [ "$first_num" -gt "10000" ]; then
                math_result="Invalid problem"
        fi

        if [ "$second_num" -lt "0" ] || [ "$second_num" -gt "10000" ]; then
                math_result="Invalid problem"
        fi

        echo ""
        echo "Compute Result: $math_result"

        math_submit_response=$(curl -s "$URL/tasks/$math_id/submit" -X POST \
        -H 'Content-Type: application/json' \
        -d "{\"answer\": \"$math_result\"}"
        )
        echo ""
        echo "Math Result: $math_submit_response"
}

caesar(){

        caesar_response="$id_response"
        caesar_id="$task_id"

        crypto=$(echo "$caesar_response" | awk -F '"' '{print $12}')
        N_ascii=$(printf "%d" "'N")
        first_char=$(echo "$crypto" | cut -c 1)
        first_ascii=$(printf "%d" "'$first_char")
        step=$(( "$first_ascii - $N_ascii" ))

        descrypt=""

        for i in $(seq 1 $((${#crypto})) ); do
                char=$(echo "$crypto" | cut -c "$i")
                ascii=$(printf "%d" "'$char")

                if [ "$ascii" -ge 65 ] && [ "$ascii" -le 90 ]; then
                        new_ascii=$(( "(ascii - 65 - $step + 26) % 26 + 65" ))

                elif [ "$ascii" -ge 97 ] && [ "$ascii" -le 122 ]; then
                        new_ascii=$(( "(ascii - 97 - $step + 26) % 26 + 97" ))

                else
                        new_ascii=$ascii
                fi
                new_char=$(printf "%b" "\\$(printf %o "$new_ascii")" )
                descrypt="$descrypt$new_char"
        done
        echo "descryption: $descrypt"

        prefix=$(echo "$descrypt" | awk -F '{' '{printf $1}')

        if [ "$prefix" != "NYCUNASA" ]; then
                caesar_result="Invalid problem"
        else
                caesar_result="$descrypt"
        fi
        echo "Descryption: $caesar_result"

        caesar_submit_response=$(curl -s "$URL/tasks/$caesar_id/submit" -X POST \
        -H 'Content-Type: application/json' \
        -d "{\"answer\": \"$caesar_result\"}"
        )
        echo ""
        echo "Caesar result: $caesar_submit_response"
}

if  [ "$task_type" = "JOIN_NYCU_CSIT" ]; then
        love
elif [ "$task_type" = "MATH_SOLVER" ]; then
        math
elif [ "$task_type" = "CRACK_PASSWORD" ]; then
        caesar
fi