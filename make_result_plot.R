library(dplyr)
library(ggplot2)
library(tidyr)

turn_df_to_proper_format <- function(df){
  
  
  pos <- df[, c(1:3)]
  neg <- df[, c(4:6)]
  
  colnames(pos) <- c("precision", "recall", "f1")
  pos <- pos %>% 
    mutate(type = "positive_sample")
  
  colnames(neg) <- c("precision", "recall", "f1")
  neg <- neg %>% 
    mutate(type = "negative_sample")
  
  proper_format <- rbind(pos, neg)
  return(proper_format)
}

path_to_data <- "polmeth_asia_paper/presentation_data"

fusion_results <- "fusion_model_result.csv"
bert_results <- "bert_model_result.csv"
logistic_results <- "logistic_regression_results.csv"
naive_bayes_results <- "naive_bayes_results.csv"
svm_results <- "svm_results.csv"

fusion_model <- read.csv(file.path(path_to_data, fusion_results))

fusion_model <- turn_df_to_proper_format(fusion_model)
fusion_model <- fusion_model %>% 
  mutate(model = "fusion")


bert_model <- read.csv(file.path(path_to_data, bert_results))

bert_model <- turn_df_to_proper_format(bert_model)
bert_model <- bert_model %>% 
  mutate(model = "bert")


naive_bayes_model <- read.csv(file.path(path_to_data, naive_bayes_results))

naive_bayes_model <- turn_df_to_proper_format(naive_bayes_model)
naive_bayes_model <- naive_bayes_model %>% 
  mutate(model = "nb")



logistic_model <- read.csv(file.path(path_to_data, logistic_results))

logistic_model <- turn_df_to_proper_format(logistic_model)
logistic_model <- logistic_model %>% 
  mutate(model = "logistic")

svm_model <- read.csv(file.path(path_to_data, svm_results))

svm_model <- turn_df_to_proper_format(svm_model)
svm_model <- svm_model %>% 
  mutate(model = "svm")

full_results_data <- rbind(fusion_model, bert_model, naive_bayes_model, logistic_model, svm_model)

positive_sample_results <- full_results_data %>% 
  filter(type == 'positive_sample') %>% 
  gather("measure", "score", -c("type", "model"))

negative_sample_results <- full_results_data %>% 
  filter(type == 'negative_sample') %>% 
  gather("measure", "score", -c("type", "model"))

pd <- position_dodge(0.2)

positive_sample_plot <- positive_sample_results %>% 
  ggplot(aes(y = score, x = measure, col = model)) +
  geom_line(position = pd) + 
  geom_point(position = pd) + 
  scale_y_continuous(name = "Score", breaks = seq(0, 1, 0.025)) + 
  scale_x_discrete(name = "Measure",  labels = c("F1 Score", "Precision",  "Recall")) +
  theme_bw() + 
  ggtitle("Validation Performance for Support Tweets (Majority Class)") + 
  scale_color_discrete(name = "Model", labels = c("Bert", "Fusion Model", "Logistic Regression", "Naive Bayes", "SVM")) + 
  coord_flip()


negative_sample_plot <- negative_sample_results %>% 
  ggplot(aes(y = score, x = measure, col = model)) +
  geom_line(position = pd) + 
  geom_point(position = pd) + 
  scale_y_continuous(name = "Score", breaks = seq(0, 1, 0.05)) + 
  scale_x_discrete(name = "Measure",  labels = c("Recall", "Precision",  "F1 Score")) +
  scale_color_discrete(name = "Model", labels = c("Bert", "Fusion Model", "Logistic Regression", "Naive Bayes", "SVM")) + 
  theme_bw() + 
  ggtitle("Validation Performance for Non-support Tweets (Minority Class") +
  coord_flip()

  
  
  