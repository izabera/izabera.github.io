#!/bin/bash

function printbar () {
  value="$1"
  total="$2"
  i=0
  echo -en "\r"
  [ -n "$3" ] && echo -n "$3 - "
  echo -n "Progress: $value/$total ["
  for (( ; i<10; i++ )); do
    if (( i >= (value*10)/total )); then
      echo -n "$(tput setab 1)"    #green
    else
      echo -n "$(tput setab 2)"    #red
    fi
    echo -n " "
  done
  echo -n "$(tput sgr 0)]"
}


function disqussify () {
  if [[ "$disqusplugin" == "true" ]]; then
    echo "<div class='container' id='disqus_thread'></div>" > disqus
    echo "<script type='text/javascript'>" >> disqus
    echo "  var disqus_shortname = '$disqus_name';" >> disqus
    echo "  (function() {" >> disqus
    echo "    var dsq = document.createElement('script'); dsq.type = 'text/javascript'; dsq.async = true;" >> disqus
    echo "    dsq.src = '//' + disqus_shortname + '.disqus.com/embed.js';" >> disqus
    echo "    (document.getElementsByTagName('head')[0] || document.getElementsByTagName('body')[0]).appendChild(dsq);" >> disqus
    echo "  })();" >> disqus
    echo "</script>" >> disqus
    echo "<noscript>Please enable JavaScript to view the <a href="http://disqus.com/?ref_noscript">comments powered by Disqus.</a></noscript>" >> disqus
    echo "<a href='http://disqus.com' class='dsq-brlink'>comments powered by <span class='logo-disqus'>Disqus</span></a>" >> disqus
  fi
}


function generateindex () {
  wordcount=0
  echo -n "<h2><a href='html/$newfile" >> index
  [[ "$rewrite_urls" == "false" ]] && echo -n .html >> index
  echo -n "'>" >> index
  head -n1 "$file" | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' >> index
  echo "</a></h2>" >> index
  [[ "$show_date_in_index" == "true" ]] && sed "s/XXX/$timestamp/" < ../blog/indextimestamp >> index
  if (( preview_words > 0 )); then
    echo "<p>" >> index
    sed '1,2d' "$file" | while read line; do
      for word in $line; do
        (( wordcount < preview_words )) && echo $word >> index
        (( wordcount++ ))
      done
    done
    echo "...</p><hr>" >> index
  fi
}


#prepare
rm -rf temp html 2> /dev/null && mkdir temp html
cd blog
source settings
cp defaults/head head
cp defaults/indexhead indexhead
cp defaults/bottom bottom
cp defaults/indexbottom indexbottom
sed -i "s/YYY/$title/" head
sed -i "s/YYY/$title/" indexhead
disqussify
cat disqus bottom > temp
mv temp bottom


#copy
cd ../src
total=$(ls | wc -l)
count=0
printbar $count $total "        Copying files"
for file in *; do
  #with timestamp, when bash will glob our files they'll be sorted by date 
  newfile=$(mktemp -u -p . "$(date '+%s' -r "$file")-XXXXXXXX")
  cp "$file" ../temp/"$newfile"
  echo "$newfile" >> ../temp/list
  (( count++ ))
  printbar $count $total "        Copying files"
done
echo


#markdownify
cd ../temp
count=0
printbar $count $total "  Markdown conversion"
for file in $(sort -r list); do
  title="$(head -n1 "$file")"
  newfile="$(echo "$title" | tr 'A-Z ' 'a-z-' | tr -dc 'a-z-')" #with no extension
  timestamp="$(date '+%c' -d @${file:2:10})"
  sed "s/XXX/$title/" < ../blog/head > ../html/"$newfile".html
  python -m markdown "$file" >> ../html/"$newfile".html
  [[ "$show_date_in_article" == "true" ]] && sed "s/XXX/$timestamp/" < ../blog/timestamp >> ../html/"$newfile".html
  echo "<a href='/'>Back</a>" >> ../html/"$newfile".html
  cat ../blog/bottom >> ../html/"$newfile".html
  (( count++ ))
  printbar $count $total "  Markdown conversion"
  generateindex
done
echo


#create index and finish
cd ..
cat blog/indexhead temp/index blog/indexbottom > index.html
rm -rf temp
[[ "$gitplugin" == "true" ]] && git add -A && git commit -m "$(date)" && git push

