library(tidytext)
library(tidyverse)
library(sentimentr)
library(wordcloud)
library(SnowballC)
library(RColorBrewer)
library(reshape2)
library(knitr)
library(broom)
library(pander)
library(modelr)
library(caret)
library(stringr)
library(feather)

# Import data
genre_tidy <- read_feather("./data/genre_tidy.feather")
text_tidy <- read_feather("./data/text_tidy.feather")
text_tfidf <- read_feather("./data/text_tfidf.feather")
text_raw <- read_feather("./data/text_raw.feather")
games_lda <- read_feather("./data/games_lda.feather")
text_sentTfidf <- read_feather("./data/text_sentTfidf.feather")

# Create topic sub groups
# (We know we can do for loops here, but I believe you understand, we really don't have time for that..)
topic_generaldata <- text_sentTfidf %>%
  left_join(games_lda, c("GameTitle" = "document"))

topic_generaldata <- topic_generaldata%>%
  mutate(topic1 = topic_generaldata$'1',
         topic2 = topic_generaldata$'2',
         topic3 = topic_generaldata$'3',
         topic4 = topic_generaldata$'4')

Topic1_raw <- topic_generaldata %>%
  filter(topic1 > 0.5) %>%
  mutate(topic = "social")
Topic2_raw <- topic_generaldata %>%
  filter(topic2 > 0.5) %>%
  mutate(topic = "achieve")
Topic3_raw <- topic_generaldata %>%
  filter(topic3 > 0.5)%>%
  mutate(topic = "explore")
Topic4_raw <- topic_generaldata %>%
  filter(topic4 > 0.5) %>%
  mutate(topic = "killer")

Topic1_text <-Topic1_raw %>%
  mutate(Review = as.character(Review)) %>%
  unnest_tokens(word, Review, token = "words",to_lower = TRUE) %>%
  filter(!word %in% stop_words$word,
         str_detect(word, "[a-z]")) %>%
  anti_join(stop_words) %>%
  mutate(word = wordStem(word))

Topic2_text <-Topic2_raw %>%
  mutate(Review = as.character(Review)) %>%
  unnest_tokens(word, Review, token = "words",to_lower = TRUE) %>%
  filter(!word %in% stop_words$word,
         str_detect(word, "[a-z]")) %>%
  anti_join(stop_words) %>%
  mutate(word = wordStem(word))

Topic3_text <-Topic3_raw %>%
  mutate(Review = as.character(Review)) %>%
  unnest_tokens(word, Review, token = "words",to_lower = TRUE) %>%
  filter(!word %in% stop_words$word,
         str_detect(word, "[a-z]")) %>%
  anti_join(stop_words) %>%
  mutate(word = wordStem(word))

Topic4_text <-Topic4_raw %>%
  mutate(Review = as.character(Review)) %>%
  unnest_tokens(word, Review, token = "words",to_lower = TRUE) %>%
  filter(!word %in% stop_words$word,
         str_detect(word, "[a-z]")) %>%
  anti_join(stop_words) %>%
  mutate(word = wordStem(word))

nrc <- get_sentiments("nrc") %>%
  mutate(word = wordStem(word)) %>%
  distinct()

bing <-  get_sentiments("bing") %>%
  mutate(word = wordStem(word)) %>%
  distinct()

# Sentiment exploration by topics
# Get the plot about the sentiment word most frequently used in game reviews
Topic1_bing_word_counts <- Topic1_text %>%
  inner_join(bing, by = "word") %>%
  count(word, sentiment, sort = TRUE) %>%
  ungroup()

Topic1_bing_word_counts %>%
  filter(n > 500) %>%
  mutate(n = ifelse(sentiment == "negative", -n, n)) %>%
  mutate(word = reorder(word, n)) %>%
  ggplot(aes(word, n, fill = sentiment)) +
  geom_bar(alpha = 0.8, stat = "identity") +
  labs(y = "Contribution to sentiment",
       x = "Social") +
  coord_flip()

Topic2_bing_word_counts <- Topic2_text %>%
  inner_join(bing, by = "word") %>%
  count(word, sentiment, sort = TRUE) %>%
  ungroup()

Topic2_bing_word_counts %>%
  filter(n > 500) %>%
  mutate(n = ifelse(sentiment == "negative", -n, n)) %>%
  mutate(word = reorder(word, n)) %>%
  ggplot(aes(word, n, fill = sentiment)) +
  geom_bar(alpha = 0.8, stat = "identity") +
  labs(y = "Contribution to sentiment",
       x = "Achieve") +
  coord_flip()

Topic3_bing_word_counts <- Topic3_text %>%
  inner_join(bing, by = "word") %>%
  count(word, sentiment, sort = TRUE) %>%
  ungroup()

Topic3_bing_word_counts %>%
  filter(n > 500) %>%
  mutate(n = ifelse(sentiment == "negative", -n, n)) %>%
  mutate(word = reorder(word, n)) %>%
  ggplot(aes(word, n, fill = sentiment)) +
  geom_bar(alpha = 0.8, stat = "identity") +
  labs(y = "Contribution to sentiment",
       x = "Explore") +
  coord_flip()

Topic4_bing_word_counts <- Topic4_text %>%
  inner_join(bing, by = "word") %>%
  count(word, sentiment, sort = TRUE) %>%
  ungroup()

Topic4_bing_word_counts %>%
  filter(n > 400) %>%
  mutate(n = ifelse(sentiment == "negative", -n, n)) %>%
  mutate(word = reorder(word, n)) %>%
  ggplot(aes(word, n, fill = sentiment)) +
  geom_bar(alpha = 0.8, stat = "identity") +
  labs(y = "Contribution to sentiment",
       x = "Killer") +
  coord_flip()

Topic1_level <- Topic1_text %>%
  mutate(level = ifelse(GSScore.x > 8.5, "high",
                        ifelse(GSScore.x < 5, "low", "medium"))) %>%
  filter(is.na(level) == F )

Topic1_level_count <- Topic1_level %>%
  count(level)

Topic1_sentCount <- Topic1_level %>%
  inner_join(nrc, by = "word") %>%
  count(level, sentiment)

Topic1_text_sent_nrc_analysis <- Topic1_sentCount %>%
  inner_join(Topic1_level_count, by = "level") %>%
  mutate(percentage = n.x / n.y)

Topic1_text_sent_nrc_analysis %>%
  filter((sentiment != "negative") & (sentiment != "positive"))%>%
  ggplot(aes(sentiment, percentage))+
  geom_bar(aes(fill = sentiment), stat = "identity")+
  facet_wrap(~ level, nrow = 2)+
  ggtitle("The different types of sentiment words proportion in game reviews-social")+
  coord_polar()

Topic2_level <- Topic2_text %>%
  mutate(level = ifelse(GSScore.x > 8.5, "high",
                        ifelse(GSScore.x < 5, "low", "medium"))) %>%
  filter(is.na(level) == F )

Topic2_level_count <- Topic2_level %>%
  count(level)

Topic2_sentCount <- Topic2_level %>%
  inner_join(nrc, by = "word") %>%
  count(level, sentiment)

Topic2_text_sent_nrc_analysis <- Topic2_sentCount %>%
  inner_join(Topic2_level_count, by = "level") %>%
  mutate(percentage = n.x / n.y)

Topic2_text_sent_nrc_analysis %>%
  filter((sentiment != "negative") & (sentiment != "positive"))%>%
  ggplot(aes(sentiment, percentage))+
  geom_bar(aes(fill = sentiment), stat = "identity")+
  facet_wrap(~ level, nrow = 2)+
  ggtitle("The different types of sentiment words proportion in game reviews-achieve")+
  coord_polar()

Topic3_level <- Topic3_text %>%
  mutate(level = ifelse(GSScore.x > 8.5, "high",
                        ifelse(GSScore.x < 5, "low", "medium"))) %>%
  filter(is.na(level) == F )

Topic3_level_count <- Topic3_level %>%
  count(level)

Topic3_sentCount <- Topic3_level %>%
  inner_join(nrc, by = "word") %>%
  count(level, sentiment)

Topic3_text_sent_nrc_analysis <- Topic3_sentCount %>%
  inner_join(Topic3_level_count, by = "level") %>%
  mutate(percentage = n.x / n.y)

Topic3_text_sent_nrc_analysis %>%
  filter((sentiment != "negative") & (sentiment != "positive"))%>%
  ggplot(aes(sentiment, percentage))+
  geom_bar(aes(fill = sentiment), stat = "identity")+
  facet_wrap(~ level, nrow = 2)+
  ggtitle("The different types of sentiment words proportion in game reviews-explore")+
  coord_polar()

Topic4_level <- Topic4_text %>%
  mutate(level = ifelse(GSScore.x > 8.5, "high",
                        ifelse(GSScore.x < 5, "low", "medium"))) %>%
  filter(is.na(level) == F )

Topic4_level_count <- Topic4_level %>%
  count(level)

Topic4_sentCount <- Topic4_level %>%
  inner_join(nrc, by = "word") %>%
  count(level, sentiment)

Topic4_text_sent_nrc_analysis <- Topic4_sentCount %>%
  inner_join(Topic4_level_count, by = "level") %>%
  mutate(percentage = n.x / n.y)

Topic4_text_sent_nrc_analysis %>%
  filter((sentiment != "negative") & (sentiment != "positive"))%>%
  ggplot(aes(sentiment, percentage))+
  geom_bar(aes(fill = sentiment), stat = "identity")+
  facet_wrap(~ level, nrow = 2)+
  ggtitle("The different types of sentiment words proportion in game reviews-killer")+
  coord_polar()

Topic1_text_tfidf <- Topic1_text %>%
  group_by(GameTitle) %>%
  count(word, sort = TRUE) %>%
  bind_tf_idf(word, GameTitle, n)


Topic2_text_tfidf <- Topic2_text %>%
  group_by(GameTitle) %>%
  count(word, sort = TRUE) %>%
  bind_tf_idf(word, GameTitle, n)


Topic3_text_tfidf <- Topic3_text %>%
  group_by(GameTitle) %>%
  count(word, sort = TRUE) %>%
  bind_tf_idf(word, GameTitle, n) 


Topic4_text_tfidf <- Topic4_text %>%
  group_by(GameTitle) %>%
  count(word, sort = TRUE) %>%
  bind_tf_idf(word, GameTitle, n) 

Topic1_text_sentCount <- Topic1_text %>%
  inner_join(nrc, by = "word") %>%
  group_by(sentiment) %>%
  count(word)

Topic2_text_sentCount <- Topic2_text %>%
  inner_join(nrc, by = "word") %>%
  group_by(sentiment) %>%
  count(word)

Topic3_text_sentCount <- Topic3_text %>%
  inner_join(nrc, by = "word") %>%
  group_by(sentiment) %>%
  count(word)

Topic4_text_sentCount <- Topic4_text %>%
  inner_join(nrc, by = "word") %>%
  group_by(sentiment) %>%
  count(word)

Topic1_text_sentTfidf <- Topic1_text_tfidf %>%
  left_join(Topic1_text_sentCount, by = "word") %>%
  group_by(GameTitle, sentiment) %>%
  summarize(tfidfScore = sum(tf_idf)) %>%
  spread(sentiment, tfidfScore) %>%
  left_join(text_raw, by = "GameTitle") %>%
  select(-`<NA>`, -Review) %>%
  na.omit()

# Exploratory
Topic1_text_sentTfidf_plt <- Topic1_text_sentTfidf %>%
  gather(sentiment, tfidf, anger : trust)

ggplot(filter(Topic1_text_sentTfidf_plt, sentiment %in% c("anger", "disgust", "fear", "sadness")),
       aes(tfidf, GSScore)) + 
  geom_jitter(height = 0.1, width = 0.1, alpha = 0.2) +
  geom_smooth(method = lm) +
  facet_wrap(~ sentiment)+
  ggtitle("Social")

ggplot(filter(Topic1_text_sentTfidf_plt, sentiment %in% c("anticipation", "joy", "surprise", "trust")),
       aes(tfidf, GSScore)) + 
  geom_jitter(height = 0.1, width = 0.1, alpha = 0.2) +
  geom_smooth(method = lm) +
  facet_wrap(~ sentiment)+
  ggtitle("Social")

Topic2_text_sentTfidf <- Topic2_text_tfidf %>%
  left_join(Topic2_text_sentCount, by = "word") %>%
  group_by(GameTitle, sentiment) %>%
  summarize(tfidfScore = sum(tf_idf)) %>%
  spread(sentiment, tfidfScore) %>%
  left_join(text_raw, by = "GameTitle") %>%
  select(-`<NA>`, -Review) %>%
  na.omit()

Topic2_text_sentTfidf_plt <- Topic2_text_sentTfidf %>%
  gather(sentiment, tfidf, anger : trust)

ggplot(filter(Topic2_text_sentTfidf_plt, sentiment %in% c("anger", "disgust", "fear", "sadness")),
       aes(tfidf, GSScore)) + 
  geom_jitter(height = 0.1, width = 0.1, alpha = 0.2) +
  geom_smooth(method = lm) +
  facet_wrap(~ sentiment)+
  ggtitle("Achieve")

ggplot(filter(Topic2_text_sentTfidf_plt, sentiment %in% c("anticipation", "joy", "surprise", "trust")),
       aes(tfidf, GSScore)) + 
  geom_jitter(height = 0.1, width = 0.1, alpha = 0.2) +
  geom_smooth(method = lm) +
  facet_wrap(~ sentiment)+
  ggtitle("Achieve")

Topic3_text_sentTfidf <- Topic3_text_tfidf %>%
  left_join(Topic3_text_sentCount, by = "word") %>%
  group_by(GameTitle, sentiment) %>%
  summarize(tfidfScore = sum(tf_idf)) %>%
  spread(sentiment, tfidfScore) %>%
  left_join(text_raw, by = "GameTitle") %>%
  select(-`<NA>`, -Review) %>%
  na.omit()

Topic3_text_sentTfidf_plt <- Topic3_text_sentTfidf %>%
  gather(sentiment, tfidf, anger : trust)

ggplot(filter(Topic3_text_sentTfidf_plt, sentiment %in% c("anger", "disgust", "fear", "sadness")),
       aes(tfidf, GSScore)) + 
  geom_jitter(height = 0.1, width = 0.1, alpha = 0.2) +
  geom_smooth(method = lm) +
  facet_wrap(~ sentiment)+
  ggtitle("Explore")

ggplot(filter(Topic3_text_sentTfidf_plt, sentiment %in% c("anticipation", "joy", "surprise", "trust")),
       aes(tfidf, GSScore)) + 
  geom_jitter(height = 0.1, width = 0.1, alpha = 0.2) +
  geom_smooth(method = lm) +
  facet_wrap(~ sentiment)+
  ggtitle("Explore")

Topic4_text_sentTfidf <- Topic4_text_tfidf %>%
  left_join(Topic4_text_sentCount, by = "word") %>%
  group_by(GameTitle, sentiment) %>%
  summarize(tfidfScore = sum(tf_idf)) %>%
  spread(sentiment, tfidfScore) %>%
  left_join(text_raw, by = "GameTitle") %>%
  select(-`<NA>`, -Review) %>%
  na.omit()

Topic4_text_sentTfidf_plt <- Topic4_text_sentTfidf %>%
  gather(sentiment, tfidf, anger : trust)

ggplot(filter(Topic4_text_sentTfidf_plt, sentiment %in% c("anger", "disgust", "fear", "sadness")),
       aes(tfidf, GSScore)) + 
  geom_jitter(height = 0.1, width = 0.1, alpha = 0.2) +
  geom_smooth(method = lm) +
  facet_wrap(~ sentiment)+
  ggtitle("Killer")

ggplot(filter(Topic4_text_sentTfidf_plt, sentiment %in% c("anticipation", "joy", "surprise", "trust")),
       aes(tfidf, GSScore)) + 
  geom_jitter(height = 0.1, width = 0.1, alpha = 0.2) +
  geom_smooth(method = lm) +
  facet_wrap(~ sentiment)+
  ggtitle("Killer")

Topic1_text_sentTfidf <- Topic1_text_sentTfidf %>%
  mutate(GSScore_cat1 = cut(GSScore,
                            c(0, (mean(text_sentTfidf$GSScore) - sd(text_sentTfidf$GSScore)), (mean(text_sentTfidf$GSScore) + sd(text_sentTfidf$GSScore)), 10),
                            labels = c("Low", "Medium", "High")),
         GSScore_cat2 = cut(GSScore,
                            c(0, mean(text_sentTfidf$GSScore), 10),
                            labels = c("Low", "High")))

# Divide training and testing groups, apply 5-fold cross validation, repeat 10 times
Topic1_inTraining <- resample_partition(Topic1_text_sentTfidf, c(testing = 0.3, training = 0.7))
Topic1_training <- Topic1_inTraining$training %>% tbl_df()
Topic1_testing <- Topic1_inTraining$testing %>% tbl_df()


fitControl <- trainControl(
  method = "repeatedcv",
  number = 5,
  repeats = 10)

Topic1_gam_fit1 <- train(GSScore ~ positive + negative, data = Topic1_training, method = 'gamLoess', trControl = fitControl)
Topic1_gam_fit2 <- train(GSScore ~ anticipation + trust + surprise + joy + sadness + anger + fear + disgust, data = Topic1_training, method = 'gamLoess', trControl = fitControl)
pander(summary(Topic1_gam_fit1)[4])
pander(summary(Topic1_gam_fit2)[4])

Topic1_gam_pred <- predict(Topic1_gam_fit2, Topic1_testing)
pander(postResample(pred = Topic1_gam_pred, obs = Topic1_testing$GSScore))

Topic2_text_sentTfidf <- Topic2_text_sentTfidf %>%
  mutate(GSScore_cat1 = cut(GSScore,
                            c(0, (mean(text_sentTfidf$GSScore) - sd(text_sentTfidf$GSScore)), (mean(text_sentTfidf$GSScore) + sd(text_sentTfidf$GSScore)), 10),
                            labels = c("Low", "Medium", "High")),
         GSScore_cat2 = cut(GSScore,
                            c(0, mean(text_sentTfidf$GSScore), 10),
                            labels = c("Low", "High")))

Topic2_inTraining <- resample_partition(Topic2_text_sentTfidf, c(testing = 0.3, training = 0.7))
Topic2_training <- Topic2_inTraining$training %>% tbl_df()
Topic2_testing <- Topic2_inTraining$testing %>% tbl_df()


Topic2_gam_fit1 <- train(GSScore ~ positive + negative, data = Topic2_training, method = 'gamLoess', trControl = fitControl)
Topic2_gam_fit2 <- train(GSScore ~ anticipation + trust + surprise + joy + sadness + anger + fear + disgust, data = Topic2_training, method = 'gamLoess', trControl = fitControl)
pander(summary(Topic2_gam_fit1)[4])
pander(summary(Topic2_gam_fit2)[4])

Topic2_gam_pred <- predict(Topic2_gam_fit2, Topic2_testing)
pander(postResample(pred = Topic2_gam_pred, obs = Topic2_testing$GSScore))

Topic3_text_sentTfidf <- Topic3_text_sentTfidf %>%
  mutate(GSScore_cat1 = cut(GSScore,
                            c(0, (mean(text_sentTfidf$GSScore) - sd(text_sentTfidf$GSScore)), (mean(text_sentTfidf$GSScore) + sd(text_sentTfidf$GSScore)), 10),
                            labels = c("Low", "Medium", "High")),
         GSScore_cat2 = cut(GSScore,
                            c(0, mean(text_sentTfidf$GSScore), 10),
                            labels = c("Low", "High")))

Topic3_inTraining <- resample_partition(Topic3_text_sentTfidf, c(testing = 0.3, training = 0.7))
Topic3_training <- Topic3_inTraining$training %>% tbl_df()
Topic3_testing <- Topic3_inTraining$testing %>% tbl_df()

Topic3_gam_fit1 <- train(GSScore ~ positive + negative, data = Topic3_training, method = 'gamLoess', trControl = fitControl)
Topic3_gam_fit2 <- train(GSScore ~ anticipation + trust + surprise + joy + sadness + anger + fear + disgust, data = Topic3_training, method = 'gamLoess', trControl = fitControl)
pander(summary(Topic3_gam_fit1)[4])
pander(summary(Topic3_gam_fit2)[4])

Topic3_gam_pred <- predict(Topic3_gam_fit2, Topic3_testing)
pander(postResample(pred = Topic3_gam_pred, obs = Topic3_testing$GSScore))

Topic4_text_sentTfidf <- Topic4_text_sentTfidf %>%
  mutate(GSScore_cat1 = cut(GSScore,
                            c(0, (mean(text_sentTfidf$GSScore) - sd(text_sentTfidf$GSScore)), (mean(text_sentTfidf$GSScore) + sd(text_sentTfidf$GSScore)), 10),
                            labels = c("Low", "Medium", "High")),
         GSScore_cat2 = cut(GSScore,
                            c(0, mean(text_sentTfidf$GSScore), 10),
                            labels = c("Low", "High")))

Topic4_inTraining <- resample_partition(Topic4_text_sentTfidf, c(testing = 0.3, training = 0.7))
Topic4_training <- Topic4_inTraining$training %>% tbl_df()
Topic4_testing <- Topic4_inTraining$testing %>% tbl_df()

Topic4_gam_fit1 <- train(GSScore ~ positive + negative, data = Topic4_training, method = 'gamLoess', trControl = fitControl)
Topic4_gam_fit2 <- train(GSScore ~ anticipation + trust + surprise + joy + sadness + anger + fear + disgust, data = Topic4_training, method = 'gamLoess', trControl = fitControl)
pander(summary(Topic4_gam_fit1)[4])
pander(summary(Topic4_gam_fit2)[4])

Topic4_gam_pred <- predict(Topic4_gam_fit2, Topic4_testing)
pander(postResample(pred = Topic4_gam_pred, obs = Topic4_testing$GSScore))
