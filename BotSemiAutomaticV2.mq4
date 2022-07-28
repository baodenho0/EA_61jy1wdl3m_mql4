//+------------------------------------------------------------------+
//|                                           BotSemiAutomaticV1.mq4 |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.10"
#property strict
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

string comment;
datetime tradeTime;
bool allowTrade = true;
int magic = 12444;
ENUM_TIMEFRAMES timeframe = 0;
extern double risk = 0.4;
extern double reward = 0.4;
extern double SLByPips = 18;
double breakEven = 99999;
int minSLPoints = 0;
int maxSLPoints = 9999;
extern double maxSpreadPoints = 6;
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
string globalRandom = "_j7a2zwqfp4_BotSemiAutoV1"; //v1.1 add
bool drawTPLine = false;
int slippage = 0;
bool drawSLLine = false;
extern int totalOrderBreakeven = 3;
extern double ratioForceClose = 1.13;
extern double ratioMartingale = 1.8;
extern int minLengthCandle = 30;
extern int minBodyCandle = 10;

enum ENUM_HOUR
{
   h00 = 00, // 00:00
   h01 = 01, // 01:00
   h02 = 02, // 02:00
   h03 = 03, // 03:00
   h04 = 04, // 04:00
   h05 = 05, // 05:00
   h06 = 06, // 06:00
   h07 = 07, // 07:00
   h08 = 08, // 08:00
   h09 = 09, // 09:00
   h10 = 10, // 10:00
   h11 = 11, // 11:00
   h12 = 12, // 12:00
   h13 = 13, // 13:00
   h14 = 14, // 14:00
   h15 = 15, // 15:00
   h16 = 16, // 16:00
   h17 = 17, // 17:00
   h18 = 18, // 18:00
   h19 = 19, // 19:00
   h20 = 20, // 20:00
   h21 = 21, // 21:00
   h22 = 22, // 22:00
   h23 = 23, // 23:00
};

input ENUM_HOUR StartHour = h01; // Start operation hour
input ENUM_HOUR LastHour = h22; // Last operation hour

int OnInit()
  {
     if (IsTesting()) {
         resetGlobal();
     }

//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   /*
   int profitTrades = 0;
   int lossTrades = 0;
   double grossProfit = 0;
   double grossLoss = 0;
   int amLienTiep = 0;
   int tmpAmLienTiep = 0;
   int idAm = 0;
   int DuongLienTiep = 0;
   int tmpDuongLienTiep = 0;
   int idDuong = 0;
   double lots = 0;
   
   for(int i = 0; i <= OrdersHistoryTotal() - 1; i++) {
      if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY) && OrderMagicNumber() == magic) {
         if(OrderProfit() > 0) {
            profitTrades = profitTrades + 1;
            grossProfit = grossProfit + OrderProfit();
            lots = lots + OrderLots();
            
            if(OrderSelect((i + 1), SELECT_BY_POS, MODE_HISTORY) && OrderProfit() > 0) {
               tmpDuongLienTiep = tmpDuongLienTiep + 1;
            } else {
               if(tmpDuongLienTiep > DuongLienTiep) {
                  DuongLienTiep = tmpDuongLienTiep;
                  idDuong = OrderTicket();
               }
               tmpDuongLienTiep = 0;
            }            
         } else if(OrderProfit() < 0) {
            lossTrades = lossTrades + 1;
            grossLoss = grossLoss + OrderProfit();
            
            if(OrderSelect((i + 1), SELECT_BY_POS, MODE_HISTORY) && OrderProfit() < 0) {
               tmpAmLienTiep = tmpAmLienTiep + 1;
            } else {
               if(tmpAmLienTiep > amLienTiep) {
                  amLienTiep = tmpAmLienTiep;
                  idAm = OrderTicket();
               }
               tmpAmLienTiep = 0;
            }
         }
      }    
   }
   
   if(profitTrades == 0 || lossTrades == 0) {
      return;
   }
   
   double percentProfit = profitTrades * 100 / (profitTrades + lossTrades); 
   double percentloss = lossTrades * 100 / (profitTrades + lossTrades);
   
   Alert("Report: profitTrades: " + profitTrades + "(" + percentProfit + "%)" + " - grossProfit: " + grossProfit 
   + " - lossTrades: " + lossTrades + "(" + percentloss + "%)" + " - grossLoss: " + grossLoss
   + " DuongLienTiep: " + DuongLienTiep
   + " idDuong: " + idDuong
   + " AmLienTiep: " + amLienTiep
   + " idAm: " + idAm
   + " - lots: " + lots
   );
   */
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   if(AccountBalance() <= 0) {
      return;
   }
  
   string sym = Symbol();
   int tradeType = -1;
   // commentReport();
   
   drawButton(sym);  
   checkDrawTPLine(sym);   
   checkDrawSLLine(sym);
   checkBreakEven(sym);
   closeTradingByProfit(sym);
   useHedge(sym);
   forceCloseAll(sym);
   checkRun(sym);
   /*
   if(tradeTime == iTime(sym, timeframe, 0) || OrdersTotal() > 0) {
      return;
   }
   tradeTime = iTime(sym, 0, 0);   
   */
   
   /*
   for(int i = 0; i <= GlobalVariablesTotal(); i++) {
      Alert(GlobalVariableName(i));    
   } 
   */
   
  }
//+------------------------------------------------------------------+


void runTrading(string sym, int tradeType, double lot = 0) 
{
   if(OrdersTotal() > 0) {
      //Alert("Cannot trade");
      return;
   }
   /*
   if(getSecondsLeft() <= 10) {
      //Alert("secondsLeft: " + getSecondsLeft());
      return;
   }
   */

   double entry = 0;
   color tradeColor = clrBlue;

   if(tradeType == OP_BUY) {
      entry = MarketInfo(sym, MODE_ASK);
      tradeColor = clrBlue;
   } else if(tradeType == OP_SELL) {
      entry = MarketInfo(sym, MODE_BID);
      tradeColor = clrRed;
   } else {
      return;
   }   
   
   //double SL = getSL(sym, tradeType, true);
   double SL = getSLByPips(sym, tradeType, entry);
   if(!SL) {
      return;
   }
   //double SL = getSLByPips(sym, tradeType, entry);
   double TP = getTP(entry, SL);
   
   entry = NormalizeDouble(entry, MarketInfo(sym, MODE_DIGITS));
   SL = NormalizeDouble(SL, MarketInfo(sym, MODE_DIGITS));
   TP = NormalizeDouble(TP, MarketInfo(sym, MODE_DIGITS));

   double SLPoints = MathAbs(NormalizeDouble(entry - SL, MarketInfo(sym, MODE_DIGITS)) / MarketInfo(sym, MODE_POINT));
   
   if(SLPoints < minSLPoints || SLPoints > maxSLPoints) {      
      Alert("SLPoints: " + SLPoints);
      return;
   }
   
   
   if(lot == 0) {
      lot = getLot(sym, SLPoints);
   }
   
   if(entry && SL && TP && lot > 0) {
      // Alert(sym + " " + tradeType + " " + lot + " " + entry + " " + SL + " " + TP + " " + magic + " " + tradeColor);
      //string commentRoot = "SL:" + SL; 
      string commentOrder = getCommentOrder();     
      OrderSend(sym, tradeType, lot, entry, slippage, 0, 0, commentOrder, magic, 0, tradeColor);
      
      if(tradeType == OP_BUY) {
         setNextTradeStop(OP_SELLSTOP);
         setBuyStop(entry);
         setSellStop(SL);
      } else if(tradeType == OP_SELL) {
         setBuyStop(SL);
         setSellStop(entry);
         setNextTradeStop(OP_BUYSTOP);
      }
   }
}

double getLot(string sym, double SLPoints)
{
   double balance = AccountEquity();
   double lotSize ;
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

double getSL(string sym, int tradeType, bool alert = false)
{
   int candleNumber;
   double SL = 0;
   double spread = MarketInfo(sym, MODE_SPREAD);
   if(spread > maxSpreadPoints && alert == true) {
      Alert("Spread: " + spread);
      return 0;
   }
   
   if(tradeType == OP_BUY) {
      candleNumber = iLowest(sym, timeframe, MODE_LOW, 3, 1);
      SL = iLow(sym, timeframe, candleNumber) - spread * MarketInfo(sym, MODE_POINT);
   } else if(tradeType == OP_SELL) { 
      candleNumber = iHighest(sym, timeframe, MODE_HIGH, 3, 1);
      SL = iHigh(sym, timeframe, candleNumber) + spread * MarketInfo(sym, MODE_POINT);
   }
   
   return (SL);
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
     SL = entry - SLByPips * MarketInfo(sym, MODE_POINT);
   } else if(tradeType == OP_SELL) { 
     SL = entry + SLByPips * MarketInfo(sym, MODE_POINT);
   }
   
   return (SL);
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

int checkADX(string sym)
{
   int tradeType = -1;
   
   double adx = iADX(sym, timeframe, 14, PRICE_HIGH, MODE_MAIN, 1);
   double plusDi = iADX(sym, timeframe, 14, PRICE_HIGH, MODE_PLUSDI, 1);
   double minusDi = iADX(sym, timeframe, 14, PRICE_HIGH, MODE_MINUSDI, 1);
   
   adx = NormalizeDouble(adx, MarketInfo(sym, MODE_DIGITS));
   plusDi = NormalizeDouble(plusDi, MarketInfo(sym, MODE_DIGITS));
   minusDi = NormalizeDouble(minusDi, MarketInfo(sym, MODE_DIGITS));
   
   if(adx > 25 && plusDi > minusDi) {
      tradeType = OP_BUY;
   } else if (adx > 25 && plusDi < minusDi) {
      tradeType = OP_SELL;
   }
   
   return tradeType;
}

int checkRSI(string sym)
{
   int tradeType = -1;

   double rsi = iRSI(sym, timeframe, 5, PRICE_CLOSE, 1);
      
   rsi = NormalizeDouble(rsi, MarketInfo(sym, MODE_DIGITS));
   
   if(rsi > 70) {
      tradeType = OP_BUY;
   } else if (rsi < 30) {
      tradeType = OP_SELL;
   }
   
   return tradeType;
}

int checkASCTrend(string sym)
{   
   int tradeType = -1;
   double buySignal = iCustom(sym, timeframe, ASCTrendName, 1, 1);
   double sellSignal = iCustom(sym, timeframe, ASCTrendName, 0, 1);
   
   if(buySignal > 0 && buySignal < 999999) {
      tradeType = OP_BUY;
   } else if(sellSignal > 0 && sellSignal < 999999) {
      tradeType = OP_SELL;
   }
   
   return (tradeType);
}

void closeTradingByProfit(string sym)
{
   double totalProfit = 0;
   int closeType = -1;
     
   double riskAmount = AccountBalance() / 100 * risk;
   double rewardAmount = AccountBalance() / 100 * reward;
     
   if(
   AccountProfit() + getCurrentLossTrade() >= rewardAmount
   || AccountProfit() + getCurrentLossTrade() >= 0 && getCountCurrentLossTrade() >= totalOrderBreakeven
   ) {
      closeAll(sym);
      //Alert("closeTradingByProfit()");
   }
}

void closeTradingByTradeType(string sym, int tradeType)
{
   double closePrice; 
   double bidPrice;
   double askPrice;
   
   for(int i = OrdersTotal() - 1; i >= 0; i--) {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES) && OrderMagicNumber() == magic && tradeType == OrderType()) {                     
         
         double orderProfit = 0;
         while(true) {
            bidPrice = MarketInfo(sym, MODE_BID);
            askPrice = MarketInfo(sym, MODE_ASK);
         
            if(OrderType() == OP_BUY) {
               closePrice = bidPrice;
            } else if(OrderType() == OP_SELL) {
               closePrice = askPrice;
            }   
         
            orderProfit = OrderProfit() + OrderCommission();
            bool checkClose = OrderClose(OrderTicket() , OrderLots(), closePrice, slippage);
            if(OrderSelect(OrderTicket(), SELECT_BY_TICKET, MODE_HISTORY)) {
               orderProfit = OrderProfit() + OrderCommission();
            }
            if(checkClose) {
               break;
            }
            Alert("Error: " + GetLastError() + " | slippage: " + slippage);            
         }
         
         setCurrentLossTrade(getCurrentLossTrade() + orderProfit);
         setCountCurrentLossTrade(getCountCurrentLossTrade() + 1);         
      }
   }
   
   if(getCurrentLossTrade() > 0) { 
      resetGlobal();
   }
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

void useHedge(string sym)
{
   datetime lastTime  = 0;
   int hedgeType = -1;
   double hedgeEntry;
   int lastTradeType = -1;
   double lastEntry;
   double lastLot;
   double allowStop = true;
   int closeType = -1;
   
   for(int i = OrdersTotal() - 1; i >= 0; i--) {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES) && OrderMagicNumber() == magic) {         
         if(OrderType() == OP_BUY && OrderOpenTime() > lastTime) {
            lastTradeType = OrderType();
            lastEntry = OrderOpenPrice();
            lastLot = OrderLots();
            lastTime   = OrderOpenTime();
         } else if(OrderType() == OP_SELL && OrderOpenTime() > lastTime) {
            lastTradeType = OrderType();
            lastEntry = OrderOpenPrice();
            lastLot = OrderLots();
            lastTime   = OrderOpenTime();
         } else if(OrderType() == OP_BUYSTOP || OrderType() == OP_SELLSTOP) {
            allowStop = false;
         }        
      }
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
      double tmpLastLot = getLastLot();
      if (tmpLastLot) {
         lastLot = tmpLastLot;
      }
      
      double hedgeLot = lastLot * ratioMartingale;
      double volumeMax = SymbolInfoDouble(sym,SYMBOL_VOLUME_MAX);      
      if (hedgeLot > volumeMax) {
         setLastLot(hedgeLot);
      }
      
      if(lastLot == 0.01) {
         hedgeLot = 0.02;
      }      
      
      if(hedgeType == OP_SELLSTOP) {
         setNextTradeStop(OP_BUYSTOP);
      } else if(hedgeType == OP_BUYSTOP) {
         setNextTradeStop(OP_SELLSTOP);
      }      
      closeTradingByTradeType(sym, closeType);
      
      string commentOrder = getCommentOrder(); 
      int checkOrder = -1;
      
      while (hedgeLot > volumeMax) {
         checkOrder = OrderSend(sym, hedgeType, volumeMax, hedgeEntry, slippage, 0, 0, commentOrder, magic, 0, clrMagenta); 
         if(checkOrder < 0) {
            handleErrorHedge(sym, hedgeType, volumeMax, hedgeEntry, commentOrder);
         }
         hedgeLot = hedgeLot - volumeMax;              
      }
         
      checkOrder = OrderSend(sym, hedgeType, hedgeLot, hedgeEntry, slippage, 0, 0, commentOrder, magic, 0, clrMagenta);
      if(checkOrder < 0) {
         handleErrorHedge(sym, hedgeType, hedgeLot, hedgeEntry, commentOrder);
      }
      
   }
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
   /*
   ObjectCreate(currentChartId, "BuyBtn", OBJ_BUTTON, 0, 0 ,0);   
   ObjectSetInteger(currentChartId, "BuyBtn", OBJPROP_XDISTANCE, 300);
   ObjectSetInteger(currentChartId, "BuyBtn", OBJPROP_XSIZE, 100);
   ObjectSetInteger(currentChartId, "BuyBtn", OBJPROP_YDISTANCE, 200);
   ObjectSetInteger(currentChartId, "BuyBtn", OBJPROP_YSIZE, 20);
   ObjectSetInteger(currentChartId, "BuyBtn", OBJPROP_CORNER, 3);
   ObjectSetInteger(currentChartId, "BuyBtn", OBJPROP_BGCOLOR, clrBlue);
   ObjectSetString(currentChartId, "BuyBtn", OBJPROP_TEXT, "BUY");

   ObjectCreate(currentChartId, "SellBtn", OBJ_BUTTON, 0, 0 ,0);   
   ObjectSetInteger(currentChartId, "SellBtn", OBJPROP_XDISTANCE, 150);
   ObjectSetInteger(currentChartId, "SellBtn", OBJPROP_XSIZE, 100);
   ObjectSetInteger(currentChartId, "SellBtn", OBJPROP_YDISTANCE, 200);
   ObjectSetInteger(currentChartId, "SellBtn", OBJPROP_YSIZE, 20);
   ObjectSetInteger(currentChartId, "SellBtn", OBJPROP_CORNER, 3);
   ObjectSetString(currentChartId, "SellBtn", OBJPROP_TEXT, "SELL");
   ObjectSetInteger(currentChartId, "SellBtn", OBJPROP_BGCOLOR, clrRed);
   
   ObjectCreate(currentChartId, "CloseAllBtn", OBJ_BUTTON, 0, 0 ,0);   
   ObjectSetInteger(currentChartId, "CloseAllBtn", OBJPROP_XDISTANCE, 150);
   ObjectSetInteger(currentChartId, "CloseAllBtn", OBJPROP_XSIZE, 100);
   ObjectSetInteger(currentChartId, "CloseAllBtn", OBJPROP_YDISTANCE, 150);
   ObjectSetInteger(currentChartId, "CloseAllBtn", OBJPROP_YSIZE, 20);
   ObjectSetInteger(currentChartId, "CloseAllBtn", OBJPROP_CORNER, 3);
   ObjectSetString(currentChartId, "CloseAllBtn", OBJPROP_TEXT, "CLOSE ALL");
   ObjectSetInteger(currentChartId, "CloseAllBtn", OBJPROP_BGCOLOR, clrWhiteSmoke);   
   */
   ObjectCreate(currentChartId, "resetGlobalBtn", OBJ_BUTTON, 0, 0 ,0);   
   ObjectSetInteger(currentChartId, "resetGlobalBtn", OBJPROP_XDISTANCE, 20);
   ObjectSetInteger(currentChartId, "resetGlobalBtn", OBJPROP_XSIZE, 130);
   ObjectSetInteger(currentChartId, "resetGlobalBtn", OBJPROP_YDISTANCE, 70);
   ObjectSetInteger(currentChartId, "resetGlobalBtn", OBJPROP_YSIZE, 20);
   ObjectSetInteger(currentChartId, "resetGlobalBtn", OBJPROP_CORNER, 2);
   ObjectSetString(currentChartId, "resetGlobalBtn", OBJPROP_TEXT, "RESET GLOBAL");
   ObjectSetInteger(currentChartId, "resetGlobalBtn", OBJPROP_BGCOLOR, clrRed);
}

void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
   string sym = Symbol();
   if(id == CHARTEVENT_OBJECT_CLICK) {
      if(sparam == "BuyBtn") {
         runTrading(sym, OP_BUY);
      } else if (sparam == "SellBtn") {
         runTrading(sym, OP_SELL);
      } else if (sparam == "CloseAllBtn") {
         closeAll(sym);
      } else if(sparam == "resetGlobalBtn") {
         resetGlobal();
      }
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

double getLastLot()
{
   return GlobalVariableGet("lastLot" + globalRandom);
}

void setLastLot(double value = 0)
{
   GlobalVariableSet("lastLot" + globalRandom, value);
}

void resetGlobal()
{
   setCurrentLossTrade();
   setCountCurrentLossTrade();
   setBuyStop();
   setSellStop();
   setNextTradeStop();
   setLastLot();
   removeDrawTPLine();
   
   //Alert("resetGlobal()");
}

void checkDrawTPLine(string sym)
{
   if(drawTPLine) {
      removeDrawTPLine();   
      double buyTP1;
      double buyTP2;
      double sellTP1;
      double sellTP2;
      
      if(getNextTradeStop() >= 0) {        
         double SLPoints = (getBuyStop() - getSellStop()) / MarketInfo(sym, MODE_POINT);
         buyTP1 = getBuyStop() + SLPoints * 1.5 * MarketInfo(sym, MODE_POINT);
         buyTP2 = getBuyStop() + SLPoints * reward * MarketInfo(sym, MODE_POINT);
         sellTP1 = getSellStop() - SLPoints * 1.5 * MarketInfo(sym, MODE_POINT);
         sellTP2 = getSellStop() - SLPoints * reward * MarketInfo(sym, MODE_POINT);         
      } else {        
         double slBuy = getSL(sym, OP_BUY);
         double slSell = getSL(sym, OP_SELL);
         double buySLPoints = (MarketInfo(sym, MODE_ASK) - slBuy) / MarketInfo(sym, MODE_POINT);
         double sellSLPoints = (slSell - MarketInfo(sym, MODE_BID)) / MarketInfo(sym, MODE_POINT);
         
         buyTP1 = MarketInfo(sym, MODE_ASK) + buySLPoints * 1.5 * MarketInfo(sym, MODE_POINT);
         buyTP2 = MarketInfo(sym, MODE_ASK) + buySLPoints * reward * MarketInfo(sym, MODE_POINT);
         sellTP1 = MarketInfo(sym, MODE_BID) - sellSLPoints * 1.5 * MarketInfo(sym, MODE_POINT);
         sellTP2 = MarketInfo(sym, MODE_BID) - sellSLPoints * reward * MarketInfo(sym, MODE_POINT);
      }        
   
      if(buyTP1 > MarketInfo(sym, MODE_ASK) || getNextTradeStop() >= 0) {
         ObjectCreate("BuyTP1", OBJ_HLINE , 0,Time[0], buyTP1);
         ObjectSet("BuyTP1", OBJPROP_STYLE, STYLE_DASH);
         ObjectSet("BuyTP1", OBJPROP_COLOR, Magenta);
         ObjectSet("BuyTP1", OBJPROP_WIDTH, 0);
         
         ObjectCreate("BuyTP2", OBJ_HLINE , 0,Time[0], buyTP2);
         ObjectSet("BuyTP2", OBJPROP_STYLE, STYLE_SOLID);
         ObjectSet("BuyTP2", OBJPROP_COLOR, Magenta);
         ObjectSet("BuyTP2", OBJPROP_WIDTH, 0);
      }
      
      if(MarketInfo(sym, MODE_BID) > sellTP1 || getNextTradeStop() >= 0) {
         ObjectCreate("SellTP1", OBJ_HLINE , 0,Time[0], sellTP1);
         ObjectSet("SellTP1", OBJPROP_STYLE, STYLE_DASH);
         ObjectSet("SellTP1", OBJPROP_COLOR, Magenta);
         ObjectSet("SellTP1", OBJPROP_WIDTH, 0);           
         
         ObjectCreate("SellTP2", OBJ_HLINE , 0,Time[0], sellTP2);
         ObjectSet("SellTP2", OBJPROP_STYLE, STYLE_SOLID);
         ObjectSet("SellTP2", OBJPROP_COLOR, Magenta);
         ObjectSet("SellTP2", OBJPROP_WIDTH, 0);
      }
   }
}

void removeDrawTPLine()
{
   ObjectDelete("BuyTP1");
   ObjectDelete("BuyTP2");
   ObjectDelete("SellTP1");
   ObjectDelete("SellTP2");
}

string getCommentOrder()
{
   string commentOrder = "B:" + NormalizeDouble(AccountBalance(), 2) + "L:" + NormalizeDouble(getCurrentLossTrade(), 2) + "|" + getCountCurrentLossTrade();

   return StringSubstr(commentOrder, 0, 31);;
}

void checkDrawSLLine(string sym)
{
   if(!drawSLLine) {
      return;
   }

   if(checkNewCandle(sym) || OrdersTotal() > 0) {
      removeDrawSLLine();
   }
   
   if(OrdersTotal() == 0) {
      double slBuy = getSL(sym, OP_BUY);
      double slSell = getSL(sym, OP_SELL);
   
      ObjectCreate("BuySL", OBJ_TREND , 0, Time[1], slBuy, Time[3], slBuy);
      ObjectSet("BuySL", OBJPROP_STYLE, STYLE_SOLID);
      ObjectSet("BuySL", OBJPROP_COLOR, Red);
      ObjectSet("BuySL", OBJPROP_WIDTH, 0);
      ObjectSetInteger(0 ,"BuySL", OBJPROP_RAY_RIGHT, false);
      
      ObjectCreate("SellSL", OBJ_TREND , 0, Time[1], slSell, Time[3], slSell);
      ObjectSet("SellSL", OBJPROP_STYLE, STYLE_SOLID);
      ObjectSet("SellSL", OBJPROP_COLOR, Red);
      ObjectSet("SellSL", OBJPROP_WIDTH, 0);
      ObjectSetInteger(0 ,"SellSL", OBJPROP_RAY_RIGHT, false);
      
      double buySLPoints = (MarketInfo(sym, MODE_ASK) - slBuy) / MarketInfo(sym, MODE_POINT);
      double sellSLPoints = (slSell - MarketInfo(sym, MODE_BID)) / MarketInfo(sym, MODE_POINT);
      
      ObjectCreate("BuySLPoints", OBJ_TEXT, 0, Time[0], slBuy);
      ObjectSetText ("BuySLPoints", NormalizeDouble(DoubleToString(buySLPoints), 2), 10, "Calibri", clrRed); 
      
      ObjectCreate("SellSLPoints", OBJ_TEXT, 0, Time[0], slSell);
      ObjectSetText ("SellSLPoints", NormalizeDouble(DoubleToString(sellSLPoints), 2), 10, "Calibri", clrRed);           
   }
}

void removeDrawSLLine()
{
   ObjectDelete("BuySL"); 
   ObjectDelete("SellSL"); 
   ObjectDelete("BuySLPoints"); 
   ObjectDelete("SellSLPoints"); 
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

void checkRun(string sym)
{
   if (!checkActiveHours()) {
      return;
   }
   double openPrice = iOpen(sym, timeframe, 1);
   double closePrice = iClose(sym, timeframe, 1);
   double hightPrice = iHigh(sym, timeframe, 1);
   double lowPrice = iLow(sym, timeframe, 1);
   
   double openPrice2 = iOpen(sym, timeframe, 0);
   double closePrice2 = iClose(sym, timeframe, 0);
   double hightPrice2 = iHigh(sym, timeframe, 0);
   double lowPrice2 = iLow(sym, timeframe, 0);
   
   openPrice = NormalizeDouble(openPrice, MarketInfo(sym, MODE_DIGITS));
   closePrice = NormalizeDouble(closePrice, MarketInfo(sym, MODE_DIGITS));
   hightPrice = NormalizeDouble(hightPrice, MarketInfo(sym, MODE_DIGITS));
   lowPrice = NormalizeDouble(lowPrice, MarketInfo(sym, MODE_DIGITS));
   
   openPrice2 = NormalizeDouble(openPrice2, MarketInfo(sym, MODE_DIGITS));
   closePrice2 = NormalizeDouble(closePrice2, MarketInfo(sym, MODE_DIGITS));
   hightPrice2 = NormalizeDouble(hightPrice2, MarketInfo(sym, MODE_DIGITS));
   lowPrice2 = NormalizeDouble(lowPrice2, MarketInfo(sym, MODE_DIGITS));
   
   if( 
      (NormalizeDouble(hightPrice - lowPrice, MarketInfo(sym, MODE_DIGITS)) / MarketInfo(sym, MODE_POINT)) <= minLengthCandle
      || (NormalizeDouble(MathAbs(openPrice - closePrice), MarketInfo(sym, MODE_DIGITS)) / MarketInfo(sym, MODE_POINT)) <= minBodyCandle
      ) {
      return;
   }
   /*
   if(
      closePrice > openPrice // nen tang
      && (MathAbs(hightPrice - closePrice) > MathAbs(closePrice - openPrice) 
      || MathAbs(openPrice - lowPrice) > MathAbs(closePrice - openPrice)) // rau nen ngan hon than nen
      ) {
      return;
   } else if(
      closePrice < openPrice // nen giam
      && (MathAbs(closePrice - lowPrice) > MathAbs(openPrice - closePrice) // rau nen ngan hon than nen
      || MathAbs(hightPrice - openPrice) > MathAbs(openPrice - closePrice))
   ) {
      return;
   }
   */
   
   if (closePrice > openPrice && closePrice2 > openPrice2) {
      runTrading(sym, OP_BUY);   
   }
   
   if (closePrice < openPrice && closePrice2 < openPrice2) {
      runTrading(sym, OP_SELL);
   }
}

bool checkActiveHours()
{
   // Set operations disabled by default.
   bool OperationsAllowed = false;
   // Check if the current hour is between the allowed hours of operations. If so, return true.
   if ((StartHour == LastHour) && (Hour() == StartHour))
      OperationsAllowed = true;
   if ((StartHour < LastHour) && (Hour() >= StartHour) && (Hour() <= LastHour))
      OperationsAllowed = true;
   if ((StartHour > LastHour) && (((Hour() >= LastHour) && (Hour() <= 23)) || ((Hour() <= StartHour) && (Hour() > 0))))
      OperationsAllowed = true;
      
      //Alert(OperationsAllowed);
   return OperationsAllowed;
}

void forceCloseAll(string sym)
{  
   double spread = MarketInfo(sym, MODE_SPREAD);
   if (OrdersTotal() > 0 && (AccountBalance() / AccountEquity() >= ratioForceClose || spread > maxSpreadPoints)) {      
      Alert("forceCloseAll() => AccountBalance(): " + AccountBalance() + " AccountEquity(): " + AccountEquity() + " spread: " + spread);
      closeAll(sym);
   }   
}

void handleErrorHedge(string sym, int hedgeType, double lots, double hedgeEntry, string commentOrder)
{
   Alert("handleErrorHedge()");
   double tmpHedgeEntry = -1;
   int tmpHedgeType = -1;
   if(hedgeType == OP_BUYSTOP) {
      tmpHedgeEntry = MarketInfo(sym, MODE_ASK);
      tmpHedgeType = OP_BUY;
   } else if(hedgeType == OP_SELLSTOP) {
      tmpHedgeEntry = MarketInfo(sym, MODE_BID);
      tmpHedgeType = OP_SELL;
   }
   
   double checkDistance = MathAbs(NormalizeDouble(hedgeEntry - tmpHedgeEntry, MarketInfo(sym, MODE_DIGITS)) / MarketInfo(sym, MODE_POINT));
   if (checkDistance > maxSpreadPoints) {
      closeAll(sym);
      Alert("bug => checkDistance: " + checkDistance);
      return;
   }
   
   int checkOrder =  OrderSend(sym, tmpHedgeType, lots, tmpHedgeEntry, slippage, 0, 0, commentOrder, magic, 0, clrMagenta);
   if(checkOrder < 0) {
      closeAll(sym);
      Alert("Error: " + GetLastError());
      return;
   } 
}
