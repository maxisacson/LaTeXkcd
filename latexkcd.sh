#!/bin/bash

function get_html_url {
    local html="$(curl -s $1)"
    echo "$html"
}

function get_html_id {
    local url="http://xkcd.com/$1/"
    local html="$(get_html_url $url)"
    echo "$html"
}

function get_html {
    local regex='(https?|ftp|file)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]'
    [[ $1 =~ $regex ]] && echo "$(get_html_url $1)" || echo "$(get_html_id $1)"
}

function get_comic_div {
    local div="$(echo "$1" | sed -n '/<div id=\"comic\">/,/<\/div>/p')"
    #local div="$(echo "$1" | sed -n '/<head>/,/<\/head>/p')"
    echo "$div"
}

function get_img_src {
    local img="$(echo "$1" | sed -n 's/.*src="\([^"]*\).*/\1/p')"
    echo "$img"
}

function get_hidden_text {
    local text="$(echo "$1" | sed -n 's/.*title="\([^"]*\).*/\1/p' | perl -MHTML::Entities -pe 'decode_entities($_);')"
    echo "$text"
}

function get_title {
    local title="$(echo "$1" | sed -n 's/<div id=\"ctitle\">\(.*\)<\/div>/\1/p')"
    echo "$title"
}

function latex_escape {
    local tex="$(echo "$1" | sed -r 's/[$%&\_#^]/\\&/g')"
    echo "$tex"
}

html="$(get_html $1)"
div=$(get_comic_div "$html")
img=$(get_img_src "$div")
text=$(get_hidden_text "$div")
title=$(get_title "$html")
tex=$(latex_escape "$text")

wget --quiet "http:$img" -P /tmp/
baseimg=$(basename $img)
wait

cat <<EOF > /tmp/xkcd.tex
\documentclass[lualatex,a4paper]{article}

\usepackage{fontspec}
\setmainfont{Humor Sans}

\\begin{document}
\\thispagestyle{empty}


{\\huge $title}

\\begin{figure}[h!]
    \\centering
    \\includegraphics[width=\\textwidth]{/tmp/$baseimg}
\\end{figure}
\\begin{flushright}
    xkcd.com/$1/
\\end{flushright}

$tex

\\end{document}
EOF

thisdir=$(pwd)
cd /tmp/
lualatex xkcd.tex && cd $thisdir && xdg-open /tmp/xkcd.pdf
