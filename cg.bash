#!/bin/bash

map=(
    r r r r r r r r r r r r r r r r
    r r g g g g g r r r r r r r r r
    r r g g g g g r r r r r r r r r
    r r g g H g g r r r r r r r r r
    r r g g g g g r h h h h r r r r
    r r g g g g g h t t t h h r r r
    r r t t t h t t t h t t t h r r
    r r t h t t t h t t t h t h h r
    r r t t t h t t t h t t t h r r
    r r r s t t w w t t t t h h h r
    s s s s s w w w w h h h h h r r
    s s s s s w w w w h h h h h h r
    s s s s s s s s s h h h h h r r
    s s s s s s s s r r h h h h h r
    s s s s s s s r r t t h h h r r
    s s s s f f r r t t t t t t r r
    s s s f f f f t t t t t t r r r
    r r f f f f f f f f f f f r r r
    r r f f f f f f f f f f f r r r
    r r f f f f f f f f f f f r r r
    r r f f f f f f f f f f f r r r
    r r f f f f f f f f f f f r r r
)

mapw=16 maph=22

declare -A colours=(
    [f]=76  # fairway
    [g]=34  # green
    [r]=64  # rough
    [h]=70  # hill
    [s]=215 # sand
    [t]=22  # tree
    [w]=33  # water
    [H]=160 # hole
    [X]=230 # player
    [x]=220 # possible move
)
declare -A pieces=(
    [f]=Q  # ♕ fairway
    [g]=R  # ♖ green
    [r]=B  # ♗ rough
    [h]=N  # ♘ hill
    [s]=p  # ♙ sand
    [t]=?  # ? tree
    [w]=?  # ? water
    [H]=?  # ? hole
    [X]=?  # ? player
    [x]=?  # ? possible move
)

display () {
    echo '   a b c d e f g h i j k l m n o p'
    for ((h=0;h<maph;h++)) do
        printf %2d "$((maph-h))"
        for ((w=0;w<mapw;w++)) do
            terrain=${map[h*mapw+w]}
            if ((h==posx&&w==posy)); then
                c=$current terrain=X
            elif ((moves[$h,$w])); then
                c=$terrain terrain=x
            else
                c=$terrain
            fi
            printf '\e[38;5;232;48;5;%dm%2s\e[m' "${colours[$terrain]}" "$c"
        done
        printf %2d\\n "$((maph-h))"
    done
    echo '   a b c d e f g h i j k l m n o p'
}

playerpos=posx*mapw+posy

declare -A moves
bound () ((tx>=0&&tx<maph&&ty>=0&&ty<mapw))
okmove () {
    bound || return
    [[ ! ${map[tx*mapw+ty]} = [tw] ]] || return
    ((!q)) && [[ ${map[playerpos]} = ${map[tx*mapw+ty]} ]] || ((++q))
    ((q<=1)) && moves[$tx,$ty]=1
}
init=tx=posx,ty=posy,i=q=0
calcmoves () {
    terrain=${map[playerpos]}
    moves=()
    case $current in
        Q) for ((init;;i++)) do tx=$((posx+i)); okmove || break; done
           for ((init;;i++)) do tx=$((posx-i)); okmove || break; done
           for ((init;;i++)) do ty=$((posy+i)); okmove || break; done
           for ((init;;i++)) do ty=$((posy-i)); okmove || break; done
           for ((init;;i++)) do tx=$((posx+i)) ty=$((posy+i)); okmove || break; done
           for ((init;;i++)) do tx=$((posx+i)) ty=$((posy-i)); okmove || break; done
           for ((init;;i++)) do tx=$((posx-i)) ty=$((posy+i)); okmove || break; done
           for ((init;;i++)) do tx=$((posx-i)) ty=$((posy-i)); okmove || break; done
           ;;
        R) for ((init;;i++)) do tx=$((posx+i)); okmove || break; done
           for ((init;;i++)) do tx=$((posx-i)); okmove || break; done
           for ((init;;i++)) do ty=$((posy+i)); okmove || break; done
           for ((init;;i++)) do ty=$((posy-i)); okmove || break; done
           ;;
        B) for ((init;;i++)) do tx=$((posx+i)) ty=$((posy+i)); okmove || break; done
           for ((init;;i++)) do tx=$((posx+i)) ty=$((posy-i)); okmove || break; done
           for ((init;;i++)) do tx=$((posx-i)) ty=$((posy+i)); okmove || break; done
           for ((init;;i++)) do tx=$((posx-i)) ty=$((posy-i)); okmove || break; done
           ;;
        N) ((init,tx=posx-2,ty=posy-1)); okmove
           ((init,tx=posx-1,ty=posy-2)); okmove
           ((init,tx=posx-1,ty=posy+2)); okmove
           ((init,tx=posx-2,ty=posy+1)); okmove
           ((init,tx=posx+1,ty=posy-2)); okmove
           ((init,tx=posx+2,ty=posy-1)); okmove
           ((init,tx=posx+1,ty=posy+2)); okmove
           ((init,tx=posx+2,ty=posy+1)); okmove
           ;;
        p) ((init)); tx=$((posx-1)); okmove
    esac
}
move () {
    move=$1$2
    set -- "${letters[${1,}]}" "$((maph-$2))"
    ((moves[$2,$1])) || return
    posy=$1 posx=$2
    current=${pieces[${map[posx*mapw+posy]}]}
    calcmoves
    true
}

echo -e "\
land on        ->   you become
\e[48;5;076;38;5;232m f\e[m = fairway   ->   Q = queen
\e[48;5;034;38;5;232m g\e[m = green     ->   R = rook
\e[48;5;064;38;5;232m r\e[m = rough     ->   B = bishop
\e[48;5;070;38;5;232m h\e[m = hill      ->   N = knight
\e[48;5;215;38;5;232m s\e[m = sand      ->   p = pawn
\e[48;5;022;38;5;232m t\e[m = tree      ->   (cannot land here)
\e[48;5;033;38;5;232m w\e[m = water     ->   (cannot land here)
\e[48;5;160;38;5;232m H\e[m = hole      ->   win :)
"

q=0
printf -v tmp %s {a..z}" $((q++)) "
eval "declare -A letters=($tmp)"

posx=20 posy=3
current=${pieces[${map[playerpos]}]}
calcmoves

declare -n m=BASH_REMATCH
count=1
win=0
while :; do
    [[ ${map[playerpos]} = H ]] && { echo you win!; win=1; break; }
    display

    read -rep "$count. "
    [[ $REPLY ]] || break
    [[ $REPLY =~ ^' '*([a-zA-Z])' '*([0-9]+)' '*$ ]] || continue

    move "${m[1],}" "${m[2]}" && game+=("$((count++)). $move")
done

echo your game:
printf %s\\n "${game[@]}"
((win)) && echo "gg :)" || echo "better luck next time :)"
