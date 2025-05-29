rm(list = ls())
library(foreign)
library(data.table)

# Project home directory, passed from the command line
(args <- commandArgs(trailingOnly = TRUE))
if(length(args)) {
  project_folder <- c(args[1])  # working directory
}
setwd(project_folder)

set.seed(301)

f.quant = function(p1, p2){
  alpha = 2
  beta = -1
  tau = 1

  c1 = 1/2 + 1/2*beta/tau*(p1-p2)
  d1 = alpha/tau + beta/tau*p1
  share1 = punif(min(c1,d1))

  c2 = 1/2 + 1/2*beta/tau*(p1-p2)
  d2 = 1 - alpha/tau - beta/tau*p2
  share2 = 1 - punif(max(c2,d2))

  mass = 2
  return(c(share1*mass, share2*mass))
}

f.price = function(params, p.max){

  a1 = params[1]
  a2 = params[2]
  b1 = params[3]
  b2 = params[4]
  
  # Note: only works if prices are above zero and below max
  p1 = (a1 + b1*a2)/(1-b1*b2)
  p2 = (a2 + b2*a1)/(1-b1*b2)
  
  dev1 = round(p1 - p.max, digits = 6)
  dev2 = round(p2 - p.max, digits = 6)
  
  if(is.na(p1) | is.na(p2)){
    print(c(p1,p2))
    print(c(a1,a2,b1,b2))
  }
  
  if(!(p1 >= 0 & dev1 <= 0 & p2 >= 0 & dev2 <= 0)){
    print(c(p1,p2, dev1, dev2))
    stopifnot(FALSE)
  }
  
  return(c(p1,p2))
}

f.simulate = function(init, delta, pr_both, p.max, n.periods){
  intercept = 0.000001
  
  m.a = matrix(NA, n.periods, 2)
  m.b = matrix(NA, n.periods, 2)
  m.price = matrix(NA, n.periods, 2)
  m.quant = matrix(NA, n.periods, 2)
  m.profit = matrix(NA, n.periods, 2)
  m.coin = matrix(NA, n.periods, 2)
  
  # Starting value
  t = 1
  
  
  m.a[t,] = c(init[1],init[2])
  m.b[t,] = c(init[3],init[4])
  
  m.a[t,1] = max(m.a[t,1], 0 + intercept)
  m.a[t,1] = min(m.a[t,1], p.max)
  m.b[t,1] = max(m.b[t,1], 0)
  m.b[t,1] = min(m.b[t,1], 1 - m.a[t,1]/p.max)
  m.b[t,1] = 0 # Asymmetric case
  m.a[t,1] = m.a[t,1]*2
  
  m.a[t,2] = max(m.a[t,2], 0 + intercept)
  m.a[t,2] = min(m.a[t,2], p.max)
  m.b[t,2] = max(m.b[t,2], 0)
  m.b[t,2] = min(m.b[t,2], 1 - m.a[t,2]/p.max)
  
  m.price[t,] = f.price(c(m.a[t,],m.b[t,]), p.max)
  m.quant[t,] = f.quant(m.price[t,1], m.price[t,2])
  m.profit[t,] = m.price[t,]*m.quant[t,]
  
  # Reselect if zero profit equlibrium
  while(m.profit[t,1] <= 0 & m.profit[t,2] <= 0){
    init = runif(4)
    m.a[t,] = c(init[1],init[2])
    m.b[t,] = c(init[3],init[4])
    
    m.a[t,1] = max(m.a[t,1], 0 + intercept)
    m.a[t,1] = min(m.a[t,1], p.max)
    m.b[t,1] = max(m.b[t,1], 0)
    m.b[t,1] = min(m.b[t,1], 1 - m.a[t,1]/p.max)
    
    m.a[t,2] = max(m.a[t,2], 0 + intercept)
    m.a[t,2] = min(m.a[t,2], p.max)
    m.b[t,2] = max(m.b[t,2], 0)
    m.b[t,2] = min(m.b[t,2], 1 - m.a[t,2]/p.max)
    
    m.price[t,] = f.price(c(m.a[t,],m.b[t,]), p.max)
    m.quant[t,] = f.quant(m.price[t,1], m.price[t,2])
    m.profit[t,] = m.price[t,]*m.quant[t,]
    
  }
  
  # Placeholder for next period
  m.a[t+1,] =  m.a[t,]
  m.b[t+1,] =  m.b[t,]
  
  for(t in 2:n.periods){
    # Flip some coins
    coin0 = (t + 1) %% 2
    
    r_state = runif(1)
    coin1 = r_state < (.5 + pr_both/2)
    coin2 = r_state > (.5 - pr_both/2)
    m.coin[t,] = c(coin1, coin2)
   
    # Update algorithms
    if(coin0){
      m.a[t,1] = m.a[t,1] + coin1*(runif(1) - .5)*delta
      m.b[t,1] = m.b[t,1] + coin1*(runif(1) - .5)*delta
      m.a[t,1] = max(m.a[t,1], 0 + intercept)
      m.a[t,1] = min(m.a[t,1], p.max)
      m.b[t,1] = max(m.b[t,1], 0)
      m.b[t,1] = min(m.b[t,1], 1 - m.a[t,1]/p.max)
      m.b[t,1] = 0 # Asymmetric case

      m.a[t,2] = m.a[t,2] + coin2*(runif(1) - .5)*delta
      m.b[t,2] = m.b[t,2] + coin2*(runif(1) - .5)*delta
      m.a[t,2] = max(m.a[t,2], 0 + intercept)
      m.a[t,2] = min(m.a[t,2], p.max)
      m.b[t,2] = max(m.b[t,2], 0)
      m.b[t,2] = min(m.b[t,2], 1 - m.a[t,2]/p.max)
      
    }
    
    m.price[t,] = f.price(c(m.a[t,],m.b[t,]), p.max)
    m.quant[t,] = f.quant(m.price[t,1], m.price[t,2])
    m.profit[t,] = m.price[t,]*m.quant[t,]
    
    if(t < n.periods){
  
      # Only update during experiments
      if(coin0*coin1){  
        if(m.profit[t,1] > m.profit[t-1,1]){
          m.a[t+1,1] =  m.a[t,1]
          m.b[t+1,1] =  m.b[t,1]
        } else {
          m.a[t+1,1] =  m.a[t-1,1]
          m.b[t+1,1] =  m.b[t-1,1]
        }
      } else {
        m.a[t+1,1] =  m.a[t,1]
        m.b[t+1,1] =  m.b[t,1]
      }
      
      # Firm 2 experiments
      if(coin2*coin0){
        if(m.profit[t,2] > m.profit[t-1,2]){
          m.a[t+1,2] =  m.a[t,2]
          m.b[t+1,2] =  m.b[t,2]
        } else {
          m.a[t+1,2] =  m.a[t-1,2]
          m.b[t+1,2] =  m.b[t-1,2]
        }
      } else {
        m.a[t+1,2] =  m.a[t,2]
        m.b[t+1,2] =  m.b[t,2]
      }

    }
    
  }
  
  return(list(m.a, m.b, m.price, m.quant, m.profit, m.coin))
}

n.periods = 20001
delta = .4
pr_both = 0
p.max = 50
n.sims = 500
pb = txtProgressBar(min = 0, max = n.sims, initial = 0, style = 3) 
m.price_final = matrix(NA, n.sims, 2)
m.a_final = matrix(NA, n.sims, 2)
m.b_final = matrix(NA, n.sims, 2)
m.profits_final = matrix(NA, n.sims, 2)
m.sd_final = matrix(NA, n.sims, 2)
for(i in 1:n.sims){
  init = runif(4)

  result = f.simulate(init, delta, pr_both, p.max, n.periods)

  m.a_final[i,] = result[[1]][n.periods,]
  m.b_final[i,] = result[[2]][n.periods,]
  m.price_temp = result[[3]]
  m.price_final[i,] = m.price_temp[n.periods,]
  m.profits_final[i,] = result[[5]][n.periods,]
  
  selector= 1:n.periods %% 2 == 1
  at_end = (1:n.periods) > n.periods - 100
  m.sd_final[i,] = apply(X = m.price_temp[selector & at_end,], MARGIN = 2, FUN = sd)
  
  setTxtProgressBar(pb,i)
  
}

results = cbind(m.price_final, m.a_final, m.b_final, m.profits_final, m.sd_final)
results = data.frame(results)

colnames(results) = c("price1",
                      "price2", 
                      "a1",
                      "a2",
                      "b1",
                      "b2",
                      "pi1",
                      "pi2",
                      "stable1",
                      "stable2")
write.dta(results, file = "analysis/results/learning_asymmetric.dta" )
