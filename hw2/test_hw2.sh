#!/bin/sh

URL="http://10.113.0.253"

love_response=$(curl -s "$URL/tasks" -X POST \
-H 'Content-Type: application/json' \
-d '{"type": "JOIN_NYCU_CSIT"}'
)
echo "Love Response Code: $love_response"

love_id=$(echo "$love_response" | awk -F '"' '{print $4}')

love_submit_response=$(curl -s "$URL/tasks/$love_id/submit" -X POST \
-H 'Content-Type: application/json' \
-d '{"answer": "I Love NYCU CSIT"}'
)
echo ""
echo "love result: $love_submit_response"

echo "---------------------------------------------------------------------------------------------------"


math_response=$(curl -s "$URL/tasks" -X POST \
-H 'Content-Type: application/json' \
-d '{"type": "MATH_SOLVER"}'
)

echo "Math Response Code: $math_response"

# Response Code: {"id":"e92f9ca1-5984-453c-9460-7bc370edd872","type":"MATH_SOLVER","problem":"-2220 / 68 = ?","status":"PENDING"}

math_id=$(echo "$math_response" | awk -F '"' '{print $4}')

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
echo "math_result: $math_result"

math_submit_response=$(curl -s "$URL/tasks/$math_id/submit" -X POST \
-H 'Content-Type: application/json' \                                                                                   -d "{\"answer\": \"$math_result\"}"
)
echo ""
echo "math result: $math_submit_response"

echo "---------------------------------------------------------------------------------------------------"

caesar_response=$(curl "$URL/tasks" -X POST \
-H 'Content-Type: application/json' \
-d '{"type": "CRACK_PASSWORD"}'
)
echo "Caesar Response Code: $caesar_response"

# Caesar Response Code: {"id":"cdbb2e85-87ec-4aeb-9d06-ab407b5ffbb5","type":"CRACK_PASSWORD","problem":"XgMEXKCK{MFOgcQChbbQqNOWi}","status":"PENDING"}

caesar_id=$(echo "$caesar_response" | awk -F '"' '{print $4}')
echo "caesar id: $caesar_id"
crypto=$(echo "$caesar_response" | awk -F '"' '{print $12}')
echo "crypto: $crypto"
N_ascii=$(printf "%d" "'N")
echo "N_ascii: $N_ascii"
first_char=$(echo $crypto | cut -c 1)
echo "first_char: $first_char"
first_ascii=$(printf "%d" "'$first_char")
echo "first_ascii: $first_ascii"
step=$(( "$first_ascii - $N_ascii" ))
echo "step: $step" # to substract

descrypt=""

for i in $(seq 1 $((${#crypto})) ); do
        char=$(echo $crypto | cut -c "$i")
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
echo "decrypt: $descrypt"


prefix=$(echo $descrypt | awk -F '{' '{printf $1}')
echo "prefix: $prefix"

if [ "$prefix" != "NYCUNASA" ]; then
        caesar_result="Invalid problem"
else
        caesar_result="$descrypt"
fi
echo "Descryption: $caesar_result"

caesar_submit_response=$(curl -s "$URL/tasks/$caesar_id/submit" -X POST \
-H 'Content-Type: application/json' \                                                                                   -d "{\"answer\": \"$caesar_result\"}"
)
echo ""
echo "Caesar result: $caesar_submit_response"