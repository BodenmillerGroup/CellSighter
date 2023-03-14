#!/bin/bash
files= find "/mnt/immucan_volume/processed_data/Panel_1/CellSighter/OVA/" -name "Output*" -type d

for bp in $files:
do
    python CellSighterCode/train.py --base_path=$bp
    python CellSighterCode/eval.py --base_path=$bp
    python CellSighterCode/analyze_results/confusion_matrix.py --base_path=$bp
    find $bp -name "*pth" -type f -delete
done
