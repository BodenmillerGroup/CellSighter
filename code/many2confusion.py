#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Feb 27 13:03:15 2023

@author: bp
"""

import os
import argparse
import pandas as pd
import json
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.metrics import confusion_matrix
from matplotlib.colors import LinearSegmentedColormap


def metric(gt, pred, classes_for_cm, title, colorbar=True):
    sns.set(font_scale=2)
    cm_normed_recall = confusion_matrix(gt, pred, labels=classes_for_cm, normalize="true") * 100
    cm = confusion_matrix(gt, pred, labels=classes_for_cm)

    plt.figure(figsize=(50,45))
    ax1 = plt.subplot2grid((50,50), (0,0), colspan=30, rowspan=30)
    cmap = LinearSegmentedColormap.from_list('', ['white', *plt.cm.Blues(np.arange(255))])
    annot_labels = cm_normed_recall.round(1).astype(str)
    annot_labels = pd.DataFrame(annot_labels) + "\n (" + pd.DataFrame(cm).astype(str)+")"

    annot_mask = cm_normed_recall.round(1) <= 0.1
    annot_labels[annot_mask] = ""

    sns.heatmap(cm_normed_recall.T, ax=ax1, annot=annot_labels.T, fmt='',cbar = colorbar,
                cmap=cmap,linewidths=1, vmin=0, vmax=100,linecolor='black', square=True)
    
    
    # ax1.tick_params(top=True,labeltop=True,labelbottom=False, axis='both', which='major', labelsize=35)
    ax1.xaxis.tick_top()
    ax1.set_xticklabels(classes_for_cm, rotation = 90)
    ax1.set_yticklabels(classes_for_cm, rotation = 0)
    ax1.tick_params(axis='both', which='major', labelsize=35)

    ax1.set_xlabel("Clustering and gating", fontsize=35)
    ax1.set_ylabel("CellSighter", fontsize=35)
    
    ax1.set_title(title)



if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Arguments')
    parser.add_argument('--base_path', type=str,
                        help='configuration_path')
    args = parser.parse_args()
    results_path = os.path.join(args.base_path, "merged_ensemble.csv")
    
    # # import hyperparamteres used
    # config_path = os.path.join(args.base_path, "config.json")
    # with open(config_path) as f:
    #     config = json.load(f)
    #     hyperparams = f'crop_input_size: {config["crop_input_size"]}, crop_size: {config["crop_size"]}, epoch_max: {config["epoch_max"]}, lr: {config["lr"]},\n#train_set: {len(config["train_set"])}, #val_set: {len(config["val_set"])}, to_pad: {config["to_pad"]}, sample_batch: {config["sample_batch"]}, size_data: {config["size_data"]}, aug: {config["aug"]},\nhierarchy_match: {config["hierarchy_match"]},\nblacklist: {config["blacklist"]}'
    
    
    # create figure
    # fig, ax = plt.subplots(1,2)
    # compute confusion matrix
    save_path = os.path.join(args.base_path, "merged_confusion_matrix.png")
    results = pd.read_csv(results_path) #Fill in the path to your results file
    classes_for_cm = np.unique(np.concatenate([results["label"], results["final_pred"]]))
    hyperparams = "title"
    metric(results["label"], results["final_pred"], classes_for_cm, hyperparams)
    
    plt.savefig(save_path)
    
    # compute confusion matrix with predictions with probability higher than 0.75
    # results = results.loc[results.pred_prob_per_max >= 0.75,]
    # save_path_75 = os.path.join(args.base_path, "merged_confusion_matrix_75.png")
    # metric(results["label"], results["pred_per_max"], classes_for_cm, hyperparams)
    # plt.savefig(save_path_75)
    
    # TODO: put plots into one figure
    # TODO: visulaize how many cells have pred_prob > x
    # TODO: add labels instead of numbers as ticks
    