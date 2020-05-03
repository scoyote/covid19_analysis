 library(plyr)
library(tidyr)
animals <- read.csv(file='https://raw.githubusercontent.com/hzlzh/Domain-Name-List/master/Animal-words.txt',stringsAsFactors = F)[,1]
adjectives <- read.csv(file='/Users/samuelcroker/OneDrive/ed_adjectives.txt',stringsAsFactors = F)[,1]

keyscore <- read.csv(file='/Users/samuelcroker/OneDrive/keyboardscore.csv')
sample(adjectives,1)

sample(animals,1)

keyScores <- function(a){
  y <- vector()
  txt <- strsplit(gsub(" ","",tolower(a),fixed=T),"")
  for(t in txt) y <- c(y,t)
  score = sum(as.numeric(mapvalues(y, from = keyscore[,1], to = keyscore[,2], warn_missing = F)))
  return(c(a,score))
}

animaldf <- data.frame(matrix(, nrow=length(animals), ncol=2))
i=0
for(animal in animals){
  i= i + 1
  animaldf[i,] <- keyScores(animal)
}


adjectivedf <- data.frame(matrix(, nrow=length(adjectives), ncol=2))
i=0
for(adjective in adjectives){
  i= i + 1
  adjectivedf[i,] <- keyScores(adjective)
}



aniz <- animaldf[animaldf$X2==0,1]
adjz <- adjectivedf[adjectivedf$X2==0,1]

full <- expand.grid(factor(adjz),factor(aniz))

full[sample(nrow(full),15),]