#!/usr/bin/env sh

loggly() {
  MSG=$1
    LOGGLY_API_KEY=your loggly key
    LOGGLY_TAGS="djr,djr-instance,djr-instance-$INSTANCE_ID"
  curl -H "content-type:application/x-www-form-urlencoded" -d "$MSG" "http://logs-01.loggly.com/inputs/$LOGGLY_API_KEY/tag/$LOGGLY_TAGS"
}

START=`date +%s%3N`
export DATE=`date +%Y-%m-%dT%H:%M:%S.000000`
export INSTANCE_ID=$(curl --silent -m1 http://169.254.169.254/latest/meta-data/instance-id)

FOLDER=`echo $1 | awk -F, '{print$1}'`
cmd=`echo $1 | cut -d, -f2-`
key=`echo $cmd | tr / _ | tr [:blank:] - | tr , - | tr ';' ::`

func=`echo $cmd | awk -F, '{print $1}'`
feature=`echo $cmd | awk -F, '{print "./input/'"$FOLDER"'/" $2 ".tif"}'`
args=`echo $cmd | awk -F, '{print $4}'`

bucket=$BUCKET
input_path=${INPUT_PATH:-"input"}
output_path=${OUTPUT_PATH:-"output"}
output_path="$OUTPUT_PATH/$FOLDER"
correct_index_count=$CORRECT_INDEX_COUNT
rm -rf $output_path
mkdir -p $output_path

TILES=`echo $cmd | awk -F, '{ split($3, tiles, ";"); for(i in tiles) { print tiles[i] } }'`
# loggly '{"tiles": "'"$TILES"'"}'

for TILE in $TILES; do

    if [[ $TILE == *"36" || $TILE == "16"* ]]; then
        MSG='skipping'
    else
        if [ -f "input/${FOLDER}/${TILE}.tif" && -f "input/dems/${TILE}.tif" ]; then
            MSG='skipping'
        else
            TILEDIR=`echo $TILE | awk -F"/" '{ print $1 }'`
            mkdir -p "input/${FOLDER}/${TILEDIR}"
            aws s3 cp "s3://tesera.ktpi/${input_path}/${FOLDER}/${TILE}.tif" "input/${FOLDER}/${TILE}.tif"
            mkdir -p "input/dems/${TILEDIR}"
            aws s3 cp "s3://tesera.ktpi/${input_path}/dems/${TILE}.tif" "input/dems/${TILE}.tif"
        fi
    fi
done

INPUT_FILES=`ls -m input`
COMMAND="./ktpi.r $func $feature ./input/dems ./$output_path $args 2>&1"
OUTPUT=`./ktpi.r $func $feature ./input/dems ./$output_path $args 2>&1 | sed 's;\n;;g' | sed 's;";;g'`
COMMANDSTATUS=$?

# Check that a CSV file ahs been output
OUTPUT_FILES=`ls -m $output_path`
[ "$(ls -A $output_path)" ] && RETURN=0 || RETURN=1

# Check that the CSV file has the correct number of indicies
if [ $RETURN == 0 ]; then
    INDEXCOUNT=`awk -F, '{x+=\$3}END{print x}' $output_path/$OUTPUT_FILES`
    [ "$INDEXCOUNT" == "$correct_index_count" ] && RETURN=0 || RETURN=2
fi

# Check that the CSV file does not contain Inf values
if [ $RETURN == 0 ]; then
    grep "Inf" "$output_path/$OUTPUT_FILES"
    [ $? == 0 ] && RETURN=3 || RETURN=0
fi

# Count the number of rows with more than one NA value
if [ $RETURN == 0 ]; then
    NUM_MULTI_NA_ROWS=`egrep "(,,,|,,.*,,|^,.*,$|^,.*,,|,,.*,$)" $output_path/$OUTPUT_FILES | wc -l`
    NUM_NA_ROWS=`egrep "(,,|^,|,$)" $output_path/$OUTPUT_FILES | wc -l`
fi

# Check for errors in the command output, excluding errors happening on tiles x/36 or 16/x
if [ $RETURN == 0]; then
    egrep "([0-9]|1[0-5])/([0-3][0-9]|3[0-5]).tif\' not recognised as a supported file format." "$output_path/$OUTPUT_FILES"
    [ $? == 0 ] && RETURN=4 || RETURN=0
fi

mkdir -p $output_path/log
echo $OUTPUT > "./$output_path/log/${OUTPUT_FILES}.log"
eval "aws s3 sync ./$output_path s3://$bucket/$output_path"
SYNC=$?

END=`date +%s%3N`
RUNTIME=`expr $END - $START`

loggly '{"started_at":"'"$DATE"'", "instance":"'"$INSTANCE_ID"'", "task":"'"$1"'", "key":"'"$key"'", "func":"'"$func"'", "feature":"'"$feature"'", "args":"'"$args"'", "bucket":"'"$bucket"'", "input_path":"'"$input_path"'", "output_path":"'"$output_path"'", "copy":"'"$COPY"'", "input_files":"'"$input_files"'", "command":"'"$COMMAND"'", "status":"'"$COMMANDSTATUS"'", "return":"'"$RETURN"'", "output":"'"$OUTPUT"'", "output_files":"'"$OUTPUT_FILES"'", "sync":"'"$SYNC"'", "runtime":"'"$RUNTIME"'", "indicies":"'"$INDEXCOUNT"'", "na_lines":"'"$NUM_NA_ROWS"'", "multi_na_lines":"'"$NUM_MULTI_NA_ROWS"'"}'
exit $RETURN
