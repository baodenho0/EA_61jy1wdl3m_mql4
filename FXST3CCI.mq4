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
extern double lots = 0.01;
extern double dailyDrawdown = 0.045;
extern double limitMaxDrawdown = 8800;
string globalRandom = "_j7a2zwqfp4_FXST3CCI";

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
   
   if (AccountProfit() > 0) {
      closeTradingByTradeType(sym, closeType);
   }
   
   if (tradeType == -1 || (lastTradeType != -1 && lastTradeType != tradeType)) {
      return;
   }   
   runTrading(sym, tradeType);
}


int checkFx_Sniper_CCI_T3_New(string sym)
{
   int tradeType = -1;
   double up = iCustom(sym, timeframe, Fx_Sniper_CCI_T3_New, 13,13,0.3,3,100, 4, 0);
   double up1 = iCustom(sym, timeframe, Fx_Sniper_CCI_T3_New, 13,13,0.3,3,100, 9, 1);
   
   double down = iCustom(sym, timeframe, Fx_Sniper_CCI_T3_New, 13,13,0.3,3,100, 3, 0);
   double down1 = iCustom(sym, timeframe, Fx_Sniper_CCI_T3_New, 13,13,0.3,3,100, 10, 1);
   
   Alert("up: " + up + " up1: " + up1 + " | down: " + down + " down1: " + down1);
   
   if ((down > 0 && down < 500) || (down1 > 0 && down1 < 500)) {
      tradeType = OP_SELL;
   } else if ((up < 0 && up > -500) || (up1 < 0 && up1 > -500)) {
      tradeType= OP_BUY;
   }
   
   return tradeType;
}

void runTrading(string sym, int tradeType, double lot = 0) 
{
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
   
   entry = NormalizeDouble(entry, MarketInfo(sym, MODE_DIGITS));
   
   
   if(lot == 0) {
      lot = getLot(sym);
   }
   
   if(entry && lot > 0) {
      string commentOrder = "";
      OrderSend(sym, tradeType, lot, entry, slippage, SL, TP, commentOrder, magic, 0, tradeColor);      
   }
}

double getLot(string sym)
{
   return lots;
}

void closeTradingByTradeType(string sym, int tradeType)
{
   double closePrice; 
   double bidPrice;
   double askPrice;
   
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
      }
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

void calculateDrawdown()
{
   if (Hour() == 00 || getLimitDayDrawdown() == 0) {
      setLimitDayDrawdown(AccountEquity() - (AccountEquity() * dailyDrawdown));
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

void setLimitDayDrawdown(int value = 0)
{
   GlobalVariableSet("LimitDayDrawdown" + globalRandom, value);
}

void resetGlobal()
{
   setCheckDayDrawdown();  
   setCheckMaxDrawdown(); 
   setLimitDayDrawdown();
}

