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
int magic = 991212;
extern string bbsqueezeaverages = "bbsqueeze averages (mtf + alerts + multi symbol)";
extern string ChandelierExit = "ChandelierExit";
ENUM_TIMEFRAMES timeframe = PERIOD_CURRENT;
int slippage = 1;
datetime tradeTime;
extern double lots = 0.02;
extern double dailyDrawdown = 0.03;
extern double limitMaxDrawdown = 8800;
string globalRandom = "_j7a2zwqfp4_bbsqueeze";
int SLpoints = 0;
int TPpoints = 0;
int TPprice = 9999999;
extern int maxTotalOrder = 30;
extern double maxLoss = 0.011;
extern int totalXLot = 10;
extern double xLot = 3;
extern int totalXLot1 = 19;
extern double xLot1 = 4;
//extern int maxLossPoints = 2900;
extern int consecutiveWins = 2;
int forceStopTradeType = -1;
extern double closeProfit = 10;
int trailingPoints = 20;
int bigWave = 130;
//extern string ichiTrend = "------ichiTrend-------";
ENUM_TIMEFRAMES ichiTrendTimeframe = PERIOD_CURRENT;
int only = OP_SELL;
double totalLots = 0;
extern int useHedgeTotal = 20;
extern double xHedge = 3;


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
int a26 = 0;
int a27 = 0;
int a28 = 0;
int a29 = 0;
int a30 = 0;
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
      Alert("21: " + a21);
      Alert("22: " + a22);
      Alert("23: " + a23);
      Alert("24: " + a24);
      Alert("25: " + a25);
      Alert("26: " + a26);
      Alert("27: " + a27);
      Alert("28: " + a28);
      Alert("29: " + a29);
      Alert("30: " + a30);
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
   
   int checkBbsqueezeaverages = checkBbsqueezeaverages(sym);
   tradeType = checkBbsqueezeaverages; Alert("tradeType: " + tradeType);  
   
   if (tradeType == OP_BUY) {
      closeType = OP_SELL;
   } else if (tradeType == OP_SELL) {
      closeType = OP_BUY;
   } 
   
   closeTradingByTradeType(sym, closeType);
   
   if (tradeType == -1) {
      return;
   }
   
   if (tradeType == OP_BUY && tradeType != checkChandelierExitX15(sym)) {
      return;
   }
   
   runTrading(sym, tradeType);
}

void runTrading(string sym, int tradeType, double lot = 0) 
{
   if (Hour() <= 1 || Hour() >= 23 || getAllowTrade() == 1 || (only != tradeType && OrdersTotal() <= useHedgeTotal)) {
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

   if (SLpoints != 0 ) {
      SL = getSLByPips(sym, tradeType, entry);
      SL = NormalizeDouble(SL, MarketInfo(sym, MODE_DIGITS));
   }
   
   if (TPpoints != 0 ) {
      TP = getTPByPips(sym, tradeType, entry);    
      TP = NormalizeDouble(TP, MarketInfo(sym, MODE_DIGITS));
   }   
   
   entry = NormalizeDouble(entry, MarketInfo(sym, MODE_DIGITS));

   if (!checkEntry(sym, entry, tradeType)) {
      return;
   }
   
   if(lot == 0) {
      lot = getLot(sym, tradeType);
   }
   
   if(entry && lot > 0) {
      string commentOrder = "";

      OrderSend(sym, tradeType, lot, entry, slippage, SL, TP, commentOrder, magic, 0, tradeColor);      
      totalLots = totalLots + lot;
   }
}

double getLot(string sym, int tradeType)
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
  
  double lastLots = getLastLots(sym, tradeType);
  
  if (lastLots) {
      tmpLots = lastLots;
  }
  
  if (getOrdersTotal(sym, tradeType) > totalXLot) {
      tmpLots = tmpLots * xLot;
  }

  if (getOrdersTotal(sym, tradeType) > totalXLot1) {
      tmpLots = tmpLots * xLot1;
  }
  
  if (getOrdersTotal(sym, OP_SELL) >= useHedgeTotal && tradeType == OP_BUY) {
     tmpLots = totalLots * xHedge;
  }
  
  double lotstep = MarketInfo(sym,MODE_LOTSTEP);
  double maxLot = (AccountFreeMargin())/MarketInfo(sym,MODE_MARGINREQUIRED);
  maxLot = DoubleToStr(MathFloor(maxLot/lotstep)*lotstep,2); 
  if (tmpLots > maxLot) {
      tmpLots = maxLot;
  }

  return tmpLots;
      
}

double getAccountProfitByTradeType(int tradeType)
{
   double profit = 0;
   
   for(int i = OrdersTotal() - 1; i >= 0; i--) {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES) && tradeType == OrderType()) {                     
         profit = profit + OrderCommission() + OrderSwap() + OrderProfit();    
      }
   }
   
   return profit;
}

void closeTradingByTradeType(string sym, int tradeType)
{
   if (getAccountProfitByTradeType(tradeType) <= 0) {
      return;
   }
   
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
   
   ObjectCreate(currentChartId, "totalLots", OBJ_LABEL, 0, 0 ,0);
   ObjectSet("totalLots", OBJPROP_CORNER, CORNER_RIGHT_UPPER);
   ObjectSet("totalLots", OBJPROP_XDISTANCE, 50);
   ObjectSet("totalLots", OBJPROP_YDISTANCE, 120);
   ObjectSetText("totalLots", "Lots: " + totalLots, 15, "Impact", Red);
   
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

int getLastLots(string sym, int tradeType)
{
   int tmpLots = 0;
   int i = 0;
   
   while (true) {
      if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
         break;
      }
      if (OrderType() == tradeType) {
         tmpLots = OrderLots();
         break;
      }
      i++;
   }
   
   return tmpLots;
}


int getOrdersTotal(string sym, int tradeType)
{
   int tmpOrdersTotal = 0;
   int i = 0;
   
   while (true) {
      if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
         break;
      }
      if (OrderType() == tradeType) {
         tmpOrdersTotal++;
      }
      i++;
   }
   
   return tmpOrdersTotal;
}

int getLastEntry(string sym, int tradeType)
{
   int tmpEntry = 0;
   int i = 0;
   
   while (true) {
      if (!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
         break;
      }
      if (OrderType() == tradeType) {         
         if (!tmpEntry) {
            tmpEntry = OrderOpenPrice();
         }
         
         if (tradeType == OP_BUY && OrderOpenPrice() < tmpEntry) {
            tmpEntry = OrderOpenPrice();
         } else if (tradeType == OP_SELL && OrderOpenPrice() > tmpEntry) {
            tmpEntry = OrderOpenPrice();
         }
      }
      i++;
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
   if (//OrdersTotal() >= maxTotalOrder && AccountEquity() <= (AccountBalance() - (AccountBalance() * maxLoss))
      //|| Hour() >= 21 && Hour() <= 24 && AccountProfit() >= 0
      //|| (Hour() >= 22 && Hour() <= 24 && AccountEquity() <= (AccountBalance() - (AccountBalance() * maxLoss)))
      //|| OrdersTotal() > 5 && AccountProfit() >= 0
      //|| OrdersTotal() > 5 //&& AccountProfit() >= 0
      AccountEquity() <= getLimitDayDrawdown()
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
   }if (ordersTotal == 21) {
      a16 = a21 + 1;
   }if (ordersTotal == 22) {
     a17 = a22 + 1;
   }if (ordersTotal == 23) {
      a18 = a23 + 1;
   }if (ordersTotal == 24) {
      a19 = a24 + 1;
   }if (ordersTotal == 25) {
      a20 = a25 + 1;
   }if (ordersTotal == 26) {
      a16 = a26 + 1;
   }if (ordersTotal == 27) {
     a17 = a27 + 1;
   }if (ordersTotal == 28) {
      a18 = a28 + 1;
   }if (ordersTotal == 29) {
      a19 = a29 + 1;
   }if (ordersTotal == 30) {
      a20 = a30 + 1;
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

void checkCloseProfit(string sym)
{
   int ordersTotal = OrdersTotal();
   if (AccountProfit() >= closeProfit) {
      closeAll(sym);
      //trailingStop(trailingPoints);
      //setCountConsecutiveWins(getCountConsecutiveWins() + 1);
      saveRP(ordersTotal);   
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
			   //Alert(NormPrice(Bid - TrailingOffsetPoints * Point) +"-"+ orderStopLoss);
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
   bool result = true;
   double lastEntry = getLastEntry(sym, tradeType); Alert("entry: " + entry + " lastEntry: " +lastEntry);
   
   if (lastEntry != 0 && tradeType == OP_BUY && entry > lastEntry) {
      result = false;
   } else if (lastEntry != 0 && tradeType == OP_SELL && entry < lastEntry) {
      result = false;
   }
    
   return result;
}

int checkIchimokuAndCandle(string sym)
{
   int tradeType = - 1;

   double tenKanSen = iIchimoku(sym, ichiTrendTimeframe, 9, 26, 52, MODE_TENKANSEN, 1);
   double kiJunSen = iIchimoku(sym, ichiTrendTimeframe, 9, 26, 52, MODE_KIJUNSEN, 1);
   double senKouSpanA = iIchimoku(sym, ichiTrendTimeframe, 9, 26, 52, MODE_SENKOUSPANA, 1);
   double senKouSpanB = iIchimoku(sym, ichiTrendTimeframe, 9, 26, 52, MODE_SENKOUSPANB, 1);
   double chiKouSpan = iIchimoku(sym, ichiTrendTimeframe, 9, 26, 52, MODE_CHIKOUSPAN, 27);
   double senKouSpanAFuture = iIchimoku(sym, ichiTrendTimeframe, 9, 26, 52, MODE_SENKOUSPANA, -25);
   double senKouSpanBFuture = iIchimoku(sym, ichiTrendTimeframe, 9, 26, 52, MODE_SENKOUSPANB, -25);
   double senKouSpanAPast = iIchimoku(sym, ichiTrendTimeframe, 9, 26, 52, MODE_SENKOUSPANA, 27);
   double senKouSpanBPast = iIchimoku(sym, ichiTrendTimeframe, 9, 26, 52, MODE_SENKOUSPANB, 27);
   
   double openPrice = iOpen(sym, ichiTrendTimeframe, 1);
   double closePrice = iClose(sym, ichiTrendTimeframe, 1);
   
   if (
      senKouSpanAFuture > senKouSpanBFuture
   ) {
      tradeType = OP_BUY;
   } else if (
      senKouSpanAFuture < senKouSpanBFuture
   ) {
      tradeType = OP_SELL;
   }
   //Alert("openPrice: " + openPrice +" < senKouSpanA: "+  senKouSpanA + " && closePrice: " + closePrice + " < senKouSpanB: " + senKouSpanB + " && tenKanSen: " +  tenKanSen + " < kiJunSen: " + kiJunSen);
   
   return (tradeType);
}

int checkIchimokuAndCandleX5(string sym)
{
   int tradeType = - 1;
   
   double tenKanSen = iIchimoku(sym, timeframe, 45, 130, 260, MODE_TENKANSEN, 1);
   double kiJunSen = iIchimoku(sym, timeframe, 45, 130, 260, MODE_KIJUNSEN, 1);
   double senKouSpanA = iIchimoku(sym, timeframe, 45, 130, 260, MODE_SENKOUSPANA, 1);
   double senKouSpanB = iIchimoku(sym, timeframe, 45, 130, 260, MODE_SENKOUSPANB, 1);
   double chiKouSpan = iIchimoku(sym, timeframe, 45, 130, 260, MODE_CHIKOUSPAN, 132);
   double senKouSpanAFuture = iIchimoku(sym, timeframe, 45, 130, 260, MODE_SENKOUSPANA, -129);
   double senKouSpanBFuture = iIchimoku(sym, timeframe, 45, 130, 260, MODE_SENKOUSPANB, -129);
   double senKouSpanAPast = iIchimoku(sym, timeframe, 45, 130, 260, MODE_SENKOUSPANA, 132);
   double senKouSpanBPast = iIchimoku(sym, timeframe, 45, 130, 260, MODE_SENKOUSPANB, 132);
   
   //double senKouSpanAFuture = iIchimoku(sym, timeframe, 9, 26, 52, MODE_SENKOUSPANA, -25);
   //double senKouSpanBFuture = iIchimoku(sym, timeframe, 9, 26, 52, MODE_SENKOUSPANB, -25);
   
   double openPrice = iOpen(sym, timeframe, 1);
   double closePrice = iClose(sym, timeframe, 1);
   
   if (
      openPrice > senKouSpanA && closePrice > senKouSpanB
   ) {
      tradeType = OP_BUY;
   } else if (
      openPrice < senKouSpanA && closePrice < senKouSpanB
   ) {
      tradeType = OP_SELL;
   }
   
   return tradeType;
}

int checkMA200(string sym)
{
   int tradeType = - 1;
   
   double ma200 = iMA(sym,timeframe,200,0,MODE_EMA,PRICE_CLOSE,1);
   double openPrice = iOpen(sym, timeframe, 1);
   double closePrice = iClose(sym, timeframe, 1);
   
   if (
      openPrice > ma200 && closePrice > ma200
   ) {
      tradeType = OP_BUY;
   } else if (
      openPrice < ma200 && closePrice < ma200
   ) {
      tradeType = OP_SELL;
   }
   
   return tradeType;
}

bool checkStockastic(string sym)
{
   bool result = false;

   double k = iStochastic(sym, timeframe, 25, 15, 15, MODE_SMA, 0, MODE_MAIN, 1);
   double d = iStochastic(sym, timeframe, 25, 15, 15, MODE_SMA, 0, MODE_SIGNAL, 1); 
   
   k = NormalizeDouble(k, MarketInfo(sym, MODE_DIGITS));
   d = NormalizeDouble(d, MarketInfo(sym, MODE_DIGITS));
   
   if(k < 80 && d < 80 && k > 30 && d > 30) {
      result = true;
   }
   
   return result;
}

int checkBbsqueezeaverages(string sym)
{
   int tradeType = -1;
   double upper = iCustom(sym, timeframe, bbsqueezeaverages, 0, 1);
   double lower = iCustom(sym, timeframe, bbsqueezeaverages, 1, 1);
   
   double upper2 = iCustom(sym, timeframe, bbsqueezeaverages, 0, 2);
   double lower2 = iCustom(sym, timeframe, bbsqueezeaverages, 1, 2);
   
   double value = iCustom(sym, timeframe, bbsqueezeaverages, 4, 1);
   double value1 = iCustom(sym, timeframe, bbsqueezeaverages, 4, 2);
   
   
   upper = NormalizeDouble(upper, MarketInfo(sym, MODE_DIGITS));
   lower = NormalizeDouble(lower, MarketInfo(sym, MODE_DIGITS));
   upper2 = NormalizeDouble(upper2, MarketInfo(sym, MODE_DIGITS));
   lower2 = NormalizeDouble(lower2, MarketInfo(sym, MODE_DIGITS));
   value = NormalizeDouble(value, MarketInfo(sym, MODE_DIGITS));
   value1 = NormalizeDouble(value1, MarketInfo(sym, MODE_DIGITS));
   Alert(value);
   //Alert("upper:" + upper + " lower: " + lower);
      
   if (value >= 0 && value1 < 0) {
      tradeType = OP_BUY;
   } else if (value <= 0 && value1 > 0) {
      tradeType = OP_SELL;
   } 
   
   return tradeType;
}

int checkChandelierExitX5(string sym)
{
   int tradeType = -1;
   double lower = iCustom(sym, timeframe, ChandelierExit,7,0,9,12.5, 0, 1);
   double upper = iCustom(sym, timeframe, ChandelierExit,7,0,9,12.5, 1, 1);
   
   double lower2 = iCustom(sym, timeframe, ChandelierExit,7,0,9,12.5, 0, 2);
   double upper2 = iCustom(sym, timeframe, ChandelierExit,7,0,9,12.5, 1, 2);
      
   if (upper > 0 && upper < 999999) {
      tradeType = OP_SELL;
   } else if (lower > 0 && lower < 999999) {
      tradeType = OP_BUY;
   } 
   
   return tradeType;
}

int checkChandelierExitX15(string sym)
{
   int tradeType = -1;
   double lower = iCustom(sym, timeframe, ChandelierExit,7,0,9,37.5, 0, 1);
   double upper = iCustom(sym, timeframe, ChandelierExit,7,0,9,37.5, 1, 1);
   
   double lower2 = iCustom(sym, timeframe, ChandelierExit,7,0,9,37.5, 0, 2);
   double upper2 = iCustom(sym, timeframe, ChandelierExit,7,0,9,37.5, 1, 2);
      
   if (upper > 0 && upper < 999999) {
      tradeType = OP_SELL;
   } else if (lower > 0 && lower < 999999) {
      tradeType = OP_BUY;
   } 
   
   return tradeType;
}

