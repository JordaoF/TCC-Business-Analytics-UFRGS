#setup

library(readr)
library(fBasics)
library(dplyr)
library(ggplot2)
library(tidyverse)
library(tidyr)
library(samplingbook)
library(lmtest)
library(arules)
library(arulesViz)
library(RColorBrewer)
library(stringr)
library(DataCombine)
library(lubridate)
library(fpp2)
library(rpart)
library(rpart.plot)
library(randomForest)
library(caTools)
library(ROCR)
library(seasonal)
library(nnet)
library(NeuralNetTools)
library(car)
library(caret)
library(e1071)
library(maps)
library(MASS)
library(plotly)
library(RColorBrewer)
library(colorRamp2)
library(grDevices)
library(xts)
library(pastecs)
library(stats)
library(dunn.test)
options(scipen=999)

# Primeiras impressões dos dados

# Janeiro 2019
planilha <- read_delim("planilha_201901.csv",
                       delim = ";", escape_double = FALSE, trim_ws = TRUE)

# Primeiros dados
head(planilha)

# attatch
attach(planilha)

# Verificando valores faltantes na base de dados
colSums(is.na(planilha))

#Substituindo os valores "<=15" da coluna numero_de_operacoes para 15
planilha$numero_de_operacoes <- trimws(planilha$numero_de_operacoes, "both")
planilha$numero_de_operacoes[planilha$numero_de_operacoes == "<= 15"] <- 15

#convertendo para numérico a coluna numero_de_operacoes
planilha$numero_de_operacoes <- as.numeric(planilha$numero_de_operacoes)

# Cria um gráfico de barras interativo com as médias de "numero_de_operacoes" para cada valor único da coluna "uf"
medias_uf <- aggregate(numero_de_operacoes ~ uf, planilha, mean, na.rm = TRUE)

plot_ly(medias_uf, x = ~uf, y = ~numero_de_operacoes, type = "bar") %>%
  layout(title = "Média de número de operações por UF", margin = list(b = 150))

# Cria um gráfico de barras interativo com as médias de "numero_de_operacoes" para cada valor único da coluna "tcb"
medias_tcb <- aggregate(numero_de_operacoes ~ tcb, planilha, mean, na.rm = TRUE)

plot_ly(medias_tcb, x = ~tcb, y = ~numero_de_operacoes, type = "bar") %>%
  layout(title = "Média de número de operações por TCB", xaxis = list(title = "TCB"), yaxis = list(title = "Média de número de operações"), margin = list(b = 150))

# Cria um gráfico de barras interativo com as médias de "numero_de_operacoes" para cada valor único da coluna "ocupacao"
medias_ocupacao <- aggregate(numero_de_operacoes ~ ocupacao, planilha, mean, na.rm = TRUE)

plot_ly(medias_ocupacao, x = ~ocupacao, y = ~numero_de_operacoes, type = "bar") %>%
  layout(title = "Média de número de operações por ocupação", margin = list(b = 150))

# Cria um gráfico de barras interativo com as médias de "numero_de_operacoes" para cada valor único da coluna "cnae_secao"
medias_cnae_secao <- aggregate(numero_de_operacoes ~ cnae_secao, planilha, mean, na.rm = TRUE)

plot_ly(medias_cnae_secao, x = ~cnae_secao, y = ~numero_de_operacoes, type = "bar") %>%
  layout(title = "Média de número de operações por CNAE seção", xaxis = list(title = "CNAE seção"), yaxis = list(title = "Média de número de operações"), margin = list(b = 150))

# Cria um gráfico de barras interativo com as médias de "numero_de_operacoes" para cada valor único da coluna "cnae_subclasse"
medias_cnae_subclasse <- aggregate(numero_de_operacoes ~ cnae_subclasse, planilha, mean, na.rm = TRUE)

plot_ly(medias_cnae_subclasse, x = ~cnae_subclasse, y = ~numero_de_operacoes, type = "bar") %>%
  layout(title = "Média de número de operações por CNAE subclasse", xaxis = list(title = "CNAE subclasse"), yaxis = list(title = "Média de número de operações"), margin = list(b = 150))

# Cria um gráfico de barras interativo com as médias de "numero_de_operacoes" para cada valor único da coluna "porte"
medias_porte <- aggregate(numero_de_operacoes ~ porte, planilha, mean, na.rm = TRUE)

plot_ly(medias_porte, x = ~porte, y = ~numero_de_operacoes, type = "bar") %>%
  layout(title = "Média de número de operações por porte", xaxis = list(title = "Porte"), yaxis = list(title = "Média de número de operações"), margin = list(b = 150))

# Cria um gráfico de barras interativo com as médias de "numero_de_operacoes" para cada valor único da coluna "modalidade"
medias_modalidade <- aggregate(numero_de_operacoes ~ modalidade, planilha, mean, na.rm = TRUE)

plot_ly(medias_modalidade, x = ~modalidade, y = ~numero_de_operacoes, type = "bar") %>%
  layout(title = "Média de número de operações por modalidade", xaxis = list(title = "Modalidade"), yaxis = list(title = "Média de número de operações"), margin = list(b = 150))

# Cria um gráfico de barras interativo com as médias de "numero_de_operacoes" para cada valor único da coluna "indexador"
medias_indexador <- aggregate(numero_de_operacoes ~ indexador, planilha, mean, na.rm = TRUE)

plot_ly(medias_indexador, x = ~indexador, y = ~numero_de_operacoes, type = "bar") %>%
  layout(title = "Média de número de operações por indexador", xaxis = list(title = "Indexador"), yaxis = list(title = "Média de número de operações"), margin = list(b = 150))

# Iterações com loop for - UF

# Template para a leitura dos arquivos csv para o banco geral
Ano1 <- c(paste0(2019,0,1:9),paste0(2019,10:12))

Ano2 <- c(paste0(2020,0,1:9),paste0(2020,10:12))

Ano3 <- c(paste0(2021,0,1:9),paste0(2021,10:12))

Ano4 <- c(paste0(2022,0,1:9),paste0(2022,10:12))

BancoGeral <-c(Ano1, Ano2, Ano3, Ano4)

# Criação de matrizes vazias com dimensão lenght(BancoGeral) x 27(número de estados))
matriz_medias_uf_operacoes <- matrix(NA, nrow = length(BancoGeral), ncol = 27,
                                     dimnames = list(BancoGeral, NULL))

# Loop for com interações por uf
for (j in 1:length(BancoGeral)) {
  End <- paste0("planilha_", BancoGeral[j], ".csv")
  planilha <- read_delim(End, delim = ";", escape_double = FALSE, trim_ws = TRUE, show_col_types = FALSE)
  
  # Substituindo os valores "<=15" da coluna numero_de_operacoes para 15
  planilha$numero_de_operacoes <- trimws(planilha$numero_de_operacoes, "both")
  planilha$numero_de_operacoes[planilha$numero_de_operacoes == "<= 15"] <- 15
  
  # Convertendo para numérico a coluna numero_de_operacoes
  planilha$numero_de_operacoes <- as.numeric(planilha$numero_de_operacoes)
  
  # Calculando a média da coluna numero_de_operacoes por uf
  media_uf_operacoes <- tapply(planilha$numero_de_operacoes, planilha$uf, mean)
  
  # Armazenando as médias na matriz de médias de operações por uf
  matriz_medias_uf_operacoes[j, ] <- sapply(unique(planilha$uf), function(estado) {
    replace(media_uf_operacoes[estado], is.na(media_uf_operacoes[estado]), 0)})
  
}

# Atribuindo os nomes dos estados às colunas da matriz
colnames(matriz_medias_uf_operacoes) <- unique(planilha$uf)

# Análise de série temporal e estatística descritiva básica - UF

# Criar objeto ts
matriz_medias_uf_operacoes_ts <- ts(matriz_medias_uf_operacoes, start = c(2019, 1), frequency = 12)

# Definir rótulos das linhas
dimnames(matriz_medias_uf_operacoes_ts)[[1]] <- BancoGeral

# Autoplot
autoplot(matriz_medias_uf_operacoes_ts)

# Estatística descritiva básica
stat.desc(matriz_medias_uf_operacoes_ts)

# Teste de Kruskall Wallis, Análise do RS entre 3 períodos

# Convertendo para data frame
data_frame_uf_operacoes <- as.data.frame(matriz_medias_uf_operacoes)

# Adicionar coluna de período ao data frame
data_frame_uf_operacoes <- data_frame_uf_operacoes %>%
  mutate(Periodo = rep(c("Periodo1", "Periodo2", "Periodo3"), each = 16))

# Realizar o teste de Kruskal-Wallis por períodos
kruskal_test_uf_operacoes <- kruskal.test(data_frame_uf_operacoes$RS ~ data_frame_uf_operacoes$Periodo)

# Imprimir os resultados
print(kruskal_test_uf_operacoes)

# Teste de dunn para comparações múltiplas do RS por cada um dos 3 períodos
dunn_test_uf_operacoes <- dunn.test(data_frame_uf_operacoes$RS, data_frame_uf_operacoes$Periodo, method = "holm")

# Média dos períodos - estado do Rio Grande do Sul
aggregate(data_frame_uf_operacoes$RS ~ data_frame_uf_operacoes$Periodo, data = data_frame_uf_operacoes, mean)

# Desvio Padrão dos períodos - estado do Rio Grande do Sul
aggregate(data_frame_uf_operacoes$RS ~ data_frame_uf_operacoes$Periodo, data = data_frame_uf_operacoes, sd)

# Criação da Matriz de médias por Cartão de Crédito PF
matriz_medias_cartao_de_credito_pf <- matrix(NA, nrow = length(BancoGeral), ncol = 10,
                                             dimnames = list(BancoGeral, NULL))

# Adicionar rótulos às colunas
colnames(matriz_medias_cartao_de_credito_pf) <- c("A vencer 90", "A vencer 91 ate 360", "A vencer 361 ate 1080",
                                                  "A vencer 1081 ate 1800", "A Vencer 1801 ate 5400", "A vencer acima 5400",
                                                  "Vencido acima 15", "Carteira Ativa", "Inadimplida arrastada", "Ativo problematico")

# Loop for com interações por modalidade Cartão de Crédito - PF #BancoGeral[j]
for (j in 1:length(BancoGeral)) {
  End <- paste0("planilha_", BancoGeral[j], ".csv")
  planilha <- read_delim(End, delim = ";", escape_double = FALSE, trim_ws = TRUE, show_col_types = FALSE)
  
  # Filtrar as linhas com modalidade igual a "PF - Cartão de Crédito"
  Names <- unique(planilha$modalidade)
  planilha_filtrada <-  filter(planilha, planilha$modalidade == Names[1])
  
  # Convertendo , em .
  planilha_filtrada <- planilha_filtrada %>% 
    mutate_at(vars(14:23), ~ gsub(",", ".", .))
  
  # Convertendo para numérico as colunas a vencer/vencidos e outras relevantes
  filtro <- apply(planilha_filtrada[,14:23], 2, as.numeric)
  
  # Teste calculo mean
  Mean_filtro <- apply(filtro, 2, mean)
  
  # Armazenar na matriz_medias_cartao_de_credito as médias do filtro
  matriz_medias_cartao_de_credito_pf[j,] <- Mean_filtro
}

# Análise de série temporal e estatística descritiva básica - Cartão de Crédito PF

# Criar objeto ts
matriz_medias_cartao_de_credito_pf_ts <- ts(matriz_medias_cartao_de_credito_pf, start = c(2019, 1), frequency = 12)

# Definir rótulos das linhas
dimnames(matriz_medias_cartao_de_credito_pf_ts)[[1]] <- BancoGeral

# Autoplot
autoplot(matriz_medias_cartao_de_credito_pf_ts)

# Estatística descritiva básica
stat.desc(matriz_medias_cartao_de_credito_pf_ts)

# Teste de Kruskall Wallis, Análise da Carteira Ativa entre 3 períodos

# Convertendo para data frame
data_frame_cartao_de_credito_pf <- as.data.frame(matriz_medias_cartao_de_credito_pf)

# Adicionar coluna de período ao data frame
data_frame_cartao_de_credito_pf <- data_frame_cartao_de_credito_pf %>%
  mutate(Periodo = rep(c("Periodo1", "Periodo2", "Periodo3"), each = 16))

# Realizar o teste de Kruskal-Wallis por períodos
kruskal_test_cartao_de_credito_pf <- kruskal.test(data_frame_cartao_de_credito_pf$`Carteira Ativa` ~ data_frame_uf_operacoes$Periodo)

# Imprimir os resultados
print(kruskal_test_cartao_de_credito_pf)

# Teste de dunn para comparações múltiplas de operações de cartão de crédito pf com cada um dos 3 períodos
dunn_test_cartao_de_credito_pf <- dunn.test(data_frame_cartao_de_credito_pf$`Carteira Ativa`, data_frame_cartao_de_credito_pf$Periodo, method = "holm")

# Média dos períodos - operações de cartão de crédito pf
aggregate(data_frame_cartao_de_credito_pf$`Carteira Ativa` ~ data_frame_cartao_de_credito_pf$Periodo, data = data_frame_cartao_de_credito_pf, mean)

# Desvio padrão dos períodos - operações de cartão de crédito pf
aggregate(data_frame_cartao_de_credito_pf$`Carteira Ativa` ~ data_frame_cartao_de_credito_pf$Periodo, data = data_frame_cartao_de_credito_pf, sd)