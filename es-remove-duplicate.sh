#!/bin/bash

# this script finds documents with duplicate ID in ES index, and remove them
# all except the most recent one. The indices name should be sortable by sort -n
# command.
#
# For example, given duplicate ID in the following indices:
# myidx-2019.01.04, myidx-2019.01.02, myidx-2019.01.03
# this script will keep the one in myidx-2019.01.04 and remove the others.
#
# Usage:
# define the following env variables, then just execute this script
# ES_CRED should be in a form of uid:password

############################################

ES_URL=${ES_URL:-http://elasticsearch:9200}
ES_INDEX_PATTERN=${ES_INDEX_PATTERN:-siem_alarms}
ES_CRED=${ES_CRED:-}
CURL_EXTRA_FLAGS=${CURL_EXTRA_FLAGS:-}

############################################

[ "$ES_CRED" != "" ] && ES_CRED="-u $ES_CRED"
[ "$ES_INDEX_PATTERN" == "" ] && { echo "ES_INDEX_PATTERN env variable is not set!"; exit 1; }

for t in curl jq sed; do
  which $t >/dev/null 2>&1|| { echo cannot find $t command in path; exit 1; }
done

# check if indices exist
curl -fsS -I $CURL_EXTRA_FLAGS $ES_CRED $ES_URL/$ES_INDEX_PATTERN >/dev/null 2>&1 || { echo cannot find $ES_INDEX_PATTERN indices; exit 1; }

tmp=/tmp/duplicate-${RANDOM}.json
echo searching duplicate IDs in $ES_INDEX_PATTERN index on $ES_URL ..
curl -fsS -XGET -H 'content-type:application/json' $CURL_EXTRA_FLAGS $ES_CRED "$ES_URL/$ES_INDEX_PATTERN/_search?pretty=true" -d '{
  "size": 0,
  "aggs": {
    "duplicateCount": {
      "terms": {
        "size": 10000,
        "field": "_id",
        "min_doc_count": 2,
        "order": {
          "_count": "desc"
        }
      },
      "aggs": {
        "duplicateDocuments": {
          "top_hits": {}
        }
      }
    }
  }
}' > $tmp || { echo failed to curl for duplicate IDs; rm -rf $tmp; exit 1; }

ids=$(cat $tmp | jq ".aggregations.duplicateCount.buckets[].key" 2>/dev/null)
ret=$? && [ "$ret" != "0" ] && { echo cannot find aggregation query result; exit $ret; }

[ "$ids" == "" ] && echo no duplicates found && rm -rf $tmp && exit

for id in $ids; do
  echo processing ID $id ..
  idx=$( cat $tmp | jq ".aggregations.duplicateCount.buckets[] | select(.key=="$id") .duplicateDocuments.hits.hits[]._index")
  sorted=$(echo "$idx" | sort -n)
  last=$(echo "$idx" | tail -1)
  else=$(echo "$idx" | grep -v $last)
  echo preserving ID in $last and deleting it in $else ..
  for idx in $else; do
    v1=$(echo $idx | sed -e 's/^"//' -e 's/"$//')
    v2=$(echo $id | sed -e 's/^"//' -e 's/"$//')
    url="$ES_URL/$v1/_doc/$v2"
    # make sure writeable first
    curl -fsS -H 'content-type:application/json' -X PUT $CURL_EXTRA_FLAGS $ES_CRED "$ES_URL/$v1/_settings" -d"
    {
      \"index.blocks.read_only_allow_delete\": \"false\",
      \"index.blocks.write\": \"false\"
    }" && echo && \
    curl -XDELETE $CURL_EXTRA_FLAGS $ES_CRED $url
    echo
  done
done

rm -rf $tmp

