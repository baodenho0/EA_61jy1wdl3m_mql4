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
extern ENUM_TIMEFRAMES timeframe = PERIOD_D1;
int slippage = 1;
datetime tradeTime;
extern double risk = 0.5; // risk (0.5%)
double reward = 0; // reward (3%)
extern double dailyDrawdown = 0.03;
extern double limitMaxDrawdown = 8800;
string globalRandom = "_j7a2zw4_BreakoutCandle";
extern int SLpoints = 50;
int TPpoints = 0;
int TPprice = 9999999;
int forceStopTradeType = -1;
extern int trailingPoints = 50;
int arrCountForceCloseAll[];
double breakEven = 99999;


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
      trailingStop(trailingPoints);
      forceCloseAll(sym);
      drawButton(sym);
      calculateDrawdown();      
      
      if(tradeTime != iTime(sym, timeframe, 0)) {   
           
         checkCancel(sym);      
         checkRun(sym);  
                
         tradeTime = iTime(sym, timeframe, 0);
      }
  }
//+------------------------------------------------------------------+

void checkRun(string sym)
{
   int tradeType = -1;
   int closeType = -1;
   int lastTradeType = -1;
   
   double hight = iHigh(sym,timeframe,1) + (10 * MarketInfo(sym, MODE_POINT));
   double low = iLow(sym,timeframe,1) - (10 * MarketInfo(sym, MODE_POINT));
   
   runTrading(sym, OP_BUYSTOP, hight);
   runTrading(sym, OP_SELLSTOP, low);
}

void runTrading(string sym, int tradeType, double entry = 0, double lot = 0) 
{
   if (/*Hour() <= 1 || Hour() >= 23 ||*/ 
         getAllowTrade() == 1 
   ) {
         return;
   }
      
   color tradeColor = clrBlue;
   double SL = 0;
   double TP = 0;
   
   if(tradeType == OP_BUY) {
      entry = MarketInfo(sym, MODE_ASK);
      tradeColor = clrBlue;
   } else if(tradeType == OP_SELL) {
      entry = MarketInfo(sym, MODE_BID);
      tradeColor = clrRed;
   }   

   if (SLpoints != 0) {
      SL = getSLByPips(sym, tradeType, entry);
      SL = NormalizeDouble(SL, MarketInfo(sym, MODE_DIGITS));
   }
   
   if (TPpoints != 0) {
      TP = getTPByPips(sym, tradeType, entry);    
      TP = NormalizeDouble(TP, MarketInfo(sym, MODE_DIGITS));
   }   
   
   entry = NormalizeDouble(entry, MarketInfo(sym, MODE_DIGITS));
   
   if(lot == 0) {
      double tmpSLpoints = MathAbs(NormalizeDouble(entry - SL, MarketInfo(sym, MODE_DIGITS)) / MarketInfo(sym, MODE_POINT));
      lot = getLot(sym, tmpSLpoints);
   }
   
   if(entry && lot > 0) {
      string commentOrder = "";

      int ticket = OrderSend(sym, tradeType, lot, entry, slippage, SL, TP, commentOrder, magic, 0, tradeColor);   
      if (ticket >= 0) {
         if (tradeType == OP_BUYSTOP) {
            setAllowBuyStop(1);
         } else if (tradeType == OP_SELLSTOP) {
            setAllowSellStop(1);
         }
      }   
   }
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
    } else {
      Comment("");
    }
    return(lotSize);
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
   
}

void drawButton(string sym)
{
   long currentChartId = ChartID();  
   
   double spread = MarketInfo(sym, MODE_SPREAD);
   
   ObjectCreate(currentChartId, "totalLots", OBJ_LABEL, 0, 0 ,0);
   ObjectSet("totalLots", OBJPROP_CORNER, CORNER_RIGHT_UPPER);
   ObjectSet("totalLots", OBJPROP_XDISTANCE, 50);
   ObjectSet("totalLots", OBJPROP_YDISTANCE, 120);
   ObjectSetText("totalLots", "Lots: " + getTotalLot(), 15, "Impact", Red);
   
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
   if ((Hour() == 00 || getLimitDayDrawdown() == 0) && getCheckResetGlobal() != Day()) {
      resetGlobal();
      setCheckResetGlobal(Day());
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

int getAllowBuyStop()
{
   return GlobalVariableGet("AllowBuyStop" + globalRandom);
}

void setAllowBuyStop(int value = 0)
{
   GlobalVariableSet("AllowBuyStop" + globalRandom, value);
}

int getAllowSellStop()
{
   return GlobalVariableGet("AllowSellStop" + globalRandom);
}

void setAllowSellStop(int value = 0)
{
   GlobalVariableSet("AllowSellStop" + globalRandom, value);
}

int getCountConsecutiveWins()
{
   return GlobalVariableGet("CountConsecutiveWins" + globalRandom);
}

void setCountConsecutiveWins(int value = 0)
{
   GlobalVariableSet("CountConsecutiveWins" + globalRandom, value);
}

int getCheckResetGlobal()
{
   return GlobalVariableGet("CheckResetGlobal" + globalRandom);
}

void setCheckResetGlobal(int value = 0)
{
   GlobalVariableSet("CheckResetGlobal" + globalRandom, value);
}

void resetGlobal()
{
   setCheckDayDrawdown();  
   setCheckMaxDrawdown(); 
   setLimitDayDrawdown();
   setAllowTrade();
   setCountConsecutiveWins();
   setAllowBuyStop();
   setAllowSellStop();
   setCheckResetGlobal();
}

void closeAll(string sym)
{
   double closePrice;
   double bidPrice = MarketInfo(sym, MODE_BID);
   double askPrice = MarketInfo(sym, MODE_ASK);
   int orderTotal = OrdersTotal();
   
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
   if (
      AccountEquity() <= getLimitDayDrawdown()
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
   if(tradeType == OP_BUY || tradeType == OP_BUYSTOP) {      
     tmpSL = entry - SLpoints * MarketInfo(sym, MODE_POINT);
   } else if(tradeType == OP_SELL || tradeType == OP_SELLSTOP) { 
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
			if (OrderType() == OP_BUY) {			   
			   if (NormPrice(Bid - TrailingOffsetPoints * Point) <= orderStopLoss) {
			      return;
			   }
			   Alert("trli BUY: " + NormPrice(Bid - TrailingOffsetPoints * Point));
				OrderModify(OrderTicket(), OrderOpenPrice(), NormPrice(Bid - TrailingOffsetPoints * Point), OrderTakeProfit(), OrderExpiration(), clrNONE);

			} else if (OrderType() == OP_SELL) {			   
            if (NormPrice(Ask + TrailingOffsetPoints * Point) >= orderStopLoss) {
			      return;
			   }
			   Alert("trli SELL: " + NormPrice(Ask + TrailingOffsetPoints * Point));
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
   double lastEntry = getLastEntry(sym, tradeType); //Alert("entry: " + entry + " lastEntry: " +lastEntry);
   
   if (lastEntry != 0 && tradeType == OP_BUY && entry > lastEntry) {
      result = false;
   } else if (lastEntry != 0 && tradeType == OP_SELL && entry < lastEntry) {
      result = false;
   }
    
   return result;
}

void checkCancel(string sym) 
{
   for(int i = OrdersTotal() - 1; i >= 0; i--) {
      if(!OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) {
         continue;
      }
      
      string strOrderOpenTime = TimeToStr(OrderOpenTime(),TIME_DATE);
      string strTimeCurrent = TimeToStr(TimeCurrent(),TIME_DATE);
      //Alert("strOrderOpenTime: " + strOrderOpenTime + " strTimeCurrent: " + strTimeCurrent );
      if ((OrderType() != OP_BUY && OrderType() != OP_SELL) /*&& strOrderOpenTime != strTimeCurrent*/) {
         OrderDelete(OrderTicket());
      }
   }
}

double getTotalLot()
{
   if (!IsTesting()) {
      return 0;
   }
   double totalLots = 0;
   int i,hstTotal=OrdersHistoryTotal();
   for(i=0;i<hstTotal;i++) {
      if(OrderSelect(i,SELECT_BY_POS,MODE_HISTORY)) {
         totalLots = totalLots + OrderLots();
      }     
   }
   
   return totalLots;
}



