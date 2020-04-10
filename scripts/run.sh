#!/bin/bash
script_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
dir=$script_dir/..
train_dir=$dir/train/sim_transformer
pretrain_dir=$dir/train/sim_pretrain

set -e
test -e $dir/fairseq
test -e $dir/m2scorer
test -e $dir/data

devices=0,1,2,3,4,5,6,7
update_freq=1
average_num=5
model_start_num=3
ensemable_num=1

bash $script_dir/pretrain.sh $devices $pretrain_dir $update_freq

all_model_dir=""
for ((i=model_start_num;i<model_start_num+ensemable_num;i++))
do
    model_dir=$train_dir'/model'$i
    bash $script_dir/transformer.sh $devices $model_dir $pretrain_dir/checkpoint5.pt $average_num $i $update_freq
    bash $script_dir/evaluate.sh $devices $model_dir/average_best$average_num/average.pt $model_dir/average_best$average_num/evaluation
    all_model_dir="$all_model_dir:$model_dir/average_best$average_num/average.pt"

    if [[ $ensemable_num == 1 ]];then
        echo 'M2 result without spellcheck'
        cat $model_dir/average_best$average_num/evaluation/testM2result
        echo ''
        echo 'M2 result with spellcheck'
        cat $model_dir/average_best$average_num/evaluation/spellM2result
    fi
done

#var=$(cat $model_dir/sorted_8.txt | sed ':label;N;s/\n/:/;b label')
#bash $script_dir/evaluate.sh $devices $var $model_dir/single_ensemble

if [[ $ensemable_num != 1 ]];then
    all_model_dir=${all_model_dir:1}
    bash $script_dir/evaluate.sh $devices $all_model_dir $train_dir/ensemble_result
    
    echo 'M2 result without spellcheck'
    cat $train_dir/ensemable_result/testERRANTresult
    echo ''
    echo 'M2 result with spellcheck'
    cat $train_dir/ensemable_result/spellERRANTresult
fi
