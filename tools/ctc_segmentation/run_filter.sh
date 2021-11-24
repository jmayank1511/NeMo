#!/bin/bash

SCRIPTS_DIR="scripts" # /<PATH TO>/NeMo/tools/ctc_segmentation/tools/scripts/ directory
MODEL_NAME_OR_PATH=""
INPUT_AUDIO_DIR=""
MANIFEST=""
BATCH_SIZE=4

# Thresholds for filtering
CER_THRESHOLD=35
WER_THRESHOLD=75
CER_EDGE_THRESHOLD=35
LEN_DIFF_THRESHOLD=0.3

for ARG in "$@"
do
    key=$(echo $ARG | cut -f1 -d=)
    value=$(echo $ARG | cut -f2 -d=)

    if [[ $key == *"--"* ]]; then
        v="${key/--/}"
        declare $v="${value}"
    fi
done

if [[ -z $MODEL_NAME_OR_PATH ]] || [[ -z $INPUT_AUDIO_DIR ]] || [[ -z $MANIFEST ]]; then
  echo "Usage: $(basename "$0")
  --MODEL_NAME_OR_PATH=[path to .nemo ASR model or a pre-trained model name to use for metrics calculation]
  --INPUT_AUDIO_DIR=[path to original directory with audio files used for segmentation]
  --MANIFEST=[path to manifest file generated during segmentation]"
  exit 1
fi

echo "--- Adding transcripts to ${MANIFEST} using ${MODEL_NAME_OR_PATH} ---"
if [[ ${MODEL_NAME_OR_PATH,,} == *".nemo" ]]; then
  ARG_MODEL="model_path";
else
  ARG_MODEL="pretrained_name";
fi

# Add transcripts to the manifest file, ASR model predictions will be stored under "pred_text" field
python ${SCRIPTS_DIR}/../../../examples/asr/transcribe_speech.py \
$ARG_MODEL=$MODEL_NAME_OR_PATH \
dataset_manifest=$MANIFEST \
output_filename=${MANIFEST}_transcribed.json || exit

echo "--- Calculating metrics and filtering out samples based on thresholds ---"
echo "CER_THRESHOLD = ${CER_THRESHOLD}"
echo "WER_THRESHOLD = ${WER_THRESHOLD}"
echo "CER_EDGE_THRESHOLD = ${CER_EDGE_THRESHOLD}"
echo "LEN_DIFF_THRESHOLD = ${LEN_DIFF_THRESHOLD}"

python ${SCRIPTS_DIR}/get_metrics_and_filter.py \
--manifest=${MANIFEST}_transcribed.json \
--audio_dir=${INPUT_AUDIO_DIR} \
--max_cer=${CER_THRESHOLD} \
--max_wer=${WER_THRESHOLD} \
--max_len_diff=${LEN_DIFF_THRESHOLD} \
--max_edge_cer=${CER_EDGE_THRESHOLD}

#rm -rf ${MANIFEST}_transcribed.json


# clean up
##rm -rf ${OUTPUT_DIR}/processed

#python /home/ebakhturina/NeMo/tools/speech_data_explorer/data_explorer.py \
#--disable-caching-metrics \
#${OUTPUT_DIR}/manifests/all_transcribed.json