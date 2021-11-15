//+------------------------------------------------------------------+
//|                                           BotSemiAutomaticV1.mq4 |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

string comment;
datetime tradeTime;
bool allowTrade = true;
int magic = 221100;
ENUM_TIMEFRAMES timeframe = 0;
extern double risk = 1; // risk (1%)
double reward = 3; // reward (3%)
double breakEven = 99999;
int minSLPoints = 50;
int maxSLPoints = 150;
double maxSpreadPoints = 30;
//extern bool combineMartingale = true;
string ASCTrendName = "ASCTrend1i-Alert";
//double currentLossTrade = 0; //v1.1 change global 
//int countCurrentLossTrade = 0; //v1.1 change global 
//int lastASCTrend = -1;
bool checkHedging = false;
//double buyStop = -1; //v1.1 change global 
//double sellStop = -1; //v1.1 change global 
//int nextTradeStop = -1; //v1.1 change global 
string SupDem = "SupDem";
string globalRandom = "_j7e5zwqfp4_AutoSL"; //v1.1 add
bool drawTPLine = true;
int slippage = 0;
bool drawSLLine = true;
int totalOrderBreakeven = 3;
string sparamBtnClick;
int tradeTypeGlobal;
double slGlobal;
double tpGlobal;
double entryGlobal;
double lotsGlobal;
double slPointsGlobal;

int OnInit()
  {
     

//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {  
   ChartSetInteger(0,CHART_SHOW_OBJECT_DESCR,true);
   string sym = Symbol();
   drawButton(sym);
   //checkBreakEven(sym);
   
   if(lotsGlobal > 0) {
      checkDragObj(sym);
   }
  }
//+------------------------------------------------------------------+


void runTrading(string sym, int tradeType, double entry, double SL, double TP) 
{   
   double lots = lotsGlobal;
   
   if(entry && SL && TP && lots > 0) {
      string commentOrder = NULL;
      int check = OrderSend(sym, tradeType, lots, entry, slippage, SL, TP, commentOrder, magic, 0, clrRed);
      if(check >= 0) {
         Alert("OK");
      }
      
      removeSetup();
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
      
    return(lotSize);
}

double getSL(string sym)
{
   double sl = ObjectGetDouble(0, "visualSl", OBJPROP_PRICE,0);
   return NormalizeDouble(sl, MarketInfo(sym, MODE_DIGITS));
}

double getSLByPips(string sym, int tradeType, double entry)
{
   double SL = 0;
   double spread = MarketInfo(sym, MODE_SPREAD);
   if(spread > maxSpreadPoints) {
      Alert("Spread: " + spread);
      return 0;
   }
   
   if(tradeType == OP_BUY) {      
     SL = entry - 350 * MarketInfo(sym, MODE_POINT);
   } else if(tradeType == OP_SELL) { 
     SL = entry + 350 * MarketInfo(sym, MODE_POINT);
   }
   
   return (SL);
}

double getTP(string sym)
{
   double tp = ObjectGetDouble(0, "visualTp", OBJPROP_PRICE,0);
   return NormalizeDouble(tp, MarketInfo(sym, MODE_DIGITS));
}

double getLastHistory(string sym)
{
   double lastProfit;
   double lastLotSize;
   int lastType;
   datetime lastTime;
   
   for(int i = 0; i <= OrdersHistoryTotal() - 1; i++) {
      if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY) == False 
      || OrderSymbol() != sym
      || OrderMagicNumber() != magic
      || OrderType() > 1
      ) {
         continue;
      }
      
      if(OrderCloseTime() > lastTime && OrderProfit() != 0) {
         lastTime = OrderCloseTime();
         lastProfit = OrderProfit();
         lastLotSize = OrderLots();
         lastType = OrderType();
      }
   }
   
   return (lastProfit);
}

double getLastTrading(string sym)
{
   double lot = 0;

   if(OrderSelect(OrdersTotal() - 1, SELECT_BY_POS, MODE_TRADES) 
      && OrderSymbol() == sym
      && OrderMagicNumber() == magic
      ) {
         lot = OrderLots();
      }
   
   return (lot);
}

void checkBreakEven(string sym)
{   
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES) && OrderMagicNumber() == magic && (MathAbs(OrderOpenPrice() - OrderStopLoss() != 0))) {
         if(MathAbs(MarketInfo(sym, MODE_BID) - OrderOpenPrice()) > (MathAbs(OrderOpenPrice() - OrderStopLoss()) * breakEven)) {
            bool result = OrderModify(OrderTicket(), OrderOpenPrice(), OrderOpenPrice(), OrderTakeProfit(), 0, CLR_NONE);
            if(result) {
              Alert("BreakEven: " + OrderTicket());
            }
         }
      }
   }
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
   double hightPrice = iHigh(sym, timeframe, 1);
   double lowPrice = iLow(sym, timeframe, 1);
   
   double openPrice2 = iOpen(sym, timeframe, 2);
   double closePrice2 = iClose(sym, timeframe, 2);
   double hightPrice2 = iHigh(sym, timeframe, 2);
   double lowPrice2 = iLow(sym, timeframe, 2);
   
   tenKanSen = NormalizeDouble(tenKanSen, MarketInfo(sym, MODE_DIGITS));
   kiJunSen = NormalizeDouble(kiJunSen, MarketInfo(sym, MODE_DIGITS));
   senKouSpanA = NormalizeDouble(senKouSpanA, MarketInfo(sym, MODE_DIGITS));
   senKouSpanB = NormalizeDouble(senKouSpanB, MarketInfo(sym, MODE_DIGITS));
   chiKouSpan = NormalizeDouble(chiKouSpan, MarketInfo(sym, MODE_DIGITS));
   senKouSpanAFuture = NormalizeDouble(senKouSpanAFuture, MarketInfo(sym, MODE_DIGITS));
   senKouSpanBFuture = NormalizeDouble(senKouSpanBFuture, MarketInfo(sym, MODE_DIGITS));
   
   openPrice = NormalizeDouble(openPrice, MarketInfo(sym, MODE_DIGITS));
   closePrice = NormalizeDouble(closePrice, MarketInfo(sym, MODE_DIGITS));
   hightPrice = NormalizeDouble(hightPrice, MarketInfo(sym, MODE_DIGITS));
   lowPrice = NormalizeDouble(lowPrice, MarketInfo(sym, MODE_DIGITS));
   
   openPrice2 = NormalizeDouble(openPrice2, MarketInfo(sym, MODE_DIGITS));
   closePrice2 = NormalizeDouble(closePrice2, MarketInfo(sym, MODE_DIGITS));
   hightPrice2 = NormalizeDouble(hightPrice2, MarketInfo(sym, MODE_DIGITS));
   lowPrice2 = NormalizeDouble(lowPrice2, MarketInfo(sym, MODE_DIGITS));
   
   if(
      closePrice > openPrice // nen tang
      && hightPrice - closePrice < closePrice - openPrice // rau nen ngan hon than nen
      && closePrice - openPrice > closePrice2 - openPrice2
      && hightPrice - lowPrice > hightPrice2 - lowPrice2
      && closePrice > senKouSpanB // nen break kumo tang            
      && tenKanSen > kiJunSen // // duong trung binh tang      
      && senKouSpanAFuture > senKouSpanBFuture // kumo tuong lai tang      
      && ( // chikou qua khu tang
         (chiKouSpan > senKouSpanAPast && chiKouSpan > senKouSpanBPast)
         || (chiKouSpan > senKouSpanAPast && (NormalizeDouble(senKouSpanBPast - chiKouSpan, MarketInfo(sym, MODE_DIGITS)) / MarketInfo(sym, MODE_POINT)) <= 20)
         || (chiKouSpan > senKouSpanBPast && (NormalizeDouble(senKouSpanAPast - chiKouSpan, MarketInfo(sym, MODE_DIGITS)) / MarketInfo(sym, MODE_POINT)) <= 20)
      )
   ) {
      // kiem tra kumo hien tai
      if(senKouSpanA > senKouSpanB 
         && (senKouSpanA > lowPrice
         || (senKouSpanA <= lowPrice
         && (NormalizeDouble(lowPrice - senKouSpanA, MarketInfo(sym, MODE_DIGITS)) / MarketInfo(sym, MODE_POINT)) <= 20))
      ) {
         tradeType = OP_BUY;
      } else if(senKouSpanB > senKouSpanA
         && (senKouSpanB > lowPrice
         || (senKouSpanB <= lowPrice
         && (NormalizeDouble(lowPrice - senKouSpanB, MarketInfo(sym, MODE_DIGITS)) / MarketInfo(sym, MODE_POINT)) <= 20))
      ) {
         tradeType = OP_BUY;
      }  
   } else if(
      closePrice < openPrice // nen giam
      && closePrice - lowPrice < openPrice - closePrice // rau nen ngan hon than nen
      && openPrice2 - closePrice2 < openPrice - closePrice
      && hightPrice2 - lowPrice2 < hightPrice - lowPrice
      && closePrice < senKouSpanB // nen break kumo giam 
      && tenKanSen < kiJunSen // // duong trung binh giam
      && senKouSpanAFuture < senKouSpanBFuture // kumo tuong lai giam
      && ( // chikou qua khu giam
         (chiKouSpan < senKouSpanAPast && chiKouSpan < senKouSpanBPast)
         || (chiKouSpan < senKouSpanAPast && (NormalizeDouble(chiKouSpan - senKouSpanBPast, MarketInfo(sym, MODE_DIGITS)) / MarketInfo(sym, MODE_POINT)) <= 20)
         || (chiKouSpan < senKouSpanBPast && (NormalizeDouble(chiKouSpan - senKouSpanAPast, MarketInfo(sym, MODE_DIGITS)) / MarketInfo(sym, MODE_POINT)) <= 20)
      )
   ) {
      // kiem tra kumo hien tai
      if(senKouSpanA < senKouSpanB
         && (senKouSpanA < hightPrice
         || (senKouSpanA >= hightPrice
         && (NormalizeDouble(senKouSpanA - hightPrice, MarketInfo(sym, MODE_DIGITS)) / MarketInfo(sym, MODE_POINT)) <= 20))
      ) {
         tradeType = OP_SELL;
      } else if(senKouSpanB < senKouSpanA
         && (senKouSpanB < hightPrice
         || (senKouSpanB >= hightPrice
         && (NormalizeDouble(senKouSpanB - hightPrice, MarketInfo(sym, MODE_DIGITS)) / MarketInfo(sym, MODE_POINT)) <= 20))
      ) {
         tradeType = OP_SELL;
      }  
   }
   /*
   Alert("chiKouSpan: " + chiKouSpan  + " - " 
   + "senKouSpanAPast: " + senKouSpanAPast + " - " 
   + "senKouSpanBPast: " + senKouSpanBPast + " | " 
   + "openPrice: " + openPrice + " - " 
   + "closePrice: " + closePrice + " - " 
   + "lowPrice: " + lowPrice + " - " 
   + "hightPrice: " + hightPrice + " | " 
   + "kiJunSen: " + kiJunSen + " - " 
   + "tenKanSen: " + tenKanSen + " | " 
   + "senKouSpanA: " + senKouSpanA + " - " 
   + "senKouSpanB: " + senKouSpanB + " | " 
   + "senKouSpanAFuture: " + senKouSpanAFuture + " - " 
   + "senKouSpanBFuture: " + senKouSpanBFuture
   );
   */
   
   return (tradeType);
}

int checkStockastic(string sym)
{
   int tradeType = -1;

   double k = iStochastic(sym, timeframe, 5, 3, 3, MODE_SMA, 0, MODE_MAIN, 1);
   double d = iStochastic(sym, timeframe, 5, 3, 3, MODE_SMA, 0, MODE_SIGNAL, 1); 
   
   k = NormalizeDouble(k, MarketInfo(sym, MODE_DIGITS));
   d = NormalizeDouble(d, MarketInfo(sym, MODE_DIGITS));
   
   if(k > d) {
      tradeType = OP_BUY;
   } else if (k < d) {
      tradeType = OP_SELL;
   }
   
   Alert("k: " +  k + " - d: " + d);
   
   return tradeType;
}

void closeAll(string sym)
{
   double closePrice;
   double bidPrice = MarketInfo(sym, MODE_BID);
   double askPrice = MarketInfo(sym, MODE_ASK);
   int orderTotal = OrdersTotal();
   
   while(true) {
       if(OrderSelect(0, SELECT_BY_POS, MODE_TRADES) && OrderMagicNumber() == magic) {
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

   resetGlobal();
}

int checkCandle(string sym)
{
   int tradeType = -1; 
   
   double openPrice = iOpen(sym, timeframe, 1);
   double closePrice = iClose(sym, timeframe, 1);
   double hightPrice = iHigh(sym, timeframe, 1);
   double lowPrice = iLow(sym, timeframe, 1);
   
   double openPrice2 = iOpen(sym, timeframe, 2);
   double closePrice2 = iClose(sym, timeframe, 2);
   double hightPrice2 = iHigh(sym, timeframe, 2);
   double lowPrice2 = iLow(sym, timeframe, 2);
   
   openPrice = NormalizeDouble(openPrice, MarketInfo(sym, MODE_DIGITS));
   closePrice = NormalizeDouble(closePrice, MarketInfo(sym, MODE_DIGITS));
   hightPrice = NormalizeDouble(hightPrice, MarketInfo(sym, MODE_DIGITS));
   lowPrice = NormalizeDouble(lowPrice, MarketInfo(sym, MODE_DIGITS));
   
   openPrice2 = NormalizeDouble(openPrice2, MarketInfo(sym, MODE_DIGITS));
   closePrice2 = NormalizeDouble(closePrice2, MarketInfo(sym, MODE_DIGITS));
   hightPrice2 = NormalizeDouble(hightPrice2, MarketInfo(sym, MODE_DIGITS));
   lowPrice2 = NormalizeDouble(lowPrice2, MarketInfo(sym, MODE_DIGITS));
   // TODO kiem tra 3 nen
   /*
   double a =(NormalizeDouble(MathAbs(openPrice - closePrice), MarketInfo(sym, MODE_DIGITS)) / MarketInfo(sym, MODE_POINT));
   Alert(a);
   if((NormalizeDouble(MathAbs(openPrice - closePrice), MarketInfo(sym, MODE_DIGITS)) / MarketInfo(sym, MODE_POINT)) <= 10) {
      return (tradeType);
   }
   */
   if(
      closePrice > openPrice // nen tang
      && MathAbs(hightPrice - closePrice) < MathAbs(closePrice - openPrice) // rau nen ngan hon than nen
      && MathAbs(closePrice - openPrice) > MathAbs(closePrice2 - openPrice2)
      // && hightPrice - lowPrice > hightPrice2 - lowPrice2
      ) {
      tradeType = OP_BUY;
   } else if(
      closePrice < openPrice // nen giam
      && MathAbs(closePrice - lowPrice) < MathAbs(openPrice - closePrice) // rau nen ngan hon than nen
      && MathAbs(openPrice2 - closePrice2) < MathAbs(openPrice - closePrice)
      // && hightPrice2 - lowPrice2 < hightPrice - lowPrice
   ) {
      tradeType = OP_SELL;
   }
   Alert(MathAbs(closePrice - lowPrice) + " < " + MathAbs(openPrice - closePrice));
   Alert(MathAbs(openPrice2 - closePrice2) + " < " + MathAbs(openPrice - closePrice));
   
   return (tradeType);
}

void commentReport()
{
   Comment(
   "accountProfit: " + AccountProfit() + "(" + OrdersTotal() + ")" + "\n"
   "currentLossTrade: " + getCurrentLossTrade() + "(" + getCountCurrentLossTrade() + ")" + "\n"
   );
   
}

bool checkSideway(string sym)
{
   int isSideway = false;
   double supSignal = iCustom(sym, timeframe, SupDem, 0, 1);
   double demSignal = iCustom(sym, timeframe, SupDem, 1, 1);
   
   Alert("supSignal: " + supSignal + " demSignal: " +demSignal );
   
   return isSideway;
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
   /*
   ObjectCreate(currentChartId, "accountProfit", OBJ_LABEL, 0, 0 ,0);   
   ObjectSet("accountProfit", OBJPROP_CORNER, CORNER_RIGHT_UPPER);
   ObjectSet("accountProfit", OBJPROP_XDISTANCE, 50);
   ObjectSet("accountProfit", OBJPROP_YDISTANCE, 200);
   ObjectSetText("accountProfit", "Account Profit: " + AccountProfit() + "(" + OrdersTotal() + ")" , 15, "Impact", Red);
   
   
   ObjectCreate(currentChartId, "currentLossTrade", OBJ_LABEL, 0, 0 ,0);   
   ObjectSet("currentLossTrade", OBJPROP_CORNER, CORNER_RIGHT_UPPER);
   ObjectSet("currentLossTrade", OBJPROP_XDISTANCE, 50);
   ObjectSet("currentLossTrade", OBJPROP_YDISTANCE, 240);
   ObjectSetText("currentLossTrade", "Current Loss Trade: " + getCurrentLossTrade() + "(" + getCountCurrentLossTrade() + ")", 15, "Impact", Red);
   */

   ObjectCreate(currentChartId, "MarketBtn", OBJ_BUTTON, 0, 0 ,0);   
   ObjectSetInteger(currentChartId, "MarketBtn", OBJPROP_XDISTANCE, 300);
   ObjectSetInteger(currentChartId, "MarketBtn", OBJPROP_XSIZE, 100);
   ObjectSetInteger(currentChartId, "MarketBtn", OBJPROP_YDISTANCE, 200);
   ObjectSetInteger(currentChartId, "MarketBtn", OBJPROP_YSIZE, 20);
   ObjectSetInteger(currentChartId, "MarketBtn", OBJPROP_CORNER, 3);
   ObjectSetInteger(currentChartId, "MarketBtn", OBJPROP_BGCOLOR, clrBlue);
   ObjectSetString(currentChartId, "MarketBtn", OBJPROP_TEXT, "Market");

   ObjectCreate(currentChartId, "PendingBtn", OBJ_BUTTON, 0, 0 ,0);   
   ObjectSetInteger(currentChartId, "PendingBtn", OBJPROP_XDISTANCE, 150);
   ObjectSetInteger(currentChartId, "PendingBtn", OBJPROP_XSIZE, 100);
   ObjectSetInteger(currentChartId, "PendingBtn", OBJPROP_YDISTANCE, 200);
   ObjectSetInteger(currentChartId, "PendingBtn", OBJPROP_YSIZE, 20);
   ObjectSetInteger(currentChartId, "PendingBtn", OBJPROP_CORNER, 3);
   ObjectSetString(currentChartId, "PendingBtn", OBJPROP_TEXT, "Pending");
   ObjectSetInteger(currentChartId, "PendingBtn", OBJPROP_BGCOLOR, clrRed);
   /*
   ObjectCreate(currentChartId, "CloseAllBtn", OBJ_BUTTON, 0, 0 ,0);   
   ObjectSetInteger(currentChartId, "CloseAllBtn", OBJPROP_XDISTANCE, 150);
   ObjectSetInteger(currentChartId, "CloseAllBtn", OBJPROP_XSIZE, 100);
   ObjectSetInteger(currentChartId, "CloseAllBtn", OBJPROP_YDISTANCE, 150);
   ObjectSetInteger(currentChartId, "CloseAllBtn", OBJPROP_YSIZE, 20);
   ObjectSetInteger(currentChartId, "CloseAllBtn", OBJPROP_CORNER, 3);
   ObjectSetString(currentChartId, "CloseAllBtn", OBJPROP_TEXT, "CLOSE ALL");
   ObjectSetInteger(currentChartId, "CloseAllBtn", OBJPROP_BGCOLOR, clrWhiteSmoke);   
   
   ObjectCreate(currentChartId, "resetGlobalBtn", OBJ_BUTTON, 0, 0 ,0);   
   ObjectSetInteger(currentChartId, "resetGlobalBtn", OBJPROP_XDISTANCE, 20);
   ObjectSetInteger(currentChartId, "resetGlobalBtn", OBJPROP_XSIZE, 130);
   ObjectSetInteger(currentChartId, "resetGlobalBtn", OBJPROP_YDISTANCE, 70);
   ObjectSetInteger(currentChartId, "resetGlobalBtn", OBJPROP_YSIZE, 20);
   ObjectSetInteger(currentChartId, "resetGlobalBtn", OBJPROP_CORNER, 2);
   ObjectSetString(currentChartId, "resetGlobalBtn", OBJPROP_TEXT, "RESET GLOBAL");
   ObjectSetInteger(currentChartId, "resetGlobalBtn", OBJPROP_BGCOLOR, clrRed);
   */
}

void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
   string sym = Symbol();
   if(id == CHARTEVENT_OBJECT_CLICK) {
      if(sparam == "MarketBtn" || sparam == "PendingBtn") {
         sparamBtnClick = sparam;
         showSetup(sym, sparam);
      } else if(sparam == "AcceptBtn") {
         runTrading(sym, tradeTypeGlobal, entryGlobal, slGlobal, tpGlobal);  
      } else if (sparam == "CancelBtn") {
         removeSetup();
      }
   } else if (id == CHARTEVENT_OBJECT_DRAG) {
      checkDragObj(sym);
   }
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

int getNextTradeStop()
{
   return GlobalVariableGet("nextTradeStop" + globalRandom);
}

void setNextTradeStop(int value = -1)
{
   GlobalVariableSet("nextTradeStop" + globalRandom, value);
}

void resetGlobal()
{
   setCurrentLossTrade();
   setCountCurrentLossTrade();
   setBuyStop();
   setSellStop();
   setNextTradeStop();
   
   Alert("resetGlobal()");
}

bool checkNewCandle(string sym)
{
   if(tradeTime == iTime(sym, timeframe, 0)) {
      return false;
   }
   tradeTime = iTime(sym, 0, 0);
   
   return true;
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

void showSetup(string sym, string sparam)
{
   ObjectCreate("visualTp", OBJ_HLINE , 0,Time[0], MarketInfo(sym, MODE_ASK));
   ObjectSet("visualTp", OBJPROP_STYLE, STYLE_SOLID);
   ObjectSet("visualTp", OBJPROP_COLOR, Blue);
   ObjectSet("visualTp", OBJPROP_WIDTH, 2);
   ObjectSetInteger(0,"visualTp",OBJPROP_SELECTABLE,true);
   ObjectSetInteger(0,"visualTp",OBJPROP_SELECTED,true);
   ObjectSet("visualTp", OBJPROP_CORNER, 0);
   ObjectSetText("visualTp", "          TP", 10, "Arial", clrBlack);
   
   ObjectCreate("visualSl", OBJ_HLINE , 0,Time[0], MarketInfo(sym, MODE_ASK));
   ObjectSet("visualSl", OBJPROP_STYLE, STYLE_SOLID);
   ObjectSet("visualSl", OBJPROP_COLOR, Red);
   ObjectSet("visualSl", OBJPROP_WIDTH, 2);
   ObjectSetInteger(0,"visualSl",OBJPROP_SELECTABLE,true);
   ObjectSetInteger(0,"visualSl",OBJPROP_SELECTED,true);
   ObjectSetText("visualSl", "          SL", 10, "Arial", clrBlack);
   
   if(sparam == "PendingBtn") {
      ObjectCreate("visualEntry", OBJ_HLINE , 0,Time[0], MarketInfo(sym, MODE_ASK));
      ObjectSet("visualEntry", OBJPROP_STYLE, STYLE_SOLID);
      ObjectSet("visualEntry", OBJPROP_STYLE, STYLE_SOLID);
      ObjectSet("visualEntry", OBJPROP_COLOR, Yellow);
      ObjectSet("visualEntry", OBJPROP_WIDTH, 2);
      ObjectSetInteger(0, "visualEntry",OBJPROP_SELECTABLE,true);
      ObjectSetInteger(0, "visualEntry",OBJPROP_SELECTED,true);
      ObjectSetText("visualEntry", "          Entry", 10, "Arial", clrBlack);
   } 
   
   ObjectCreate("AcceptBtn", OBJ_BUTTON, 0, 0 ,0);   
   ObjectSetInteger(0,"AcceptBtn", OBJPROP_XDISTANCE, 300);
   ObjectSetInteger(0,"AcceptBtn", OBJPROP_XSIZE, 100);
   ObjectSetInteger(0,"AcceptBtn", OBJPROP_YDISTANCE, 150);
   ObjectSetInteger(0,"AcceptBtn", OBJPROP_YSIZE, 20);
   ObjectSetInteger(0, "AcceptBtn", OBJPROP_CORNER, 3);
   ObjectSetInteger(0, "AcceptBtn", OBJPROP_BGCOLOR, clrBlue);
   ObjectSetString(0,"AcceptBtn", OBJPROP_TEXT, "Accept");

   ObjectCreate("CancelBtn", OBJ_BUTTON, 0, 0 ,0);   
   ObjectSetInteger(0, "CancelBtn", OBJPROP_XDISTANCE, 150);
   ObjectSetInteger(0, "CancelBtn", OBJPROP_XSIZE, 100);
   ObjectSetInteger(0, "CancelBtn", OBJPROP_YDISTANCE, 150);
   ObjectSetInteger(0, "CancelBtn", OBJPROP_YSIZE, 20);
   ObjectSetInteger(0, "CancelBtn", OBJPROP_CORNER, 3);
   ObjectSetString(0, "CancelBtn", OBJPROP_TEXT, "Cancel");
   ObjectSetInteger(0, "CancelBtn", OBJPROP_BGCOLOR, clrRed);  
}

void removeSetup()
{
   ObjectDelete("visualTp");
   ObjectDelete("visualSl");
   ObjectDelete("visualEntry");
   ObjectDelete("AcceptBtn");
   ObjectDelete("CancelBtn");
   ObjectDelete("infoTrade");
   
   lotsGlobal = 0;
}

double getEntry(string sym, string sparam)
{
   double entry = ObjectGetDouble(0, "visualEntry", OBJPROP_PRICE,0);
   if(sparam == "PendingBtn") {
      entry = ObjectGetDouble(0, "visualEntry", OBJPROP_PRICE,0);
      entry = NormalizeDouble(entry, MarketInfo(sym, MODE_DIGITS));
   }
   
   return entry;
}

string getTradeType(string sym)
{
   string results;
   if(tradeTypeGlobal == OP_BUY) {
      results = "BUY";
   } else if(tradeTypeGlobal == OP_SELL) {
      results = "SELL";
   } else if(tradeTypeGlobal == OP_BUYSTOP) {
      results = "BUYSTOP";
   } else if(tradeTypeGlobal == OP_BUYLIMIT) {
      results = "BUYLIMIT";
   } else if(tradeTypeGlobal == OP_SELLSTOP) {
      results = "SELLSTOP";
   } else if(tradeTypeGlobal == OP_SELLLIMIT) {
      results = "SELLLIMIT";
   }
   
   return results;
}

string getRR(string sym)
{
   if(getSLPoints(sym) <= 0) {
      return 0;
   }

   double rr =  (getTPPoints(sym) / 10) / (getSLPoints(sym) / 10);
   
   return NormalizeDouble(rr, 2);
}

string getRisk(string sym)
{
   double tickVal = MarketInfo(sym , MODE_TICKVALUE);
   double tickSize = MarketInfo(sym , MODE_TICKSIZE);
    
   double amountRisk = lotsGlobal * (slPointsGlobal * MarketInfo(sym, MODE_POINT) * tickVal / tickSize);
   return NormalizeDouble(amountRisk, 2);
}

double getSLPips(string sym)
{
   double slPips = (getSLPoints(sym) / 10);
   return NormalizeDouble(slPips, 2);
}

double getSLPoints(string sym)
{
   return MathAbs(NormalizeDouble(entryGlobal - slGlobal, MarketInfo(sym, MODE_DIGITS)) / MarketInfo(sym, MODE_POINT));
}

double getTPPoints(string sym)
{
   return MathAbs(NormalizeDouble(tpGlobal - entryGlobal, MarketInfo(sym, MODE_DIGITS)) / MarketInfo(sym, MODE_POINT));
}

void checkDragObj(string sym)
{
   ChartRedraw(0);
   
   int tradeType = - 1;
   double lots = 0;
   double entry = getEntry(sym, sparamBtnClick);
   double sl = getSL(sym);
   double tp = getTP(sym);
   double currentPrice = -1;
   
   if(tp > sl) {      
      currentPrice = MarketInfo(sym, MODE_ASK);
      if(tp > currentPrice || sparamBtnClick == "PendingBtn") {
         tradeType = OP_BUY;
      }      
   } else if(tp < sl) {      
      currentPrice = MarketInfo(sym, MODE_BID);
      if(tp < currentPrice || sparamBtnClick == "PendingBtn") {
         tradeType = OP_SELL;
      } 
   }
   
   if (sparamBtnClick == "PendingBtn") {
      if(entry > currentPrice && tradeType == OP_BUY && tp > entry) {
         tradeType = OP_BUYSTOP;
      } else if(entry > currentPrice && tradeType == OP_SELL && tp < entry) {
         tradeType = OP_SELLLIMIT;
      } else if(entry < currentPrice && tradeType == OP_BUY && tp > entry) {
         tradeType = OP_BUYLIMIT;
      } else if(entry < currentPrice && tradeType == OP_SELL && tp < entry) {
         tradeType = OP_SELLSTOP;
      }
   } else if (sparamBtnClick == "MarketBtn") {
      entry = currentPrice;      
   }   
   
   slGlobal = NormalizeDouble(sl, MarketInfo(sym, MODE_DIGITS));
   tpGlobal = NormalizeDouble(tp, MarketInfo(sym, MODE_DIGITS));
   entryGlobal = NormalizeDouble(entry, MarketInfo(sym, MODE_DIGITS));
   tradeTypeGlobal = tradeType;   
   slPointsGlobal = getSLPoints(sym);
   lotsGlobal = getLot(sym, slPointsGlobal);
   
   ObjectCreate(0, "infoTrade", OBJ_LABEL, 0, 0 ,0);   
   ObjectSet("infoTrade", OBJPROP_CORNER, CORNER_RIGHT_UPPER);
   ObjectSet("infoTrade", OBJPROP_XDISTANCE, 50);
   ObjectSet("infoTrade", OBJPROP_YDISTANCE, 200);
   ObjectSetText("infoTrade", getTradeType(sym) + " " + lotsGlobal + "lots R:R" + getRR(sym) + " SL:" + getRisk(sym) + "$ " + getSLPips(sym) + "pips", 15, "Impact", Red);
}