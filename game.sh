#!/bin/bash

export TERM=xterm
export NCURSES_NO_UTF8_ACS=1


rows=20
cols=40

snake_position=("5 20" "5 19" "5 18")
snake_length=3
fruit_position=""
base_time=0.5
speed="$base_time"
# decay=0.85

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


display_length() {
    tput cup $((rows + 1)) 0
    echo -n "Length: $snake_length"
}
display_length


generate_random_fruit() {
    while true; do
        local row=$((RANDOM % (rows-2) + 1))
        local col=$((RANDOM % (cols-2) + 1))
        local position="$row $col"
        if [[ ! " ${snake_position[@]} " =~ " $position " ]]; then
            fruit_position="$position"
            tput cup $row $col
            echo -n "$"
            break
        fi
    done
}


eat_fruit() {
    if [[ ${snake_position[0]} == "$fruit_position" ]]; then
        snake_position+=("${snake_position[-1]}")
        ((snake_length++))
        generate_random_fruit
        display_length
        calculate_speed
    fi
}



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

    if ((y <= 0)); then
        y=$((rows-2))
    elif ((y >= rows-1)); then
        y=1
    fi

    if ((x <= 0)); then
        x=$((cols-2))
    elif ((x >= cols-1)); then
        x=1
    fi

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


game_over() {
  local head_pos="${snake_position[0]}"

  for ((i=1; i<${#snake_position[@]}; i++)); do
    if [[ "${snake_position[$i]}" == "$head_pos" ]]; then
      tput cup $((rows/2)) $((cols/2-4))
      echo -n "GAME OVER"
      tput cup $((rows/2+1)) $((cols/2-9))
      echo -n "Press any key to exit"
      stty echo
      tput cnorm
      read -n1
      clear
      exit 0
    fi
  done
}


calculate_speed() {
    speed=$(awk "BEGIN {printf \"%.4f\", $speed / 1.1}")
}


flush_input_buffer
generate_random_fruit
while true; do
    eat_fruit
    move_and_slide
    draw_snake
    game_over
    # flush_input_buffer
    sleep "$speed"
done

