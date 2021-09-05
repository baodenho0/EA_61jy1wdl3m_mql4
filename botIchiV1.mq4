//+------------------------------------------------------------------+
//|                                                    botIchiV1.mq4 |
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
//+------------------------------------------------------------------+
//| v1 start
//+------------------------------------------------------------------+
//| v1.1 add global, fix reconnect internet, add button reset global
//+------------------------------------------------------------------+

extern string comment;
datetime tradeTime;
bool allowTrade = true;
int magic = 991; //v1.1 change 991
extern ENUM_TIMEFRAMES timeframe = PERIOD_M5;
extern double risk = 0.3; // risk (0.3%)
extern double reward = 1.3; // reward (1.3%)
extern double breakEven = 99999999;
extern int minSLPoints = 50;
extern int maxSLPoints = 200;
extern double maxSpreadPoints = 15;
extern bool combineStockastic = false;
extern bool combineADX = false;
extern bool combineRSI = false;
extern bool combineMartingale = true;
extern string ASCTrendName = "ASCTrend1i-Alert";
//double currentLossTrade = 0; //v1.1 change global 
//int countCurrentLossTrade = 0; //v1.1 change global
extern int countBreakEvenForMartingale = 2;
int lastASCTrend = -1;
//bool checkHedging = false; //v1.1 change global
extern int hedgeDistance = 100;
extern double hedge = 6; // hedge (6%)
extern int countHedge = 3;
string globalRandom = "_u6hxhs7f2p_BotIchiV1"; //v1.1 add

int OnInit()
  {
     
   //resetGlobal();
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
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   drawButton();
   commentReport();
//---
   string sym = Symbol();
   int tradeType = -1;
   
   checkBreakEven(sym);
   closeTradingByProfit(sym);
   
   if(tradeTime == iTime(sym, timeframe, 0)) {
      return;      
   }
   tradeTime = iTime(sym, 0, 0);     
   
   int checkASCTrend = checkASCTrend(sym);
   if(checkASCTrend == OP_BUY || checkASCTrend == OP_SELL) {
      lastASCTrend = checkASCTrend;
   }
         
   if(getCheckHedging() == true) {
      checkRemoveHedging(sym);
      return;
   }
   
   if(combineMartingale == true && ASCTrendName != "") {
      double lotsOfLastTrading = getLastTrading(sym);
      if(lotsOfLastTrading > 0) {
         Alert("useMartingale");
         useMartingale(sym, lotsOfLastTrading);
         return;
      }
   }
   
   tradeType = checkIchimokuAndCandle(sym);
   if(lastASCTrend < 0 || tradeType != lastASCTrend) {
      return;
   }
   int candleTradeType = checkCandle(sym);   
   if(candleTradeType != tradeType) {
      return;
   }
   /*
   if(combineStockastic == true) {
   int stockasticTradeType = checkStockastic(sym);
   // int stockasticTradeTypeX6 = checkStockasticX6(sym);
      if(tradeType != stockasticTradeType) {
         return;
      }
   }

   int ichimokuAndCandleX6TradeType = checkIchimokuAndCandleX6(sym);
   if(tradeType != ichimokuAndCandleX6TradeType) {
         return;
   }
 
   if(combineADX == true) {
      int adxTradeType = checkADX(sym);
      if(tradeType != adxTradeType) {
         return;
      }
   }
   
   if(combineRSI == true) {
      int rsiTradeType = checkRSI(sym);
      if(tradeType != rsiTradeType) {
         return;
      }
   }
   */
   
   runTrading(sym, tradeType);
  }
//+------------------------------------------------------------------+


void runTrading(string sym, int tradeType, double lot = 0) 
{
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
   
   double SL = getSL(sym, tradeType);
   double TP = getTP(entry, SL);
   
   entry = NormalizeDouble(entry, MarketInfo(sym, MODE_DIGITS));
   SL = NormalizeDouble(SL, MarketInfo(sym, MODE_DIGITS));
   TP = NormalizeDouble(TP, MarketInfo(sym, MODE_DIGITS));

   double SLPoints = MathAbs(NormalizeDouble(entry - SL, MarketInfo(sym, MODE_DIGITS)) / MarketInfo(sym, MODE_POINT));
   /*
   if(SLPoints < minSLPoints || SLPoints > maxSLPoints) {      
      Alert("SLPoints: " + SLPoints);
      return;
   }
   */
   
   if(lot == 0) {
      lot = getLot(sym, SLPoints);
      Alert("lot: " + lot);
   }
   
   if(entry && SL && TP) {
      if(combineMartingale == true && ASCTrendName != "") {
         SL = 0;
         TP = 0;
      }
      
      Alert(sym + " " + tradeType + " " + lot + " " + entry + " " + SL + " " + TP + " " + magic + " " + tradeColor);
      OrderSend(sym, tradeType, lot, entry, 20, SL, TP, comment, magic, 0, tradeColor);
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

    return(lotSize);
}

double getSL(string sym, int tradeType)
{
   int candleNumber;
   double SL = 0;
   double spread = MarketInfo(sym, MODE_SPREAD);
   if(spread > maxSpreadPoints) {
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

void useMartingale(string sym, double lot)
{
   int tradeType = -1;
   int closeTradeType = -1;
   int ascTrendTradeType = checkASCTrend(sym);
   //int ichimokuAndCandleTradeType = checkIchimokuAndCandle(sym);
   
   if(ascTrendTradeType != -1) {
      tradeType = ascTrendTradeType;
   } /*else if(ichimokuAndCandleTradeType != -1) {
      tradeType = ichimokuAndCandleTradeType;
   }*/
      
   int candleTradeType = checkCandle(sym);   
   if(candleTradeType != tradeType) {
      return;
   }
   
   if(tradeType == OP_BUY) {
      closeTradeType = OP_SELL;
   } else if(tradeType == OP_SELL) {
      closeTradeType = OP_BUY;
   } else {
      return;
   }
   
   closeTradingByTradeType(sym, closeTradeType);   
   
   if(getCurrentLossTrade() < 0) {
      runTrading(sym, tradeType, lot * 2);
      
      double checkHedge = AccountBalance() / 100 * hedge;
      
      if(getCurrentLossTrade() <= checkHedge * -1 || getCountCurrentLossTrade() >= countHedge) {
         useHedge(sym, tradeType, lot * 2);
         return;
      }
   }
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
      ((AccountProfit() + getCurrentLossTrade()) >= rewardAmount && getCurrentLossTrade() >= 0) 
      || (getCountCurrentLossTrade() >= 1 && (AccountProfit() + getCurrentLossTrade()) >= (rewardAmount / 2) && getCurrentLossTrade() < 0) 
      // || (countCurrentLossTrade >= countBreakEvenForMartingale && ((AccountProfit() + currentLossTrade) >= 0))
   ) {
      for(int i = OrdersTotal() - 1; i >= 0; i--) {
         if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES) && OrderMagicNumber() == magic) {
            if(OrderType() == OP_BUY) {
               closeType = MODE_BID;
            } else if(OrderType() == OP_SELL) {
               closeType = MODE_ASK;
            } else {
               OrderDelete(OrderTicket());
            }
            
            OrderClose(OrderTicket() , OrderLots(), MarketInfo(sym, closeType), 5);            
         }
      }
      
      /*
      setCurrentLossTrade(0);
      setCountCurrentLossTrade(0);
      setCheckHedging(false);
      */
      resetGlobal();
   }
}

void closeTradingByTradeType(string sym, int tradeType)
{
   int closeType;
   
   for(int i = OrdersTotal() - 1; i >= 0; i--) {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES) && OrderMagicNumber() == magic && tradeType == OrderType()) {
         if(OrderType() == OP_BUY) {
            closeType = MODE_BID;
         } else if(OrderType() == OP_SELL) {
            closeType = MODE_ASK;
         }
         
         setCurrentLossTrade(getCurrentLossTrade() + OrderProfit());
         setCountCurrentLossTrade(getCountCurrentLossTrade() + 1);
         
         OrderClose(OrderTicket() , OrderLots(), MarketInfo(sym, closeType), 5);
      }
   }
   
   if(getCurrentLossTrade() > 0) {
      resetGlobal();
      /*
      setCurrentLossTrade(0);
      setCountCurrentLossTrade(0);
      */
   }
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
      "currentLossTrade: " + getCurrentLossTrade() + " (" + getCountCurrentLossTrade() + ")\n"
      + "accountProfit: " + AccountProfit() + "\n"
      + "checkHedging: " + getCheckHedging()
   );
    
    /*
    for(int i = 0; i <= GlobalVariablesTotal(); i++) {
      Alert(GlobalVariableName(i));    
    }    
    */
}

void useHedge(string sym, int tradeType, double lot)
{
   int hedgeType = -1;
   double hedgeEntry;
   double lastEntry;
     
   if(OrderSelect(OrdersTotal() - 1, SELECT_BY_POS, MODE_TRADES) 
      && OrderSymbol() == sym
      && OrderMagicNumber() == magic
   ) {
         lastEntry = OrderOpenPrice();
   }

   if(tradeType == OP_BUY) {
      hedgeType = OP_SELLSTOP;
      hedgeEntry = lastEntry - hedgeDistance * MarketInfo(sym, MODE_POINT);
   } else if(tradeType == OP_SELL) {
      hedgeType = OP_BUYSTOP;
      hedgeEntry = lastEntry + hedgeDistance * MarketInfo(sym, MODE_POINT);
   } else {
      return;
   }
   
   hedgeEntry = NormalizeDouble(hedgeEntry, MarketInfo(sym, MODE_DIGITS));
   
   OrderSend(sym, hedgeType, lot, hedgeEntry, 20, 0, 0, comment, magic, 0);
   
   setCheckHedging(true);
}

void checkRemoveHedging(string sym)
{
   int closeTradeType = -1;
   int tradeType = checkIchimokuAndCandle(sym);
   if(lastASCTrend < 0 || tradeType != lastASCTrend) {
      return;
   }
   int candleTradeType = checkCandle(sym);   
   if(candleTradeType != tradeType) {
      return;
   }
   
   if(tradeType == OP_BUY) {
      closeTradeType = OP_SELL;
   } else if(tradeType == OP_SELL) {
      closeTradeType = OP_BUY;
   } else {
      return;
   }
   
   double lotsOfLastTrading = getLastTrading(sym);
   
   closeTradingByTradeType(sym, closeTradeType);
   
   runTrading(sym, tradeType, lotsOfLastTrading);
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

bool getCheckHedging()
{
   return GlobalVariableGet("checkHedging" + globalRandom);
}

void setCheckHedging(bool value = false)
{
   GlobalVariableSet("checkHedging" + globalRandom, value);
}

void resetGlobal()
{
   setCurrentLossTrade();
   setCountCurrentLossTrade();
   setCheckHedging();
   
   Alert("resetGlobal()");
}

void drawButton()
{    
   long currentChartId = ChartID();

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
   if(id == CHARTEVENT_OBJECT_CLICK) {
      if(sparam == "resetGlobalBtn") {
         resetGlobal();
      }      
   }
}
