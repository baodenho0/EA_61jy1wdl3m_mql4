//+------------------------------------------------------------------+
//|                                                     TudoGirl.mq4 |
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

string comment;
datetime tradeTime;
bool allowTrade = true;
int magic = 991112;
extern ENUM_TIMEFRAMES timeframe = PERIOD_M1;
extern ENUM_TIMEFRAMES timeframe1 = PERIOD_M5;
extern ENUM_TIMEFRAMES timeframe2 = PERIOD_M15;
extern ENUM_TIMEFRAMES timeframe3 = PERIOD_M30;

extern string HG_0001a_MTF = "HG_0001a_MTF";
string globalRandom = "_u6hxhs7f2p_TudorGirl";
int slippage = 0;
extern int SL = 500;
extern int TP = 250;


int OnInit()
  {
//---
   if (IsTesting()) {
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
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   string sym = Symbol();
   drawButton(sym);
   if(tradeTime == iTime(sym, timeframe, 0)) {
      return;      
   }
   tradeTime = iTime(sym, 0, 0);
   closeTradingByTradeType(sym);
   checkRun(sym);
  }
//+------------------------------------------------------------------+

int checkHG_0001a_MTF1(string sym)
{   
   int tradeType = -1;
   
   double redM1_1 = iCustom(sym, timeframe, HG_0001a_MTF, 1, timeframe, timeframe1, timeframe2, timeframe3, 0, 1); // red m1
   double blueM1_1 = iCustom(sym, timeframe, HG_0001a_MTF, 1, timeframe, timeframe1, timeframe2, timeframe3, 1, 1); // blue m1
   double redM5_1 = iCustom(sym, timeframe, HG_0001a_MTF, 1, timeframe, timeframe1, timeframe2, timeframe3, 2, 1); // red m5
   double blueM5_1 = iCustom(sym, timeframe, HG_0001a_MTF, 1, timeframe, timeframe1, timeframe2, timeframe3, 3, 1); // blue m5
   double redM15_1 = iCustom(sym, timeframe, HG_0001a_MTF, 1, timeframe, timeframe1, timeframe2, timeframe3, 4, 1); // red m15
   double blueM15_1 = iCustom(sym, timeframe, HG_0001a_MTF, 1, timeframe, timeframe1, timeframe2, timeframe3, 5, 1); // blue m15
   double redM30_1 = iCustom(sym, timeframe, HG_0001a_MTF, 1, timeframe, timeframe1, timeframe2, timeframe3, 6, 1); // red m30
   double blueM30_1 = iCustom(sym, timeframe, HG_0001a_MTF, 1, timeframe, timeframe1, timeframe2, timeframe3, 7, 1); // blue m30
   
   double redM1_2 = iCustom(sym, timeframe, HG_0001a_MTF, 1, timeframe, timeframe1, timeframe2, timeframe3, 0, 2); // red m1
   double blueM1_2 = iCustom(sym, timeframe, HG_0001a_MTF, 1, timeframe, timeframe1, timeframe2, timeframe3, 1, 2); // blue m1
   double redM5_2 = iCustom(sym, timeframe, HG_0001a_MTF, 1, timeframe, timeframe1, timeframe2, timeframe3, 2, 2); // red m5
   double blueM5_2 = iCustom(sym, timeframe, HG_0001a_MTF, 1, timeframe, timeframe1, timeframe2, timeframe3, 3, 2); // blue m5
   double redM15_2 = iCustom(sym, timeframe, HG_0001a_MTF, 1, timeframe, timeframe1, timeframe2, timeframe3, 4, 2); // red m15
   double blueM15_2 = iCustom(sym, timeframe, HG_0001a_MTF, 1, timeframe, timeframe1, timeframe2, timeframe3, 5, 2); // blue m15
   double redM30_2 = iCustom(sym, timeframe, HG_0001a_MTF, 1, timeframe, timeframe1, timeframe2, timeframe3, 6, 2); // red m30
   double blueM30_2 = iCustom(sym, timeframe, HG_0001a_MTF, 1, timeframe, timeframe1, timeframe2, timeframe3, 7, 2); // blue m30
   
   double redM1_3 = iCustom(sym, timeframe, HG_0001a_MTF, 1, timeframe, timeframe1, timeframe2, timeframe3, 0, 3); // red m1
   double blueM1_3 = iCustom(sym, timeframe, HG_0001a_MTF, 1, timeframe, timeframe1, timeframe2, timeframe3, 1, 3); // blue m1
   double redM5_3 = iCustom(sym, timeframe, HG_0001a_MTF, 1, timeframe, timeframe1, timeframe2, timeframe3, 2, 3); // red m5
   double blueM5_3 = iCustom(sym, timeframe, HG_0001a_MTF, 1, timeframe, timeframe1, timeframe2, timeframe3, 3, 3); // blue m5
   double redM15_3 = iCustom(sym, timeframe, HG_0001a_MTF, 1, timeframe, timeframe1, timeframe2, timeframe3, 4, 3); // red m15
   double blueM15_3 = iCustom(sym, timeframe, HG_0001a_MTF, 1, timeframe, timeframe1, timeframe2, timeframe3, 5, 3); // blue m15
   double redM30_3 = iCustom(sym, timeframe, HG_0001a_MTF, 1, timeframe, timeframe1, timeframe2, timeframe3, 6, 3); // red m30
   double blueM30_3 = iCustom(sym, timeframe, HG_0001a_MTF, 1, timeframe, timeframe1, timeframe2, timeframe3, 7, 3); // blue m30
   
   double redM1_4 = iCustom(sym, timeframe, HG_0001a_MTF, 1, timeframe, timeframe1, timeframe2, timeframe3, 0, 4); // red m1
   double blueM1_4 = iCustom(sym, timeframe, HG_0001a_MTF, 1, timeframe, timeframe1, timeframe2, timeframe3, 1, 4); // blue m1
   double redM5_4 = iCustom(sym, timeframe, HG_0001a_MTF, 1, timeframe, timeframe1, timeframe2, timeframe3, 2, 4); // red m5
   double blueM5_4 = iCustom(sym, timeframe, HG_0001a_MTF, 1, timeframe, timeframe1, timeframe2, timeframe3, 3, 4); // blue m5
   double redM15_4 = iCustom(sym, timeframe, HG_0001a_MTF, 1, timeframe, timeframe1, timeframe2, timeframe3, 4, 4); // red m15
   double blueM15_4 = iCustom(sym, timeframe, HG_0001a_MTF, 1, timeframe, timeframe1, timeframe2, timeframe3, 5, 4); // blue m15
   double redM30_4 = iCustom(sym, timeframe, HG_0001a_MTF, 1, timeframe, timeframe1, timeframe2, timeframe3, 6, 4); // red m30
   double blueM30_4 = iCustom(sym, timeframe, HG_0001a_MTF, 1, timeframe, timeframe1, timeframe2, timeframe3, 7, 4); // blue m30
   
   Comment("redM1_1: " + redM1_1 + " blueM1_1: " + blueM1_1 + " | redM5_1: " + redM5_1 + " blueM5_1: " + blueM5_1 + " | redM15_1: " + redM15_1 + " blueM15_1: " + blueM15_1
      + "\n || " + "redM1_2: " + redM1_2 + " blueM1_2: " + blueM1_2 + " | redM5_2: " + redM5_2 + " blueM5_2: " + blueM5_2 + " | redM15_2: " + redM15_2 + " blueM15_2: " + blueM15_2
      + "\n || " + "redM1_3: " + redM1_3 + " blueM1_3: " + blueM1_3 + " | redM5_3: " + redM5_3 + " blueM5_3: " + blueM5_3 + " | redM15_3: " + redM15_3 + " blueM15_3: " + blueM15_3
   );
   
   if (blueM15_1 == 3 && blueM15_2 == 3 /*&& blueM15_3 == 3*/) {
      setTrendTimeframe2("up"); 
   }
   
   if (redM15_1 == 3 && redM15_2 == 3 /*&& redM15_3 == 3*/) {
      setTrendTimeframe2("down");
   }
   
   if (getTrendTimeframe2() == "up"
      && (blueM1_1 == 1 && blueM1_2 == 1 && redM1_3 == 1 && redM1_4 == 1
      || blueM5_1 == 1 && blueM5_2 == 1 && redM5_3 == 1 && redM5_4 == 1)
   ) {
      tradeType = OP_BUY;
   }
   
   if (getTrendTimeframe2() == "down"
      && (redM1_1 == 1 && redM1_2 == 1 && blueM1_3 == 1 && blueM1_3 == 1
      || redM5_1 == 1 && redM5_2 == 1 && blueM5_3 == 1 && blueM5_3 == 1)
   ) {
      tradeType = OP_SELL;
   }
   
   return (tradeType);
}

void closeTradingByTradeType(string sym)
{
   double closePrice; 
   double bidPrice;
   double askPrice;
   int tradeType = -1;
   
   if (getTrendTimeframe2() == "up") {
      tradeType = OP_SELL;
   } else if (getTrendTimeframe2() == "down") {
      tradeType = OP_BUY;
   }
   
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
               break;
            }
            //Alert("Error: " + GetLastError() + " | slippage: " + slippage);            
         }        
      } else {
         return;
      }
   }
}

void checkRun(string sym)
{
   int tradeType = -1;
   int closeType = -1;
   tradeType = checkHG_0001a_MTF1(sym);  
   //if (OrdersTotal() <= 15) {
      runTrading(sym, tradeType);
   //}    
}

void runTrading(string sym, int tradeType, double lot = 0) 
{
   double entry = 0;
   color tradeColor = clrBlue;
   double tmpSL = 0;
   double tmpTP = 0;

   if(tradeType == OP_BUY) {
      entry = MarketInfo(sym, MODE_ASK);
      tradeColor = clrBlue;
   } else if(tradeType == OP_SELL) {
      entry = MarketInfo(sym, MODE_BID);
      tradeColor = clrRed;
   } else {
      return;
   }   
   
   if (tmpSL > 0 && tmpTP > 0) {
      tmpSL = getSLByPips(sym, tradeType, entry);
      if(!tmpSL) {
         return;
      }
      tmpTP = getTPByPips(sym, tradeType, entry);   
      tmpSL = NormalizeDouble(tmpSL, MarketInfo(sym, MODE_DIGITS));
      tmpTP = NormalizeDouble(tmpTP, MarketInfo(sym, MODE_DIGITS));   
   }
   
   entry = NormalizeDouble(entry, MarketInfo(sym, MODE_DIGITS));
   
   
   if(lot == 0) {
      lot = getLot(sym);
   }
   
   if(entry && lot > 0) {
      string commentOrder = "";
      OrderSend(sym, tradeType, lot, entry, slippage, tmpSL, tmpTP, commentOrder, magic, 0, tradeColor);      
   }
}

double getLot(string sym)
{
   return 0.01;
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
   
   ObjectCreate(currentChartId, "getTrendTimeframe2", OBJ_LABEL, 0, 0 ,0);   
   ObjectSet("getTrendTimeframe2", OBJPROP_CORNER, CORNER_RIGHT_UPPER);
   ObjectSet("getTrendTimeframe2", OBJPROP_XDISTANCE, 50);
   ObjectSet("getTrendTimeframe2", OBJPROP_YDISTANCE, 280);
   ObjectSetText("getTrendTimeframe2", "Trend: " + getTrendTimeframe2() , 15, "Impact", Red);
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

string getTrendTimeframe2()
{
   string tmp = "";
   int global = GlobalVariableGet("trendTF2" + globalRandom);
   if (global == 1) {
      tmp = "up";
   } else if (global == 2) {
      tmp = "down";
   }
   
   return tmp;
}

void setTrendTimeframe2(string value = "")
{
   int global = -1;
   if (value == "up") {
      global = 1;
   } else if (value == "down") {
      global = 2;
   }
   GlobalVariableSet("trendTF2" + globalRandom, global);
}

void resetGlobal()
{
   setTrendTimeframe2();   
}

double getSLByPips(string sym, int tradeType, double entry)
{
   double tmpSL = 0;   
   if(tradeType == OP_BUY) {      
     tmpSL = entry - SL * MarketInfo(sym, MODE_POINT);
   } else if(tradeType == OP_SELL) { 
     tmpSL = entry + SL * MarketInfo(sym, MODE_POINT);
   }
   
   return (tmpSL);
}

double getTPByPips(string sym, int tradeType, double entry)
{
   double tmpTP = 0;   
   if(tradeType == OP_BUY) {      
     tmpTP = entry + TP * MarketInfo(sym, MODE_POINT);
   } else if(tradeType == OP_SELL) { 
     tmpTP = entry - TP * MarketInfo(sym, MODE_POINT);
   }
   
   return (tmpTP);
}
