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
extern string DonchianChannels = "DonchianChannels";
extern int DonchianChannelsValue = 34;
extern int DonchianChannelsTrailingStop = 10;
extern string ATRTrailStop_v3 = "ATRTrailStop_v3";
ENUM_TIMEFRAMES timeframe = PERIOD_CURRENT;
datetime tradeTime;
extern double dailyDrawdown = 0.04;
extern double limitMaxDrawdown = 8800;
string globalRandom = "_fsdp4_RichardDennis";
int magic = 921112;
extern double risk = 0.1;
extern double reward = 1;
double upperDonchianChannels;
double lowerDonchianChannels;
double upperDonchianChannelsTrailingStop;
double lowerDonchianChannelsTrailingStop;
extern bool swap = false;
double totalLots = 0;

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
//---
      string sym = Symbol();    
      drawButton(sym);
      forceCloseAll(sym);
      calculateDrawdown();
      if(tradeTime == iTime(sym, timeframe, 0)) {
         return;      
      }
      tradeTime = iTime(sym, 0, 0);
      getDonchianChannels(sym);
      trailingTP(sym);     
      checkRun(sym);
  }
//+------------------------------------------------------------------+
void checkRun(string sym)
{
   int tradeType = checkDonchianChannels(sym);
   
   if (tradeType == -1) {
      return;
   }
   
   runTrading(sym, tradeType);
}

void runTrading(string sym, int tradeType, double lot = 0) 
{
   if (Hour() < 1 || Hour() >= 23 || getAllowTrade() == 1 || OrdersTotal() >= 1) {
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

   SL = getSL(sym, tradeType);
   if (!SL) {
      return;
   }
   TP = getTP(entry, SL);
   entry = NormalizeDouble(entry, MarketInfo(sym, MODE_DIGITS));
   SL = NormalizeDouble(SL, MarketInfo(sym, MODE_DIGITS));
   TP = NormalizeDouble(TP, MarketInfo(sym, MODE_DIGITS));


   double SLpoints = MathAbs(NormalizeDouble(entry - SL, MarketInfo(sym, MODE_DIGITS)) / MarketInfo(sym, MODE_POINT));   
   
   if(lot == 0) {
      lot = getLot(sym, SLpoints);
   }
   
   if(entry && lot > 0) {
      string commentOrder = "";
      if (swap == true) {
         double tmpSL = TP;
         TP = SL;
         SL = tmpSL;
               
         if (tradeType == OP_BUY) {
            tradeType = OP_SELL;            
            entry = MarketInfo(sym, MODE_BID);
            tradeColor = clrRed;
         } else if (tradeType == OP_SELL) {
            tradeType = OP_BUY;
            entry = MarketInfo(sym, MODE_ASK);
            tradeColor = clrBlue;
         }
      }
      OrderSend(sym, tradeType, lot, entry, slippage, SL, TP, commentOrder, magic, 0, tradeColor);    
      totalLots = totalLots + lot;
   }
}

void getDonchianChannels(string sym)
{
   upperDonchianChannels = iCustom(sym, timeframe, DonchianChannels, DonchianChannelsValue, 0, 2);
   lowerDonchianChannels = iCustom(sym, timeframe, DonchianChannels, DonchianChannelsValue, 3, 2);
   
   upperDonchianChannelsTrailingStop = iCustom(sym, timeframe, DonchianChannels, DonchianChannelsTrailingStop, 0, 1);
   lowerDonchianChannelsTrailingStop = iCustom(sym, timeframe, DonchianChannels, DonchianChannelsTrailingStop, 2, 1);
   
   if (upperDonchianChannels == 0) {
      upperDonchianChannels = iCustom(sym, timeframe, DonchianChannels, DonchianChannelsTrailingStop, 0, 2);
   }
   
   if (lowerDonchianChannels == 0) {
      lowerDonchianChannels = iCustom(sym, timeframe, DonchianChannels, DonchianChannelsTrailingStop, 2, 2);
   }
}

int checkDonchianChannels(string sym)
{
   int tradeType = -1;
   double upper = upperDonchianChannels;
   double lower = lowerDonchianChannels;   
   double closed = iClose(sym,timeframe,1);
   
   if (closed > upper) {
      tradeType = OP_BUY;
   } else if (closed < lower) {
      tradeType = OP_SELL;
   } 
   
   return tradeType;
}

double getSL(string sym, int tradeType)
{  
   double SL = 0;
   if (tradeType == OP_BUY) {
      SL = iCustom(sym, timeframe, ATRTrailStop_v3, 0, 1);
   } else if (tradeType == OP_SELL) {
      SL = iCustom(sym, timeframe, ATRTrailStop_v3, 1, 1);
   }
   
   return SL;
}

double getTP(double entry, double SL)
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
    } else {
      Comment("");
    }
    return(lotSize);
}

void trailingStop(string sym)
{
   double upper = upperDonchianChannelsTrailingStop;
   double lower = lowerDonchianChannelsTrailingStop;
   double newSL = 0;      
      
	for (int i = OrdersTotal() - 1; i >= 0; i--) {
		if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
		   double orderStopLoss = OrderStopLoss();
		   if (orderStopLoss == 0 && (OrderType() == OP_BUY)) {
		      orderStopLoss = -1;
		   } else if (orderStopLoss == 0 && (OrderType() == OP_SELL)) {
		      orderStopLoss = 9999;
		   }
			if ((OrderType() == OP_BUY)) {
			   newSL = lower;			   
			   if (newSL <= orderStopLoss) {
			      return;
			   }
				OrderModify(OrderTicket(), OrderOpenPrice(), newSL, OrderTakeProfit(), OrderExpiration(), clrNONE);

			} else if ((OrderType() == OP_SELL)) {
            newSL = upper;
			   if (newSL >= orderStopLoss) {
			      return;
			   }
            OrderModify(OrderTicket(), OrderOpenPrice(),newSL, OrderTakeProfit(), OrderExpiration(), clrNONE);
			}
		}
	}
}

void trailingTP(string sym)
{
   double upper = upperDonchianChannelsTrailingStop;
   double lower = lowerDonchianChannelsTrailingStop;
   double newTP = 0;      
      
	for (int i = OrdersTotal() - 1; i >= 0; i--) {
		if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
		   double orderTP = OrderTakeProfit();
		   if (newTP == 0 && (OrderType() == OP_BUY)) {
		      newTP = 9999;
		   } else if (newTP == 0 && (OrderType() == OP_SELL)) {
		      newTP = -1;
		   }
			if ((OrderType() == OP_BUY)) {
			   newTP = upper;			   
			   if (newTP >= orderTP) {
			      return;
			   }
				OrderModify(OrderTicket(), OrderOpenPrice(), OrderStopLoss(), newTP, OrderExpiration(), clrNONE);

			} else if ((OrderType() == OP_SELL)) {            
            newTP = lower;		
			   if (newTP <= orderTP) {
			      return;
			   }
            OrderModify(OrderTicket(), OrderOpenPrice(),OrderStopLoss(), newTP, OrderExpiration(), clrNONE);
			}
		}
	}
}

double NormPrice(double Price) {
	return NormalizeDouble(Price, Digits);
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

void resetGlobal()
{
   setCheckDayDrawdown();  
   setCheckMaxDrawdown(); 
   setLimitDayDrawdown();
   setAllowTrade();
}

void forceCloseAll(string sym, int force = false)
{
   int orderTotal = OrdersTotal();
   double accountProfit = AccountProfit();
   if (AccountEquity() <= getLimitDayDrawdown()

   ) {
      closeAll(sym);
      setAllowTrade(1);    
   }   
}

void closeAll(string sym)
{
   double closePrice;
   double bidPrice = MarketInfo(sym, MODE_BID);
   double askPrice = MarketInfo(sym, MODE_ASK);
   int orderTotal = OrdersTotal();

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



