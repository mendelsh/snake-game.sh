#!/bin/bash

rows=25
cols=53

snake_position=("5 20" "5 19" "5 18")

clear
stty -echo
tput civis
trap "stty echo; tput cnorm; clear; exit" EXIT


for ((row = 0; row < rows; row++)); do
    for ((col = 0; col < cols; col++)); do
        tput cup $row $col
        if ((row == 0 && col == 0)); then
            echo -n "╔" 
        elif ((row == 0 && col == cols - 1)); then
            echo -n "╗" 
        elif ((row == rows - 1 && col == 0)); then
            echo -n "╚" 
        elif ((row == rows - 1 && col == cols - 1)); then
            echo -n "╝" 
        elif ((row == 0 || row == rows - 1)); then
            echo -n "═" 
        elif ((col == 0 || col == cols - 1)); then
            echo -n "║" 
        else
            echo -n " " 
        fi
    done
    echo
done



draw_snake() {
    read y x <<< ${snake_position[0]}
    tput cup $y $x
    echo -n "@"
    for ((i=1; i<${#snake_position[@]}; i++)); do
        read y x <<< ${snake_position[i]}
        tput cup $y $x
        echo -n "o"
    done
}

draw_snake


move_snake() {
    local direction=$1
    read y x <<< ${snake_position[0]}

    case $direction in
        "u") ((y--)) ;;
        "d") ((y++)) ;;
        "l") ((x--)) ;;
        "r") ((x++)) ;;
    esac

    new_head="$y $x"

    len=${#snake_position[@]}
    last=$((len - 1))
    last_element=${snake_position[$last]}

    snake_position=("$new_head" "${snake_position[@]:0:$last}")

    read tail_y tail_x <<< "$last_element"
    tput cup $tail_y $tail_x
    echo -n " "
}

opposite_direction() {
    case "$1" in
        u) echo "d" ;;
        d) echo "u" ;;
        l) echo "r" ;;
        r) echo "l" ;;
    esac
}

flush_input_buffer() {
    while read -rsn1 -t 0.005; do :; done
}

direction="r"
move_and_slide() {
    local new_direction
    
    if read -rsn1 -t 0.01 key; then
        if [[ $key == $'\x1b' ]]; then
            read -rsn2 rest
            key+=$rest
        fi

        case "$key" in
            $'\x1b[A') new_direction="u" ;;
            $'\x1b[B') new_direction="d" ;;
            $'\x1b[C') new_direction="r" ;;
            $'\x1b[D') new_direction="l" ;;
        esac

        if [[ -n "$new_direction" && "$(opposite_direction "$direction")" != "$new_direction" ]]; then
            direction="$new_direction"
        fi
    fi

    move_snake "$direction"
}


flush_input_buffer
while true; do
    move_and_slide
    draw_snake
    flush_input_buffer
    sleep 1
done

