# -*- coding: utf-8 -*-

from transformers import RobertaForSequenceClassification, Trainer, TrainingArguments
from transformers import RobertaTokenizerFast
import torch
import torch.nn as nn
import pandas as pd
import re
from typing import List
from torch.nn import CrossEntropyLoss, NLLLoss
from torch.utils.data import Dataset, DataLoader
import torch.optim
from sklearn.model_selection import train_test_split
import tensorboard
from sklearn.metrics import accuracy_score, precision_recall_fscore_support


"""stance_net

Automatically generated by Colaboratory.

Original file is located at
    https://colab.research.google.com/drive/14T7ZIg952o-FnIYtFNuD6C18WiySqN5r
"""


class HashtagDataset(Dataset):
    sampler_hashtags = ['WearAMask',
                        'Masks4All',
                        'WearADamnMask',
                        'NoMasks',
                        'Trump2020',
                        'NoMask',
                        'MasksOff',
                        'Scamdemic',
                        'CovidHoax']

    hashtag_regex = re.compile('#\S*')

    def __init__(self, input_text: List, input_labels: List):

        self.input_text = input_text
        self.input_labels = input_labels

    def __len__(self):
        return len(self.input_labels)

    def __getitem__(self, idx):

        item = {key: torch.tensor(val[idx]) for key, val in self.input_text.items()}
        label = self.input_labels[idx]
        item['labels'] = torch.tensor(label)

        item = {k: v.to(device) for k, v in item.items()}
        return item


def format_tweet_file(tweet_file):
    tweet_file.loc[:, 'text'] = tweet_file.text.str.lower()
    tweet_file.loc[:, 'label'] = [1 if x == 'support' else 0 for x in tweet_file.label]

    tweet_file.loc[:, 'text'] = [HashtagDataset.hashtag_regex.sub('', x) for x in tweet_file.text.values]

    return tweet_file


def process_input(input, target, tokenizer):
    encoding = tokenizer.tokenize(input, return_tensors='pt', padding=True, truncation=True)
    input_tensor = encoding['input_ids']
    attention_mask = encoding['attention_mask']

    input_tensor.to(device)
    attention_mask.to(device)

    target_tensor = torch.tensor(target)
    target_tensor.to(device)

    return input_tensor, attention_mask, target_tensor


def compute_metrics(pred):
    labels = pred.label_ids
    preds = pred.predictions.argmax(-1)
    precision, recall, f1, _ = precision_recall_fscore_support(labels, preds, average='binary')
    acc = accuracy_score(labels, preds)
    return {
        'accuracy': acc,
        'f1': f1,
        'precision': precision,
        'recall': recall
    }

def main():
    number_of_epochs = 1
    initial_lr = 1e-5
    device = torch.device("cuda:0" if torch.cuda.is_available() else "cpu")
    print(f"device is {device}")

    data = pd.read_pickle('labelled_tweets_set.pkl')
    data = format_tweet_file(data)

    screen_name_map = 'drive/My Drive/mask_stance_neural_net/edgelist/id_screen_name_map.pkl'
    path_to_map = \
    'drive/My Drive/mask_stance_neural_net/edgelist/int_screen_name_map.pkl'

    path_to_other_labelled_samples = \
    'drive/My Drive/mask_stance_neural_net/labelled_tweets_sample.csv'

    path_to_output = 'drive/My Drive/mask_stance_neural_net/testset_predicted_text_only.pkl'

    id_sc_map = pd.read_pickle(screen_name_map)
    data.loc[:, 'screen_name'] = [id_sc_map[user_id] for user_id in data.user_id]

    user_name_map = pd.read_pickle(path_to_map)

    extra_labelled_samples = pd.read_csv(path_to_other_labelled_samples)
    extra_labelled_samples = extra_labelled_samples.rename(columns={'labels': 'label'})

    data = pd.concat([data, extra_labelled_samples], ignore_index=True)
    data = data.loc[data.screen_name.isin(user_name_map.keys()), :]

    tokenizer = RobertaTokenizerFast.from_pretrained('roberta-base')
    text_sequences = tokenizer(data.text.tolist(), padding=True, truncation=True, max_length=200)
    print('tokenized sequence')

    model = RobertaForSequenceClassification.from_pretrained('roberta-base', return_dict=True)

    model.to(device)
    model.train()


    dataset_object = HashtagDataset(text_sequences, data.label.tolist())

    train_length = int(len(dataset_object) * 0.8)
    test_length = len(dataset_object) - train_length

    train_dataset, test_dataset = torch.utils.data.random_split(dataset_object,
                                                                lengths=[train_length, test_length],
                                                                generator=torch.Generator().manual_seed(42))

    num_epochs = 5

    training_args = TrainingArguments(
            output_dir='./results',          # output directory
            num_train_epochs=num_epochs,              # total # of training epochs
            per_device_train_batch_size=32,  # batch size per device during training
            per_device_eval_batch_size=64,   # batch size for evaluation
            warmup_steps=500,                # number of warmup steps for learning rate scheduler
            weight_decay=0.05,               # strength of weight decay
            logging_dir='./logs',            # directory for storing logs
            save_steps=10000
        )

    trainer = Trainer(model=model,
                      args=training_args,
                      train_dataset=train_dataset,
                      eval_dataset=test_dataset,
                      compute_metrics=compute_metrics)

    trainer.train()

    predictions = trainer.predict(test_dataset=test_dataset)

    predicted = np.argmax(predictions.predictions, axis=1)
    golden_labels = predictions.label_ids

    print(metrics.precision_score(golden_labels, predicted, pos_label=1))
    print(metrics.recall_score(golden_labels, predicted, pos_label=1))
    print(metrics.f1_score(golden_labels, predicted, pos_label=1))
    print(metrics.precision_score(golden_labels, predicted, pos_label=0))
    print(metrics.recall_score(golden_labels, predicted, pos_label=0))
    print(metrics.f1_score(golden_labels, predicted, pos_label=0))
    print(metrics.accuracy_score(golden_labels, predicted))

    test_set_tweets = test_dataset.indices
    tweets_from_testset = data.iloc[test_set_tweets, :]

    tweets_from_testset.loc[:, 'model_prediction'] = predicted
    tweets_from_testset.to_pickle()


if __name__ == "__main__":
    main()