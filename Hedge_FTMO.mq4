//+------------------------------------------------------------------+
//|                                                RichardDennis.mq4 |
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
int slippage = 1;
extern string ChandelierExit = "ChandelierExit";
ENUM_TIMEFRAMES timeframe = PERIOD_CURRENT;
extern string bbsqueezeaverages = "bbsqueeze averages (mtf + alerts + multi symbol)";
datetime tradeTime;
extern double dailyDrawdown = 4.5;//dailyDrawdown(4.5%)
extern double limitMaxDrawdown = 8800;
string globalRandom = "_fsdp4_Hedge_FTMO";
int magic = 92122;
extern int minSL = 30; //minSL(points)
extern double risk = 0.005; //risk(0.005%)
extern double reward = 4;
extern int SLBypoints = 30;
extern double removeHedge = 20;//removeHedge(20)
double totalLots = 0;
bool swap = false;
int optimize = 0;
int countCancel = 0;
string cciWoodieArrowsOscillator = "cci-woodie-arrows-oscillator";
int forceStopTradeType = -1;
int breakEven = 2;

int OnInit()
  {
//---
   if (IsTesting()) {    
         resetGlobal();
         resetGlobalHedge();
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
      //Alert("countCancel: " + countCancel);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
      string sym = Symbol();
      drawButton(sym);
      forceCloseAll(sym);        
      calculateDrawdown();
      useHedge(sym);
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
   //int checkBbsqueezeaverages = checkBbsqueezeaverages(sym);
   //tradeType = checkBbsqueezeaverages;
   
   if (OrdersTotal() == 0) {
      runTrading(sym, OP_BUY);
   }
}

void runTrading(string sym, int tradeType, double lot = 0) 
{
   if (/*(OrdersTotal() == 0 && (Hour() < 1 || Hour() >= 23)) ||*/ getAllowTrade() == 1) {
         return;
   }
      
   double entry = 0;
   color tradeColor = clrBlue;
   double SL = 0;
   double TP = 0;
   double spread = MarketInfo(sym, MODE_SPREAD);
   
   if(tradeType == OP_BUY) {
      entry = MarketInfo(sym, MODE_ASK);
      tradeColor = clrBlue;
   } else if(tradeType == OP_SELL) {
      entry = MarketInfo(sym, MODE_BID);
      tradeColor = clrRed;
   } else {
      return;
   } 
   //entry = MarketInfo(sym, MODE_BID);
   if (swap == true) {
      if (optimize == 1 || optimize == 2) {
         entry = MarketInfo(sym, MODE_BID);
      }
   }     

   SL = getSLByPips(sym, tradeType, entry, SLBypoints);
   if (reward != 0) {
      TP = getTP(sym, entry, SL);
   }

   double SLpoints = MathAbs(NormalizeDouble(entry - SL, MarketInfo(sym, MODE_DIGITS)) / MarketInfo(sym, MODE_POINT));
   if ((SLpoints < minSL)
      || (tradeType == OP_BUY && SL >= entry)
      || (tradeType == OP_SELL && SL <= entry)
      || (SL == 0)
   ) {
      SL = getSLByPips(sym, tradeType, entry, minSL);
      SLpoints = MathAbs(NormalizeDouble(entry - SL, MarketInfo(sym, MODE_DIGITS)) / MarketInfo(sym, MODE_POINT));
   }
   
   if (SLpoints < MarketInfo(Symbol(), MODE_STOPLEVEL)) {
      if(tradeType == OP_BUY) {
         SL = MarketInfo(sym, MODE_ASK) - MarketInfo(Symbol(), MODE_STOPLEVEL) * MarketInfo(sym, MODE_POINT);
      } else if(tradeType == OP_SELL) {
         SL = MarketInfo(sym, MODE_BID) * MarketInfo(Symbol(), MODE_STOPLEVEL) * MarketInfo(sym, MODE_POINT);
      }
   }
   
   SLpoints = MathAbs(NormalizeDouble(entry - SL, MarketInfo(sym, MODE_DIGITS)) / MarketInfo(sym, MODE_POINT));
   
   if(lot == 0) {
      lot = getLot(sym, SLpoints);
   }
   
   entry = NormalizeDouble(entry, MarketInfo(sym, MODE_DIGITS));
   SL = NormalizeDouble(SL, MarketInfo(sym, MODE_DIGITS));
   TP = NormalizeDouble(TP, MarketInfo(sym, MODE_DIGITS));
   
   if(entry && lot > 0) {
      string commentOrder = "";
      if (tradeType == OP_BUY) {
            entry = MarketInfo(sym, MODE_ASK); 
         } else if (tradeType == OP_SELL) {
            entry = MarketInfo(sym, MODE_BID);
         }
  
      int ticket = OrderSend(sym, tradeType, lot, entry, slippage, 0, 0, commentOrder, magic, 0, tradeColor);   
      if(ticket < 0) { 
         Print("SL: " + SL + " SLpoints:" + SLpoints + " OrderSend failed with error #",GetLastError()); 
      }  
      totalLots = totalLots + lot;
      
      if(tradeType == OP_BUY) {
         setNextTradeStop(OP_SELLSTOP);
         setBuyStop(entry);
         setSellStop(SL);
         setBuyStopTP(TP);
      } else if(tradeType == OP_SELL) {
         setBuyStop(SL);
         setSellStop(entry);
         setNextTradeStop(OP_BUYSTOP);
         setSellStopTP(TP);
      }
   }
}

int checkChandelierExit(string sym)
{
   int tradeType = -1;
   double lower = iCustom(sym, timeframe, ChandelierExit,7,0,9,3, 0, 1);
   double upper = iCustom(sym, timeframe, ChandelierExit,7,0,9,3, 1, 1);
   
   double lower2 = iCustom(sym, timeframe, ChandelierExit,7,0,9,3, 0, 2);
   double upper2 = iCustom(sym, timeframe, ChandelierExit,7,0,9,3, 1, 2);
      
   if (upper > 0 && upper < 999999) {
      tradeType = OP_SELL;
   } else if (lower > 0 && lower < 999999) {
      tradeType = OP_BUY;
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

int checkChandelierExitX30(string sym)
{
   int tradeType = -1;
   double lower = iCustom(sym, timeframe, ChandelierExit,7,0,9,75, 0, 1);
   double upper = iCustom(sym, timeframe, ChandelierExit,7,0,9,75, 1, 1);
   
   double lower2 = iCustom(sym, timeframe, ChandelierExit,7,0,9,75, 0, 2);
   double upper2 = iCustom(sym, timeframe, ChandelierExit,7,0,9,75, 1, 2);
      
   if (upper > 0 && upper < 999999) {
      tradeType = OP_SELL;
   } else if (lower > 0 && lower < 999999) {
      tradeType = OP_BUY;
   } 
   
   return tradeType;
}

double getSL(string sym, int tradeType)
{  
   double lower = iCustom(sym, timeframe, ChandelierExit,7,0,9,3, 0, 0);
   double upper = iCustom(sym, timeframe, ChandelierExit,7,0,9,3, 1, 0);

   double SL = 0;
   if (tradeType == OP_BUY) {
      SL = lower;
   } else if (tradeType == OP_SELL) {
      SL = upper;
   }
   
   if (SL < 0 || SL > 999999) {
      SL = 0;
   }
   
   return NormalizeDouble(SL, MarketInfo(sym, MODE_DIGITS));;
}

double getTP(string sym, double entry, double SL)
{
   double TP = 0;
   
   if(SL < entry) {
      TP = entry + (entry - SL) * reward;
   } else if(SL > entry) {
      TP = entry - (SL - entry) * reward;
   }
   
   
   
   return (TP);   
}

double getLot(string sym, double SLPoints)
{
   double balance = AccountBalance();
   double lotSize;
   if(balance == 0) {
      Alert("balance: " + balance);
      return 0;
   }
   
   double amountRisk = MathAbs(risk/100*balance);
   double tickVal = MarketInfo(sym , MODE_TICKVALUE);
   double tickSize = MarketInfo(sym , MODE_TICKSIZE);

    if(SLPoints != 0 && tickSize != 0 && tickVal != 0) {
      SLPoints = SLPoints * MarketInfo(sym, MODE_POINT);
      lotSize = amountRisk / (SLPoints * tickVal / tickSize);
      //Alert("lotSize=amountRisk/(SLPoints*tickVal/tickSize) - " + lotSize + "=" + amountRisk + "/" + "(" + SLPoints + "*" + tickVal + "/" + tickSize + ")");
    } else {
      return 0;
    }

    double lotStep = MarketInfo(sym, MODE_LOTSTEP);
    int step;
    if(lotStep == 1){
      step = 0;
    }
    if(lotStep == 0.01){
      step = 2;
    }
    if(lotStep == 0.001){
      step = 3;
    }
    if(lotStep == 0.1){
      step = 1;
    }
    lotSize = NormalizeDouble(lotSize,step);
    if (lotSize < MarketInfo(sym, MODE_MINLOT)) {
      lotSize = MarketInfo(sym, MODE_MINLOT);  
    }                  
    if (lotSize > MarketInfo(sym, MODE_MAXLOT)) {
      lotSize = MarketInfo(sym, MODE_MAXLOT);   
    }            
    
    //Alert("balance: " + balance + " | amountRisk: " + amountRisk + " | lotSize: " + lotSize + " | SLPoints: " + SLPoints);  
    double lotstep = MarketInfo(sym,MODE_LOTSTEP);
    double maxlot = (AccountFreeMargin())/MarketInfo(sym,MODE_MARGINREQUIRED);
    maxlot = DoubleToStr(MathFloor(maxlot/lotstep)*lotstep,2); 
    if(lotSize > maxlot) {
      Comment("Initial Lots: " + lotSize);
      lotSize = maxlot;
    }
    return(lotSize);
}

void drawButton(string sym)
{
   long currentChartId = ChartID();  
   
   double spread = MarketInfo(sym, MODE_SPREAD);
   
   ObjectCreate(currentChartId, "totalLots", OBJ_LABEL, 0, 0 ,0);
   ObjectSet("totalLots", OBJPROP_CORNER, CORNER_RIGHT_UPPER);
   ObjectSet("totalLots", OBJPROP_XDISTANCE, 50);
   ObjectSet("totalLots", OBJPROP_YDISTANCE, 120);
   ObjectSetText("totalLots", "Lots: " + NormalizeDouble(totalLots, 2), 15, "Impact", Red);
   
   ObjectCreate(currentChartId, "showSpread", OBJ_LABEL, 0, 0 ,0);   
   ObjectSet("showSpread", OBJPROP_CORNER, CORNER_RIGHT_UPPER);
   ObjectSet("showSpread", OBJPROP_XDISTANCE, 50);
   ObjectSet("showSpread", OBJPROP_YDISTANCE, 160);
   ObjectSetText("showSpread", "Spread: " + spread + " Next bar in: " + getNextBar(), 15, "Impact", Red);
   
   ObjectCreate(currentChartId, "accountProfit", OBJ_LABEL, 0, 0 ,0);   
   ObjectSet("accountProfit", OBJPROP_CORNER, CORNER_RIGHT_UPPER);
   ObjectSet("accountProfit", OBJPROP_XDISTANCE, 50);
   ObjectSet("accountProfit", OBJPROP_YDISTANCE, 200);
   ObjectSetText("accountProfit", "Account Profit: " + DoubleToString(AccountProfit(),2) + "(" + OrdersTotal() + ")" , 15, "Impact", Red);
   
   ObjectCreate(currentChartId, "AccountBalance", OBJ_LABEL, 0, 0 ,0);   
   ObjectSet("AccountBalance", OBJPROP_CORNER, CORNER_RIGHT_UPPER);
   ObjectSet("AccountBalance", OBJPROP_XDISTANCE, 50);
   ObjectSet("AccountBalance", OBJPROP_YDISTANCE, 240);
   ObjectSetText("AccountBalance", "AccountBalance: " + AccountBalance() + " | AccountEquity: " + DoubleToString(AccountEquity(), 2) , 15, "Impact", Red);
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
      setLimitDayDrawdown(account - (account * dailyDrawdown/100));
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

int getTmpAllowTrade()
{
   return GlobalVariableGet("TmpAllowTrade" + globalRandom);
}

void setTmpAllowTrade(int value = 0)
{
   GlobalVariableSet("TmpAllowTrade" + globalRandom, value);
}

double getCurrentLossTrade()
{
   return GlobalVariableGet("currentLossTrade" + globalRandom);
}

void setCurrentLossTrade(double value = 0)
{
   GlobalVariableSet("currentLossTrade" + globalRandom, value);
}

int getCountCurrentLossTrade()
{
   return GlobalVariableGet("countCurrentLossTrade" + globalRandom);
}

void setCountCurrentLossTrade(int value = 0)
{
   GlobalVariableSet("countCurrentLossTrade" + globalRandom, value);
}

double getBuyStop()
{
   return GlobalVariableGet("buyStop" + globalRandom);
}

void setBuyStop(double value = -1)
{
   GlobalVariableSet("buyStop" + globalRandom, value);
}

double getSellStop()
{
   return GlobalVariableGet("sellStop" + globalRandom);
}

void setSellStop(double value = -1)
{
   GlobalVariableSet("sellStop" + globalRandom, value);
}

double getBuyStopTP()
{
   return GlobalVariableGet("buyStopTP" + globalRandom);
}

void setBuyStopTP(double value = -1)
{
   GlobalVariableSet("buyStopTP" + globalRandom, value);
}

double getSellStopTP()
{
   return GlobalVariableGet("sellStopTP" + globalRandom);
}

void setSellStopTP(double value = -1)
{
   GlobalVariableSet("sellStopTP" + globalRandom, value);
}

int getNextTradeStop()
{
   return GlobalVariableGet("nextTradeStop" + globalRandom);
}

void setNextTradeStop(int value = -1)
{
   GlobalVariableSet("nextTradeStop" + globalRandom, value);
}

int getRemoveHedge()
{
   return GlobalVariableGet("removeHedge" + globalRandom);
}

void setRemoveHedge(int value = -1)
{
   GlobalVariableSet("removeHedge" + globalRandom, value);
}

void resetGlobal()
{
   setCheckDayDrawdown();  
   setCheckMaxDrawdown(); 
   setLimitDayDrawdown();
   setAllowTrade();
   setTmpAllowTrade();
}

void resetGlobalHedge()
{
   setCurrentLossTrade();
   setCountCurrentLossTrade();
   setBuyStop();
   setSellStop();
   setNextTradeStop();
   setBuyStopTP();
   setSellStopTP();
   setRemoveHedge();
}

void forceCloseAll(string sym, int force = false)
{
   int orderTotal = OrdersTotal();
   double accountProfit = AccountProfit();
   if (
         OrdersTotal() <= breakEven && AccountProfit() > (AccountBalance() * risk/100 * reward)
      || OrdersTotal() > breakEven && AccountProfit() > 0      
   ) {
      closeAll(sym);
      resetGlobalHedge();
   }
   
   if (AccountEquity() <= getLimitDayDrawdown()
      || OrdersTotal() <= breakEven && AccountProfit() > (AccountBalance() * risk * reward)
      || OrdersTotal() > breakEven && AccountProfit() > 0      
   ) {
      closeAll(sym);
      setAllowTrade(1);   
      resetGlobalHedge();
   }   
}

void closeAll(string sym)
{
   double closePrice; 
   double bidPrice;
   double askPrice;
   
   for(int i = OrdersTotal() - 1; i >= 0; i--) {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES) && (OrderType() == OP_BUY || OrderType() == OP_SELL) && OrderProfit() >= 0) {                     
         
         double orderProfit = 0;
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
            Alert("Error: " + GetLastError() + " | slippage: " + slippage);            
         }             
      }
   }
   
   for(int i = OrdersTotal() - 1; i >= 0; i--) {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES) && (OrderType() == OP_BUY || OrderType() == OP_SELL) && OrderProfit() < 0) {                     
         
         double orderProfit = 0;
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
            Alert("Error: " + GetLastError() + " | slippage: " + slippage);            
         }             
      }
   }
   
   checkCancel(sym);
}


void closeTradingByTradeType(string sym, int tradeType)
{
   double closePrice; 
   double bidPrice;
   double askPrice;
   
   for(int i = OrdersTotal() - 1; i >= 0; i--) {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES) && tradeType == OrderType()) {                     
         
         double orderProfit = 0;
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
            Alert("Error: " + GetLastError() + " | slippage: " + slippage);            
         }             
      }
   } 
   
   checkCancel(sym);
}

int checkIchimokuAndCandle(string sym)
{
   int tradeType = - 1;

   double tenKanSen = iIchimoku(sym, timeframe, 9, 26, 52, MODE_TENKANSEN, 1);
   double kiJunSen = iIchimoku(sym, timeframe, 9, 26, 52, MODE_KIJUNSEN, 1);
   double senKouSpanA = iIchimoku(sym, timeframe, 9, 26, 52, MODE_SENKOUSPANA, 1);
   double senKouSpanB = iIchimoku(sym, timeframe, 9, 26, 52, MODE_SENKOUSPANB, 1);
   double chiKouSpan = iIchimoku(sym, timeframe, 9, 26, 52, MODE_CHIKOUSPAN, 27);
   double senKouSpanAFuture = iIchimoku(sym, timeframe, 9, 26, 52, MODE_SENKOUSPANA, -25);
   double senKouSpanBFuture = iIchimoku(sym, timeframe, 9, 26, 52, MODE_SENKOUSPANB, -25);
   double senKouSpanAPast = iIchimoku(sym, timeframe, 9, 26, 52, MODE_SENKOUSPANA, 27);
   double senKouSpanBPast = iIchimoku(sym, timeframe, 9, 26, 52, MODE_SENKOUSPANB, 27);
   
   double openPrice = iOpen(sym, timeframe, 1);
   double closePrice = iClose(sym, timeframe, 1);
   
   if (
      senKouSpanAFuture > senKouSpanBFuture
   ) {
      tradeType = OP_BUY;
   } else if (
      senKouSpanAFuture < senKouSpanBFuture
   ) {
      tradeType = OP_SELL;
   }
   
   return (tradeType);
}

void checkIchimokuAndCandleX5(string sym)
{
   double tenKanSen = iIchimoku(sym, timeframe, 45, 130, 260, MODE_TENKANSEN, 1);
   double kiJunSen = iIchimoku(sym, timeframe, 45, 130, 260, MODE_KIJUNSEN, 1);
   double senKouSpanA = iIchimoku(sym, timeframe, 45, 130, 260, MODE_SENKOUSPANA, 1);
   double senKouSpanB = iIchimoku(sym, timeframe, 45, 130, 260, MODE_SENKOUSPANB, 1);
   double chiKouSpan = iIchimoku(sym, timeframe, 45, 130, 260, MODE_CHIKOUSPAN, 132);
   //double senKouSpanAFuture = iIchimoku(sym, timeframe, 45, 130, 260, MODE_SENKOUSPANA, -129);
   //double senKouSpanBFuture = iIchimoku(sym, timeframe, 45, 130, 260, MODE_SENKOUSPANB, -129);
   double senKouSpanAPast = iIchimoku(sym, timeframe, 45, 130, 260, MODE_SENKOUSPANA, 132);
   double senKouSpanBPast = iIchimoku(sym, timeframe, 45, 130, 260, MODE_SENKOUSPANB, 132);
   
   double senKouSpanAFuture = iIchimoku(sym, timeframe, 9, 26, 52, MODE_SENKOUSPANA, -25);
   double senKouSpanBFuture = iIchimoku(sym, timeframe, 9, 26, 52, MODE_SENKOUSPANB, -25);
   
   double openPrice = iOpen(sym, timeframe, 1);
   double closePrice = iClose(sym, timeframe, 1);
   /*
   if (
      senKouSpanAFuture > senKouSpanBFuture
   ) {
      tradeType = OP_BUY;
   } else if (
      senKouSpanAFuture < senKouSpanBFuture
   ) {
      tradeType = OP_SELL;
   }   
   */
   //Alert("senKouSpanA: " + senKouSpanA + " senKouSpanB: " + senKouSpanB + " closePrice: " + closePrice);
   if ((closePrice > senKouSpanA && closePrice < senKouSpanB)
      || (closePrice < senKouSpanA && closePrice > senKouSpanB)
   ) {
      
      forceStopTradeType = -1;
   }
}

int checkStockastic(string sym)
{
   int tradeType = -1;

   double k = iStochastic(sym, timeframe, 5, 3, 3, MODE_SMA, 0, MODE_MAIN, 1);
   double d = iStochastic(sym, timeframe, 5, 3, 3, MODE_SMA, 0, MODE_SIGNAL, 1); 
   
   k = NormalizeDouble(k, MarketInfo(sym, MODE_DIGITS));
   d = NormalizeDouble(d, MarketInfo(sym, MODE_DIGITS));
   
   if(k > 80 && d > 80) {
      tradeType = OP_BUY;
   } else if (k < 30 && d < 30) {
      tradeType = OP_SELL;
   }
   
   return tradeType;
}

int checkADX(string sym)
{
   int tradeType = -1;
   
   double adx = iADX(sym, timeframe, 10, PRICE_HIGH, MODE_MAIN, 1);
   double plusDi = iADX(sym, timeframe, 10, PRICE_HIGH, MODE_PLUSDI, 1);
   double minusDi = iADX(sym, timeframe, 10, PRICE_HIGH, MODE_MINUSDI, 1);
   
   adx = NormalizeDouble(adx, MarketInfo(sym, MODE_DIGITS));
   plusDi = NormalizeDouble(plusDi, MarketInfo(sym, MODE_DIGITS));
   minusDi = NormalizeDouble(minusDi, MarketInfo(sym, MODE_DIGITS));
   
   if(adx > 30 && plusDi > minusDi) {
      tradeType = OP_BUY;
   } else if (adx > 30 && plusDi < minusDi) {
      tradeType = OP_SELL;
   }
   
   return tradeType;
}

int checkRSI(string sym)
{
   int tradeType = -1;

   double rsi = iRSI(sym, timeframe, 7, PRICE_CLOSE, 1);
      
   rsi = NormalizeDouble(rsi, MarketInfo(sym, MODE_DIGITS));
   
   if(rsi > 70) {
      tradeType = OP_BUY;
   } else if (rsi < 30) {
      tradeType = OP_SELL;
   }
   
   return tradeType;
}

int checkMACD(string sym)
{
   int tradeType = -1;
   double main = iMACD(NULL,0,12,26,9,PRICE_CLOSE,MODE_MAIN,1);
   double signal = iMACD(NULL,0,12,26,9,PRICE_CLOSE,MODE_SIGNAL,1);
   
   if(main > 0 && signal > 0) {
      tradeType = OP_BUY;
   } else if (main < 0 && signal < 0) {
      tradeType = OP_SELL;
   }
   
   return tradeType;
}

int checkCciWoodieArrowsOscillator(string sym)
{
   int tradeType = -1;
   double upper = iCustom(sym, timeframe, cciWoodieArrowsOscillator, 0, 1);
   double lower = iCustom(sym, timeframe, cciWoodieArrowsOscillator, 1, 1);   
      
   if (upper > 0 && upper < 999999) {
      tradeType = OP_BUY;
   } else if (lower < 0 && lower > -999999) {
      tradeType = OP_SELL;
   } 
   
   return tradeType;
}

double getSLByPips(string sym, int tradeType, double entry, double SLpoints)
{
   double tmpSL = 0;   
   if(tradeType == OP_BUY) {      
     tmpSL = entry - SLpoints * MarketInfo(sym, MODE_POINT);
   } else if(tradeType == OP_SELL) { 
     tmpSL = entry + SLpoints * MarketInfo(sym, MODE_POINT);
   }
   
   return (tmpSL);
}

bool checkMA(string sym, int tradeType)
{
   bool result = false;
   
   double lower2 = iCustom(sym, timeframe, ChandelierExit,7,0,9,3, 0, 2);
   double upper2 = iCustom(sym, timeframe, ChandelierExit,7,0,9,3, 1, 2);
   
   if (tradeType == OP_BUY && upper2 > 0 && upper2 < 99999 && checkCrossOverMAAndCandle(sym, tradeType)) {
      result = true;
   } else if (tradeType == OP_SELL && lower2 > 0 && lower2 < 99999 && checkCrossOverMAAndCandle(sym, tradeType)) {
      result = true;
   }
   
   return result;
}

bool checkCrossOverMAAndCandle(string sym, int tradeType)
{
   bool check = false;
   double openPrice = iOpen(sym, timeframe, 1);
   double closePrice = iClose(sym, timeframe, 1);
   
   double ma50 = iMA(sym,timeframe,50,0,MODE_EMA,PRICE_CLOSE,1);
   double ma200 = iMA(sym,timeframe,200,0,MODE_EMA,PRICE_CLOSE,1);
   
   double tmpOpenPrice = 0;
   double tmpClosePrice = 0;
   double tmpMa50 = 0;
   double tmpMa200 = 0;
   
   for(int i = 1; i <= 10; i++) {
      tmpOpenPrice = iOpen(sym, timeframe, i);
      
      if (tradeType == OP_BUY && closePrice > ma50 && tmpOpenPrice < ma50) {
         check = true;
         break;
      }
      
      if (tradeType == OP_BUY && closePrice > ma200 && closePrice < ma50 && tmpOpenPrice < ma200) {
         check = true;
         break;
      }
      
      if (tradeType == OP_SELL && closePrice < ma50 && tmpOpenPrice > ma50) {
         check = true;
         break;
      }
      
      if (tradeType == OP_SELL && closePrice < ma200 && closePrice > ma50 && tmpOpenPrice > ma200) {
         check = true;
         break;
      }
   } 
   
   return check; 
}
bool checkCrossOverMA(string sym, int tradeType)
{
   bool check = false;

   
   double ma50 = iMA(sym,timeframe,50,0,MODE_EMA,PRICE_CLOSE,1);
   double ma200 = iMA(sym,timeframe,200,0,MODE_EMA,PRICE_CLOSE,1);
   double ma502 = iMA(sym,timeframe,50,0,MODE_EMA,PRICE_CLOSE,2);
   double ma2002 = iMA(sym,timeframe,200,0,MODE_EMA,PRICE_CLOSE,2);
   
   if (tradeType == OP_BUY && ma50 > ma200 && ma502 < ma2002) {
      check = true;
   } else if (tradeType == OP_SELL && ma50 < ma200 && ma502 > ma2002) {
      check = true;
   }
   
   return check; 
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
   Alert(value);
   
   upper = NormalizeDouble(upper, MarketInfo(sym, MODE_DIGITS));
   lower = NormalizeDouble(lower, MarketInfo(sym, MODE_DIGITS));
   upper2 = NormalizeDouble(upper2, MarketInfo(sym, MODE_DIGITS));
   lower2 = NormalizeDouble(lower2, MarketInfo(sym, MODE_DIGITS));
   value = NormalizeDouble(value, MarketInfo(sym, MODE_DIGITS));
   //Alert("upper:" + upper + " lower: " + lower);
      
   if (value > 0) {
      tradeType = OP_BUY;
   } else if (value < 0) {
      tradeType = OP_SELL;
   } 
   
   return tradeType;
}

int getLastTradeType(string sym)
{
   int tradeType = -1;
   
   if (OrderSelect(0, SELECT_BY_POS, MODE_TRADES)) {
      tradeType = OrderType();
   }
   
   return tradeType;
}

void useHedge(string sym)
{
   datetime lastTime  = 0;
   int hedgeType = -1;
   double hedgeEntry;
   int lastTradeType = -1;
   double lastEntry;
   double lastLot;
   int lastTicket;
   double allowStop = true;
   int closeType = -1;
   double SL = 0;
   double TP = 0;
   
   if (OrdersTotal() == 0) {
      return;
   }
   
   if (OrdersTotal() >= removeHedge) {
      setRemoveHedge(1);
   }
   
   for(int i = OrdersTotal() - 1; i >= 0; i--) {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES) && OrderMagicNumber() == magic) {         
         if(OrderType() == OP_BUY && OrderOpenTime() > lastTime) {
            lastTradeType = OrderType();
            lastEntry = OrderOpenPrice();
            lastLot = OrderLots();
            lastTime   = OrderOpenTime();
            lastTicket = OrderTicket();
         } else if(OrderType() == OP_SELL && OrderOpenTime() > lastTime) {
            lastTradeType = OrderType();
            lastEntry = OrderOpenPrice();
            lastLot = OrderLots();
            lastTime   = OrderOpenTime();
            lastTicket = OrderTicket();
         } else if(OrderType() == OP_BUYSTOP || OrderType() == OP_SELLSTOP) {
            allowStop = false;
         }        
      }
   }
   
   if (getRemoveHedge() == 1) {
      checkRemoveHedge(sym, lastTicket);
      return;
   }
   
   if(lastEntry && lastLot > 0 && lastTradeType >= 0 && allowStop == true) {
      if(lastTradeType == OP_BUY) {
         hedgeEntry = getSellStop();
         hedgeType = OP_SELLSTOP;
         closeType = OP_SELL;
      } else if(lastTradeType == OP_SELL) {
         hedgeEntry = getBuyStop();
         hedgeType = OP_BUYSTOP;
         closeType = OP_BUY;
      }
      
      if(hedgeType != getNextTradeStop()) {
         return;
      }

      double hedgeLot = getLotHedge(sym, hedgeType);
      //Alert("hedgeLot: " + hedgeLot);
      
      SL = lastEntry;
      if (reward != 0) {
         TP = getTP(sym, hedgeEntry, SL);
      }    
      
      if(hedgeType == OP_SELLSTOP) {
         setNextTradeStop(OP_BUYSTOP);
         setSellStopTP(TP);
      } else if(hedgeType == OP_BUYSTOP) {
         setNextTradeStop(OP_SELLSTOP);
         setBuyStopTP(TP);
      }
      
      string commentOrder = "";   
         
      int checkOrder = OrderSend(sym, hedgeType, hedgeLot, hedgeEntry, slippage, 0, 0, commentOrder, magic, 0);
      if(checkOrder < 0) {
         handleErrorHedge(sym, hedgeType, hedgeLot, hedgeEntry, commentOrder);
         Alert("Error: " + GetLastError());
      }
   }
}

void checkCancel(string sym) 
{
   for(int i = OrdersTotal() - 1; i >= 0; i--) {
      if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) {
         continue;
      }
      
      if ((OrderType() != OP_BUY && OrderType() != OP_SELL)) {
         OrderDelete(OrderTicket());
      }
   }
}

double getLotHedge(string sym, int tradeType)
{
   double totalLotBuy = 0;
   double totalLotSell = 0;   
   double lots = 0;
   
   for(int i = OrdersTotal() - 1; i >= 0; i--) {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES) && OrderMagicNumber() == magic) {          
         if(OrderType() == OP_BUY) {
            totalLotBuy = totalLotBuy + OrderLots();
         } else if(OrderType() == OP_SELL) {
            totalLotSell = totalLotSell + OrderLots();
         }       
      }
   }
   
   if (tradeType == OP_BUYSTOP) {
      lots = (totalLotSell * (1 + reward) - totalLotBuy * reward) / reward;
   } else if (tradeType == OP_SELLSTOP) {
      lots = (totalLotBuy * (1 + reward) - totalLotSell * reward) / reward;
   }

   return RoundUp(lots, 2);
}

double RoundUp(double val, int digit)
{
   double adjust = (val >= 0)? 0.9 : -0.9;
   return ((double)(int)(val * MathPow(10, digit) + adjust)) / MathPow(10, digit);
}

void handleErrorHedge(string sym, int hedgeType, double lots, double hedgeEntry, string commentOrder)
{
   if (GetLastError() != 130) {
      return;
   }
   double tmpHedgeEntry = -1;
   int tmpHedgeType = -1;
   if(hedgeType == OP_BUYSTOP) {
      tmpHedgeEntry = MarketInfo(sym, MODE_ASK);
      tmpHedgeType = OP_BUY;
   } else if(hedgeType == OP_SELLSTOP) {
      tmpHedgeEntry = MarketInfo(sym, MODE_BID);
      tmpHedgeType = OP_SELL;
   }
   
   int checkOrder =  OrderSend(sym, tmpHedgeType, lots, tmpHedgeEntry, slippage, 0, 0, commentOrder, magic, 0, clrMagenta);
   if(checkOrder < 0) {
      closeAll(sym);
      Alert("Error: " + GetLastError());
      return;
   } 
}

void checkRemoveHedge(string sym, int lastTicket)
{
   if(!OrderSelect(lastTicket, SELECT_BY_TICKET, MODE_TRADES)) {
      return;
   }
   
   double bidPrice;
   double askPrice;
   double closePrice;
   
   if (OrderType() == OP_BUY && MarketInfo(sym, MODE_BID) <= getSellStop()
      || OrderType() == OP_SELL && MarketInfo(sym, MODE_ASK) >= getBuyStop()
   ) {
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
         Alert("Error: " + GetLastError() + " | slippage: " + slippage);            
      }      
   }
}


