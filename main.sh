#!/bin/bash
# Import items in mdx dictionary into ElasticSearch.

if [[ $# < 1 ]]; then
    echo "Usage: ./main.sh your_mdx_file_name";
    echo "i.e. ./main.sh test.mdx";
    exit 0
fi


# 1. mdx to html
echo "extracting from $1"
mdict -x $1

# 2. html to txt
echo "removing HTML tags from $1.txt"
sed 's/<[^<>]*>//g' $1.txt > $1.pure.txt

# 3. txt to ES json
echo "writing ES bulk json to $1.json"
TOTAL=$(wc -l $1.pure.txt)
LNO=0 #Line Number
TYPE=`cut -d . -f 1 <<< $1`
echo '' > $1.json

while read line; do
  case $((LNO%3)) in
    0)
        k=${line//[$'\r\n']}
        echo "{\"index\": {\"_index\": \"dict\"}" >> $1.json ;;
    1)
        v=${line//[$'\r\n']}
        echo "{\"k\":\"$k\", \"v\":\"$v\", \"t\":\"$TYPE\"}" >> $1.json ;;
    2)
        echo -ne "$LNO/$TOTAL \033[0K\r";;
  esac
  let LNO++
done < $1.pure.txt
echo "$TOTAL"
echo "$1.json is ready!"

# 4. json to ES index
echo "bulk uploading to ES, with type: $TYPE"
curl -H "Content-Type: application/json" -XPOST "localhost:9200/dict/_bulk?pretty&refresh" --data-binary "@$1.json" > result.log
echo "check result.log for result"
head result.log
echo "Finished $TYPE!"
