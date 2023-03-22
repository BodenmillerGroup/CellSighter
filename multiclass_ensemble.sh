#!/bin/bash

for i in {1..10}
do
    bp="/mnt/immucan_volume/processed_data/Panel_1/CellSighter/Multiclass/Model_$i"
    python CellSighterCode/train.py --base_path=$bp
    python CellSighterCode/eval.py --base_path=$bp
    find $bp -name "*pth" -type f -delete
done