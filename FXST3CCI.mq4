//+------------------------------------------------------------------+
//|                                                     FXST3CCI.mq4 |
//|                        Copyright 2022, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int magic = 991112;
extern string Fx_Sniper_CCI_T3_New = "Fx_Sniper_CCI_T3_New";
ENUM_TIMEFRAMES timeframe = PERIOD_CURRENT;
int slippage = 1;
datetime tradeTime;
extern double lots = 0.04;
extern double dailyDrawdown = 0.03;
extern double limitMaxDrawdown = 8800;
string globalRandom = "_j7a2zwqfp4_FXST3CCI";
int SLpoints = 0;
int TPpoints = 0;
int TPprice = 9999999;
extern int maxTotalOrder = 30;
extern double maxLoss = 0.011;
extern int totalXLot = 5;
extern double xLot = 2.1;
extern int totalXLot1 = 6;
extern double xLot1 = 2.1;
//extern int maxLossPoints = 2900;
extern int consecutiveWins = 2;
int forceStopTradeType = -1;
extern double closeProfit = 10;
extern int trailingPoints = 20;
extern int bigWave = 130;

string tmpDes = ""; //------Setup Fx_Sniper_CCI_T3_New------- 13,13,0.3,3,100
int v1 = 13;//------Setup Fx_Sniper_CCI_T3_New------- 13,13,0.3,3,100
int v2 = 13;//------Setup Fx_Sniper_CCI_T3_New------- 13,13,0.3,3,100
double v3 = 0.3;//------Setup Fx_Sniper_CCI_T3_New------- 13,13,0.3,3,100
int v4 = 3;//------Setup Fx_Sniper_CCI_T3_New------- 13,13,0.3,3,100
int v5 = 100;//------Setup Fx_Sniper_CCI_T3_New------- 13,13,0.3,3,100
//==========
int a1 = 0;
int a2 = 0;
int a3 = 0;
int a4 = 0;
int a5 = 0;
int a6 = 0;
int a7 = 0;
int a8 = 0;
int a9 = 0;
int a10 = 0;
int a11 = 0;
int a12 = 0;
int a13 = 0;
int a14 = 0;
int a15 = 0;
int a16 = 0;
int a17 = 0;
int a18 = 0;
int a19 = 0;
int a20 = 0;
int a21 = 0;
int a22 = 0;
int a23 = 0;
int a24 = 0;
int a25 = 0;
int arrCountForceCloseAll[];

int OnInit()
  {
//---
     if (IsTesting()) {
         
         ArrayFree(arrCountForceCloseAll);
         
         ArrayResize(arrCountForceCloseAll, 0,0);
         Alert(ArraySize(arrCountForceCloseAll));
         
         resetGlobal();
     }
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
      
      Alert("1: " + a1);
      Alert("2: " + a2);
      Alert("3: " + a3);
      Alert("4: " + a4);
      Alert("5: " + a5);
      Alert("6: " + a6);
      Alert("7: " + a7);
      Alert("8: " + a8);
      Alert("9: " + a9);
      Alert("10: " + a10);
      Alert("11: " + a11);
      Alert("12: " + a12);
      Alert("13: " + a13);
      Alert("14: " + a14);
      Alert("15: " + a15);
      Alert("16: " + a16);
      Alert("17: " + a17);
      Alert("18: " + a18);
      Alert("19: " + a19);
      Alert("20: " + a20);
      Alert("21: " + a11);
      Alert("22: " + a12);
      Alert("23: " + a13);
      Alert("24: " + a14);
      Alert("25: " + a25);
      Alert("=======");
      Alert("arrCountForceCloseAll: " + ArraySize(arrCountForceCloseAll));
      
      showForceClose();
      
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {      
      string sym = Symbol();
      forceCloseAll(sym);
      checkCloseProfit(sym);
      drawButton(sym);
      calculateDrawdown();
      if(tradeTime == iTime(sym, timeframe, 0)) {
         return;      
      }
      tradeTime = iTime(sym, 0, 0);
      checkRun(sym);
   
  }
//+------------------------------------------------------------------+

void checkRun(string sym)
{
   int tradeType = -1;
   int closeType = -1;
   int lastTradeType = -1;
   
   tradeType = checkFx_Sniper_CCI_T3_New(sym);
   lastTradeType = getLastTradeType(sym);   
   
   if (tradeType == OP_BUY) {
      closeType = OP_SELL;
   } else if (tradeType == OP_SELL) {
      closeType = OP_BUY;
   }   
   
   if (AccountProfit() > 0 && closeProfit == 0) {
      closeTradingByTradeType(sym, closeType);      
   }
   
   if (tradeType == -1 || (lastTradeType != -1 && lastTradeType != tradeType)) {
      return;
   }
   
   if (forceStopTradeType != tradeType) {
      forceStopTradeType = -1;
   }
   /*
   if (OrdersTotal() == 0 && (checkConsecutiveTradeType(sym) || forceStopTradeType == tradeType)) {
         forceStopTradeType = tradeType;
         if (AccountProfit() >= 0) {
            closeAll(sym);
         }         
         return;
   }
   */
   
   if ((checkBigWave(sym) || forceStopTradeType == tradeType)) {
         forceStopTradeType = tradeType;
         closeAll(sym);        
         return;
   }
   
   
   
   
   runTrading(sym, tradeType);
}


int checkFx_Sniper_CCI_T3_New(string sym)
{
   int tradeType = -1;
   double up = iCustom(sym, timeframe, Fx_Sniper_CCI_T3_New, v1,v2,v3,v4,v5, 4, 0);
   double up1 = iCustom(sym, timeframe, Fx_Sniper_CCI_T3_New, v1,v2,v3,v4,v5, 9, 1);
   
   double down = iCustom(sym, timeframe, Fx_Sniper_CCI_T3_New, v1,v2,v3,v4,v5, 3, 0);
   double down1 = iCustom(sym, timeframe, Fx_Sniper_CCI_T3_New, v1,v2,v3,v4,v5, 10, 1);
   
   //Alert("up: " + up + " up1: " + up1 + " | down: " + down + " down1: " + down1);
   
   if ((down > 0 && down < 500) || (down1 > 0 && down1 < 500)) {
      tradeType = OP_SELL;
   } else if ((up < 0 && up > -500) || (up1 < 0 && up1 > -500)) {
      tradeType= OP_BUY;
   }
   
   return tradeType;
}

void runTrading(string sym, int tradeType, double lot = 0) 
{
   if (Hour() <= 1 || Hour() >= 23 || getAllowTrade() == 1) {
         return;
   }
      
   double entry = 0;
   color tradeColor = clrBlue;
   double SL = 0;
   double TP = 0;
   
   if(tradeType == OP_BUY) {
      entry = MarketInfo(sym, MODE_ASK);
      tradeColor = clrBlue;
   } else if(tradeType == OP_SELL) {
      entry = MarketInfo(sym, MODE_BID);
      tradeColor = clrRed;
   } else {
      return;
   }   
   /*
   SL = getSLByPips(sym, tradeType, entry);
   if(!SL) {
      return;
   }
   TP = getTP(entry, SL);
   
   SL = NormalizeDouble(SL, MarketInfo(sym, MODE_DIGITS));
   TP = NormalizeDouble(TP, MarketInfo(sym, MODE_DIGITS));
   double SLPoints = MathAbs(NormalizeDouble(entry - SL, MarketInfo(sym, MODE_DIGITS)) / MarketInfo(sym, MODE_POINT));
   */
   if (SLpoints != 0 ) {
      SL = getSLByPips(sym, tradeType, entry);
      SL = NormalizeDouble(SL, MarketInfo(sym, MODE_DIGITS));
   }
   
   if (TPpoints != 0 ) {
      TP = getTPByPips(sym, tradeType, entry);    
      TP = NormalizeDouble(TP, MarketInfo(sym, MODE_DIGITS));
   }   
   
   entry = NormalizeDouble(entry, MarketInfo(sym, MODE_DIGITS));
   /*
   if (OrdersTotal() >= 5) {
      if (checkEntry(sym, entry, tradeType)) {
         return;
      }
   } 
   */  
   
   if(lot == 0) {
      lot = getLot(sym);
   }
   
   if(entry && lot > 0) {
      string commentOrder = ""; //Alert("getCountConsecutiveWins:" + getCountConsecutiveWins());
      if (getCountConsecutiveWins() == consecutiveWins) {
         lot = lot * 2.1;
         setCountConsecutiveWins();
      }
      OrderSend(sym, tradeType, lot, entry, slippage, SL, TP, commentOrder, magic, 0, tradeColor);      
   }
}

double getLot(string sym)
{
   double tmpLots = lots;
   switch(OrdersTotal()) 
   { 
   case 2: 
      tmpLots = 0.02;
      break; 
   case 3: 
      tmpLots = 0.03;
      break; 
   case 4: 
      tmpLots = 0.04;
      break; 
   case 5: 
      tmpLots = 0.07;
      break;
   case 6: 
      tmpLots = 0.10;
      break;   
   case 7: 
      tmpLots = 0.17;
      break;   
   case 8: 
      tmpLots = 0.27;
      break;   
   case 9: 
      tmpLots = 0.43;
      break;
   case 10: 
      tmpLots = 0.69;
      break; 
   case 11: 
      tmpLots = 1.10;
      break;  
   case 12: 
      tmpLots = 1.76;
      break; 
   case 13: 
      tmpLots = 2.81;
      break;
   case 14: 
      tmpLots = 4.56;
      break;
   case 15: 
      tmpLots = 7.37;
      break;         
  }
  
  tmpLots = lots;
  
  double lastLots = getLastLots(sym);
  
  if (lastLots) {
      tmpLots = lastLots;
  }
  
  if (OrdersTotal() > totalXLot) {
      tmpLots = tmpLots * xLot;
  }

  if (OrdersTotal() > totalXLot1) {
      tmpLots = tmpLots * xLot1;
  }

  return tmpLots;
      
}

void closeTradingByTradeType(string sym, int tradeType)
{
   double closePrice; 
   double bidPrice;
   double askPrice;
   bool checkTrue = false;
   int ordersTotal = OrdersTotal();
   
   for(int i = OrdersTotal() - 1; i >= 0; i--) {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES) && tradeType == OrderType()) {                     
         
         while(true) {
            bidPrice = MarketInfo(sym, MODE_BID);
            askPrice = MarketInfo(sym, MODE_ASK);
         
            if(OrderType() == OP_BUY) {
               closePrice = bidPrice;
            } else if(OrderType() == OP_SELL) {
               closePrice = askPrice;
            }   
         
            bool checkClose = OrderClose(OrderTicket() , OrderLots(), closePrice, slippage);
            if(checkClose) {
               checkTrue = true;
               break;
            }
            //Alert("Error: " + GetLastError() + " | slippage: " + slippage);   
                    
         }        
      }
   }
   
   if (checkTrue) {
      setCountConsecutiveWins(getCountConsecutiveWins() + 1);
      saveRP(ordersTotal);      
   }
}

void drawButton(string sym)
{
   long currentChartId = ChartID();  
   
   double spread = MarketInfo(sym, MODE_SPREAD);
   
   ObjectCreate(currentChartId, "showSpread", OBJ_LABEL, 0, 0 ,0);   
   ObjectSet("showSpread", OBJPROP_CORNER, CORNER_RIGHT_UPPER);
   ObjectSet("showSpread", OBJPROP_XDISTANCE, 50);
   ObjectSet("showSpread", OBJPROP_YDISTANCE, 160);
   ObjectSetText("showSpread", "Spread: " + spread + " Next bar in: " + getNextBar(), 15, "Impact", Red);
   
   ObjectCreate(currentChartId, "accountProfit", OBJ_LABEL, 0, 0 ,0);   
   ObjectSet("accountProfit", OBJPROP_CORNER, CORNER_RIGHT_UPPER);
   ObjectSet("accountProfit", OBJPROP_XDISTANCE, 50);
   ObjectSet("accountProfit", OBJPROP_YDISTANCE, 200);
   ObjectSetText("accountProfit", "Account Profit: " + AccountProfit() + "(" + OrdersTotal() + ")" , 15, "Impact", Red);
   
   ObjectCreate(currentChartId, "AccountBalance", OBJ_LABEL, 0, 0 ,0);   
   ObjectSet("AccountBalance", OBJPROP_CORNER, CORNER_RIGHT_UPPER);
   ObjectSet("AccountBalance", OBJPROP_XDISTANCE, 50);
   ObjectSet("AccountBalance", OBJPROP_YDISTANCE, 240);
   ObjectSetText("AccountBalance", "AccountBalance: " + AccountBalance() + " | AccountEquity: " + AccountEquity() , 15, "Impact", Red);
}

string getNextBar()
{
   string nextBar;
   int s = getSecondsLeft();
      
   int d = 86400;
   int h = 3600;
   int m = 60;
   int nextD;
   int nextH;
   int nextM;
   
   if(s >= d) {
      nextD = s/d;
      s = s - d * nextD;
   }
   if(s >= h) {
      nextH = s/h;
      s = s - h * nextH;
   }
   if(s >= m) {
      nextM = s/m;
      s = s - m * nextM;
   }  
   
   if(nextD > 0) {
      nextBar += nextD + "d ";
   }
   if(nextH > 0) {
      nextBar += nextH + "h ";
   }
   if(nextM > 0) {
      nextBar += nextM + "m ";
   }
   
   nextBar += s + "s"; 
   
   return nextBar;
}

int getSecondsLeft()
{
   return Time[0] + PeriodSeconds() - TimeCurrent();
}

int getLastTradeType(string sym)
{
   int tradeType = -1;
   
   if (OrderSelect(0, SELECT_BY_POS, MODE_TRADES)) {
      tradeType = OrderType();
   }
   
   return tradeType;
}

int getLastLots(string sym)
{
   int tmpLots = 0;
   
   if (OrderSelect(0, SELECT_BY_POS, MODE_TRADES)) {
      tmpLots = OrderLots();
   }
   
   return tmpLots;
}

int getLastEntry(string sym)
{
   int tmpEntry = 0;
   
   if (OrderSelect(0, SELECT_BY_POS, MODE_TRADES)) {
      tmpEntry = OrderOpenPrice();
   }
   
   return tmpEntry;
}

void calculateDrawdown()
{
   //Alert(getLimitDayDrawdown());
   if (Hour() == 00 || getLimitDayDrawdown() == 0) {
      resetGlobal();
      double account = 0;
      if (AccountBalance() > AccountEquity()) {
         account = AccountBalance();
      } else {
         account = AccountEquity();
      }
      setLimitDayDrawdown(account - (account * dailyDrawdown));
   }
   
   if (AccountEquity() < getLimitDayDrawdown()) {
      setCheckDayDrawdown(AccountProfit());
      ObjectCreate(0, "limitMaxDrawdown", OBJ_LABEL, 0, 0 ,0);   
      ObjectSet("limitMaxDrawdown", OBJPROP_CORNER, CORNER_RIGHT_UPPER);
      ObjectSet("limitMaxDrawdown", OBJPROP_XDISTANCE, 50);
      ObjectSet("limitMaxDrawdown", OBJPROP_YDISTANCE, 280);
      ObjectSetText("limitMaxDrawdown", "AccountProfit: " + AccountProfit() + " | getLimitDayDrawdown: " + getLimitDayDrawdown() , 15, "Impact", Red);
   }
   
   if (AccountEquity() < limitMaxDrawdown) {
      setCheckMaxDrawdown(AccountEquity());
      ObjectCreate(0, "limitMaxDrawdown", OBJ_LABEL, 0, 0 ,0);   
      ObjectSet("limitMaxDrawdown", OBJPROP_CORNER, CORNER_RIGHT_UPPER);
      ObjectSet("limitMaxDrawdown", OBJPROP_XDISTANCE, 50);
      ObjectSet("limitMaxDrawdown", OBJPROP_YDISTANCE, 320);
      ObjectSetText("limitMaxDrawdown", "AccountEquity: " + getCheckMaxDrawdown() , 15, "Impact", Red);
   }
}

double getCheckDayDrawdown()
{
   return GlobalVariableGet("CheckDayDrawdown" + globalRandom);
}

void setCheckDayDrawdown(double value = 0)
{
   GlobalVariableSet("CheckDayDrawdown" + globalRandom, value);
}

double getCheckMaxDrawdown()
{
   return GlobalVariableGet("CheckMaxDrawdown" + globalRandom);
}

void setCheckMaxDrawdown(double value = 0)
{
   GlobalVariableSet("CheckMaxDrawdown" + globalRandom, value);
}

double getLimitDayDrawdown()
{
   return GlobalVariableGet("LimitDayDrawdown" + globalRandom);
}

void setLimitDayDrawdown(double value = 0)
{
   GlobalVariableSet("LimitDayDrawdown" + globalRandom, value);
}

int getAllowTrade()
{
   return GlobalVariableGet("AllowTrade" + globalRandom);
}

void setAllowTrade(int value = 0)
{
   GlobalVariableSet("AllowTrade" + globalRandom, value);
}

int getCountConsecutiveWins()
{
   return GlobalVariableGet("CountConsecutiveWins" + globalRandom);
}

void setCountConsecutiveWins(int value = 0)
{
   GlobalVariableSet("CountConsecutiveWins" + globalRandom, value);
}

void resetGlobal()
{
   setCheckDayDrawdown();  
   setCheckMaxDrawdown(); 
   setLimitDayDrawdown();
   setAllowTrade();
   setCountConsecutiveWins();
}

void closeAll(string sym)
{
   double closePrice;
   double bidPrice = MarketInfo(sym, MODE_BID);
   double askPrice = MarketInfo(sym, MODE_ASK);
   int orderTotal = OrdersTotal();
   /*
   while(true) {
       if(OrderSelect(0, SELECT_BY_POS, MODE_TRADES)) {
            if(OrderType() == OP_BUY) {
               closePrice = bidPrice;
            } else if(OrderType() == OP_SELL) {
               closePrice = askPrice;
            } else {
               OrderDelete(OrderTicket());
            }
            
           OrderClose(OrderTicket(), OrderLots(), closePrice, slippage);
       } else {
         break;
       }
   }
   */
   for(int i = OrdersTotal() - 1; i >= 0; i--) {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {                     
         
         while(true) {
            bidPrice = MarketInfo(sym, MODE_BID);
            askPrice = MarketInfo(sym, MODE_ASK);
         
            if(OrderType() == OP_BUY) {
               closePrice = bidPrice;
            } else if(OrderType() == OP_SELL) {
               closePrice = askPrice;
            }   
         
            bool checkClose = OrderClose(OrderTicket() , OrderLots(), closePrice, slippage);
            if(checkClose) {
               break;
            }
            //Alert("Error: " + GetLastError() + " | slippage: " + slippage);            
         }        
      }
   }
}

void forceCloseAll(string sym, int force = false)
{  
   /*
   if(OrderSelect(0, SELECT_BY_POS, MODE_TRADES)) {
      double checkDistanceEntry = MathAbs(OrderOpenPrice() - MarketInfo(sym, MODE_ASK)) / MarketInfo(sym, MODE_POINT);      
      if (checkDistanceEntry > maxLossPoints) {
         closeAll(sym);
         setAllowTrade(1);
      }
   }
   */
   
   int orderTotal = OrdersTotal();
   double accountProfit = AccountProfit();
   if (OrdersTotal() >= maxTotalOrder && AccountEquity() <= (AccountBalance() - (AccountBalance() * maxLoss))
      //|| Hour() >= 21 && Hour() <= 24 && AccountProfit() >= 0
      || (Hour() >= 22 && Hour() <= 24 && AccountEquity() <= (AccountBalance() - (AccountBalance() * maxLoss)))
      || OrdersTotal() > 5 && AccountProfit() >= 0
      || OrdersTotal() > 5 //&& AccountProfit() >= 0
      || AccountEquity() <= getLimitDayDrawdown()
      //|| Hour() >= 23 && Hour() <= 24
      //|| AccountProfit() >= (AccountBalance() * TP)
      //|| AccountEquity() <= (AccountBalance() - (AccountBalance() * dailyDrawdown))
      || force == true
   ) {
      closeAll(sym);
      setAllowTrade(1);
      
      if (accountProfit < 0) {
         arrayPush(arrCountForceCloseAll, orderTotal);
      }      
   }   
}

double getSLByPips(string sym, int tradeType, double entry)
{
   double tmpSL = 0;   
   if(tradeType == OP_BUY) {      
     tmpSL = entry - SLpoints * MarketInfo(sym, MODE_POINT);
   } else if(tradeType == OP_SELL) { 
     tmpSL = entry + SLpoints * MarketInfo(sym, MODE_POINT);
   }
   
   return (tmpSL);
}

double getTPByPips(string sym, int tradeType, double entry)
{
   double tmpTP = 0;   
   if(tradeType == OP_BUY) {      
     tmpTP = entry + TPpoints * MarketInfo(sym, MODE_POINT);
   } else if(tradeType == OP_SELL) { 
     tmpTP = entry - TPpoints * MarketInfo(sym, MODE_POINT);
   }
   
   return (tmpTP);
}

void saveRP(int ordersTotal)
{
   if (ordersTotal == 1) {
      a1 = a1 + 1;
   }if (ordersTotal == 2) {
      a2 = a2 + 1;
   }if (ordersTotal == 3) {  
    a3 = a3 + 1;
   }if (ordersTotal == 4) {
     a4 = a4 + 1;
   }if (ordersTotal == 5) {
      a5 = a5 + 1;
   }if (ordersTotal == 6) {
      a6 = a6 + 1;
   }if (ordersTotal == 7) {
      a7 = a7 + 1;
   }if (ordersTotal == 8) {
     a8 = a8 + 1;
   }if (ordersTotal == 9) {
     a9 = a9 + 1;
   }if (ordersTotal == 10) {
     a10 = a10 + 1;
   }if (ordersTotal == 11) {
      a11 = a11 + 1;
   }if (ordersTotal == 12) {
     a12 = a12 + 1;
   }if (ordersTotal == 13) {
      a13 = a13 + 1;
   }if (ordersTotal == 14) {
      a14 = a14 + 1;
   }if (ordersTotal == 15) {
      a15 = a15 + 1;
   }if (ordersTotal == 16) {
      a16 = a16 + 1;
   }if (ordersTotal == 17) {
     a17 = a17 + 1;
   }if (ordersTotal == 18) {
      a18 = a18 + 1;
   }if (ordersTotal == 19) {
      a19 = a19 + 1;
   }if (ordersTotal == 20) {
      a20 = a20 + 1;
   }
}

void arrayPush(int & array[] , double dataToPush){
    int count = ArrayResize(array, ArraySize(array) + 1);
    array[ArraySize(array) - 1] = dataToPush;
}

void showForceClose()
{
   ArraySort(arrCountForceCloseAll);
   int tmpC = 1;
   for(int i = 1; i <= ArraySize(arrCountForceCloseAll) - 1; i++) {
      
      if (arrCountForceCloseAll[i] == arrCountForceCloseAll[i - 1]) {
         tmpC = tmpC + 1;
      }  
      if (arrCountForceCloseAll[i] != arrCountForceCloseAll[i - 1]) {
         Alert(arrCountForceCloseAll[i] + "=>" + tmpC);
         tmpC = 1;
      } 
   }
}

bool checkConsecutiveTradeType(string sym)
{
   bool result = false;   
   double up = -1;
   double up1 = -1;
   double down = -1;
   double down1 = -1;
   int countUp = 0;
   int countDown = 0;
   
   int i = 0;
   while (true) {
      up = iCustom(sym, timeframe, Fx_Sniper_CCI_T3_New, v1,v2,v3,v4,v5, 4, i);
      up1 = iCustom(sym, timeframe, Fx_Sniper_CCI_T3_New, v1,v2,v3,v4,v5, 9, i);
   
      down = iCustom(sym, timeframe, Fx_Sniper_CCI_T3_New, v1,v2,v3,v4,v5, 3, i);
      down1 = iCustom(sym, timeframe, Fx_Sniper_CCI_T3_New, v1,v2,v3,v4,v5, 10, i);
   
      if ((down > 0 && down < 500) || (down1 > 0 && down1 < 500)) {
         countDown = countDown + 1;
      } else if ((up < 0 && up > -500) || (up1 < 0 && up1 > -500)) {
         countUp = countUp + 1;
      }
      
      if (countUp >= 1 && countDown >= 1) {
         break;
      }
      
      if ((countUp == 4 && countDown == 0)
         || (countUp == 0 && countDown == 4)
      ) {
         result = true;
         break;
      }
      
      i = i + 1;
   }   
   
   return result;
}

bool checkBigWave(string sym)
{
   double check = iCustom(sym, timeframe, Fx_Sniper_CCI_T3_New, v1,v2,v3,v4,v5, 0, 1);
   
   if (check >= bigWave || check <= (bigWave * -1)) {
      return true;
   }
   
   return false;
}

void checkCloseProfit(string sym)
{
   int ordersTotal = OrdersTotal();
   if (AccountProfit() >= closeProfit) {
      //closeAll(sym);
      trailingStop(trailingPoints);
      //setCountConsecutiveWins(getCountConsecutiveWins() + 1);
      //saveRP(ordersTotal);   
   }
}

void trailingStop(int TrailingOffsetPoints) 
{
	for (int i = OrdersTotal() - 1; i >= 0; i--) {
		if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
		   double orderStopLoss = OrderStopLoss();
		   if (orderStopLoss == 0 && (OrderType() == OP_BUY)) {
		      orderStopLoss = -1;
		   } else if (orderStopLoss == 0 && (OrderType() == OP_SELL)) {
		      orderStopLoss = 9999;
		   }
			if ((OrderType() == OP_BUY) && (NormPrice(Bid - orderStopLoss) > NormPrice(TrailingOffsetPoints * Point))) {
			   Alert(NormPrice(Bid - TrailingOffsetPoints * Point) +"-"+ orderStopLoss);
			   if (NormPrice(Bid - TrailingOffsetPoints * Point) <= orderStopLoss) {
			      return;
			   }
				OrderModify(OrderTicket(), OrderOpenPrice(), NormPrice(Bid - TrailingOffsetPoints * Point), OrderTakeProfit(), OrderExpiration(), clrNONE);

			} else if ((OrderType() == OP_SELL) && (NormPrice(orderStopLoss - Ask) > NormPrice(TrailingOffsetPoints * Point))) {
            if (NormPrice(Ask + TrailingOffsetPoints * Point) >= orderStopLoss) {
			      return;
			   }
            OrderModify(OrderTicket(), OrderOpenPrice(), NormPrice(Ask + TrailingOffsetPoints * Point), OrderTakeProfit(), OrderExpiration(), clrNONE);
			}
		}
	}
}


double NormPrice(double Price) {
	return NormalizeDouble(Price, Digits);
}

bool checkEntry(string sym, double entry, int tradeType)
{
   bool result = false;
   double lastEntry = getLastEntry(sym);
   
   if (tradeType == OP_BUY && entry < lastEntry) {
      result = true;
   } else if (tradeType == OP_SELL && entry > lastEntry) {
      result = true;
   }
    
   return result;
}
