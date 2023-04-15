#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Mar  3 16:30:17 2023

@author: bp
"""

import pandas as pd
import numpy as np
import os
from sklearn.metrics import confusion_matrix
import seaborn as sns
import matplotlib.pyplot as plt

val_results = []
FPR_list = []

# create list of all files in directory that have a val_results.csv
base_path = "/Volumes/immucan_volume/processed_data/Panel_1/CellSighter/OVA"
for path in os.listdir(base_path):
    if os.path.isfile(os.path.join(base_path, path, "val_results.csv")):
        val_results.append(os.path.join(base_path, path, "val_results.csv"))

val_results = sorted(val_results)

# combine all dataframes by unique cell id
df_all_labeled = pd.DataFrame()
ensemble_size = len(val_results)
cell_names = []
for i, val_result in enumerate(val_results):
    
    # extract cell type
    cell_name = val_result.split("/")[-2].split("_")[-1].split(".")[0]
    cell_names.append(cell_name)
    
    curr_df = pd.read_csv(val_result, index_col=0)
    # prob_list = curr_df["prob_list"].apply(eval)
    # num_classes = len(prob_list.iloc[0])
    # curr_df[[f"prob_class_{j}" for j in range(num_classes)]] = prob_list.apply(pd.Series)
    # curr_df.columns = [c+f"_ens_{i}" for c in curr_df.columns]
    curr_df["unique_id"] = [f"{image}_{cell}" for cell, image in zip(curr_df[f"cell_id"],curr_df[f"image_id"])]
    
    # exchange 1 and 0 as assignment was done alphabetically -> 1 meaning prediction of this cell type
    if sorted([cell_name, "not"],key=str.casefold)[-1] == "not":
        dic = {1:0,0:1, -1:-1}
        curr_df["pred"] = [dic[x] for x in curr_df["pred"]]
        curr_df["label"] = [dic[x] for x in curr_df["label"]]
    
    # compute FPR
    values = curr_df["label"][(curr_df["pred"] == 1) & (curr_df["pred_prob"] >= 0.8)]
    values = values[values != -1]
    FPR = np.sum(values == 0)/len(values)
    FPR_list.append(FPR)
    
    if df_all_labeled.empty:
        curr_df = curr_df[["image_id", "cell_id","unique_id","pred","pred_prob","label"]]
        # add suffix to first dataframe
        curr_df.rename(columns={"pred": f"pred_{cell_name}", "pred_prob": f"pred_prob_{cell_name}", "label": f"label_{cell_name}"}, inplace = True)
        df_all_labeled = curr_df
    else:
        curr_df = curr_df[["unique_id","pred","pred_prob","label"]]
        # add suffix to dataframe
        curr_df.rename(columns={"pred": f"pred_{cell_name}", "pred_prob": f"pred_prob_{cell_name}", "label": f"label_{cell_name}"}, inplace = True)
        df_all_labeled = pd.merge(df_all_labeled,curr_df,on="unique_id", suffixes=("",""))
        # df_all_labeled = pd.concat([df_all_labeled, curr_df], axis=1)



# Extract predictions
# create prediciton and probability arrays
predictions = df_all_labeled[[f"pred_{cell_name}" for cell_name in cell_names]].to_numpy()
probability = df_all_labeled[[f"pred_prob_{cell_name}" for cell_name in cell_names]].to_numpy()

# scale probability by FPR
probability = probability-np.array(FPR_list)*0.05


# extract prediciton with max probablity
a = probability * predictions
final_pred = a.argmax(axis = 1)
# set those without any prediciton to -1
final_pred[np.logical_not(a.any(axis=1))] = -1


# Extract label
labels = []
label_id = df_all_labeled[[f"label_{cell_name}" for cell_name in cell_names]].to_numpy()
cell_names = np.array(cell_names)
for i in range(label_id.shape[0]):
    boolean = label_id[i] == 1
    if sum(boolean) == 0:
        label = "unlabelled"
    else:
        label = cell_names[boolean].item()

    labels.append(label)
    
# Compute certainty metric
loss_ones = np.copy(probability)
loss_ones[predictions == 0] = 0
for i in range(loss_ones.shape[0]):
    loss_ones[i,final_pred[i]] = 0

loss_zeros = np.full(probability.shape,100.)
loss_zeros[predictions == 1] = 0
loss_zeros[predictions == 0] -= probability[predictions == 0]*100

certainty = (np.full(probability.shape[0],1400) - np.sum((loss_zeros + loss_ones),axis=1))/1400

# final prediction
cell_names_dict = {}
for i,cell_name in enumerate(cell_names):
    cell_names_dict[i] = cell_name


results = pd.DataFrame()
# create final dataframe  
results["image_id"] = df_all_labeled["image_id"]
results["cell_id"] = df_all_labeled["cell_id"]
results["pred_prob"] = a.max(axis = 1)
results["certainty"] = certainty
results["final_pred"] = [cell_names_dict[x] if x in cell_names_dict.keys() else "undefined" for x in final_pred]
results["label"] = labels


# save results
results.to_csv(os.path.join(base_path, "merged_results.csv"))
