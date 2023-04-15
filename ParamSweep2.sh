#!/bin/bash


for i in {1..12}
do
    bp="/mnt/immucan_volume/processed_data/Panel_1/CellSighter/ParamSweep2/Model_$i"
    if [ -d "$bp" ]; then
        python CellSighterCode/train.py --base_path=$bp
        python CellSighterCode/eval.py --base_path=$bp
        python CellSighterCode/analyze_results/confusion_matrix.py --base_path=$bpv
        find $bp -name "*pth" -type f -delete
    fi
done