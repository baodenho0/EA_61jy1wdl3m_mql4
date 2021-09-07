//+------------------------------------------------------------------+
//|                                                    botIchiV2.mq4 |
//|                        Copyright 2021, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "2.20"
#property strict
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| v2 update from botIchiV1
//+------------------------------------------------------------------+
//| v2.1 add global, fix reconnect internet, add button reset global,
//| change const
//| update closeTradingByProfit()
//+------------------------------------------------------------------+

extern string comment;
datetime tradeTime;
bool allowTrade = true;
int magic = 992; //v2.1 change 992 
extern ENUM_TIMEFRAMES timeframe = PERIOD_M5;
extern double risk = 0.9; // risk (0.9%)
extern double reward = 2.6; // reward (2.6%)
extern double breakEven = 99999;
extern int minSLPoints = 50;
extern int maxSLPoints = 150;
extern double maxSpreadPoints = 15;
//extern bool combineMartingale = true; //v2.1 remove
extern string ASCTrendName = "ASCTrend1i-Alert";
//double currentLossTrade = 0; //v2.1 change global 
//int countCurrentLossTrade = 0; //v2.1 change global 
int lastASCTrend = -1;
//bool checkHedging = false; //v2.1 remove
//double buyStop = -1; //v2.1 change global 
//double sellStop = -1; //v2.1 change global 
//int nextTradeStop = -1;  //v2.1 change global 
string SupDem = "SupDem";
string globalRandom = "_jkfp72iu40_BotIchiV2"; //v2.1 add

int OnInit()
  {
   if(IsTesting()) {
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
   
   /*
   if(useAvgPrice(sym)) {
         return;
   }
   */
   /*   
   if(getAllowUseAvgPrice()) {
      if(useAvgPrice(sym)) {
         return;
      }
   } else {
      checkAllowUseAvgPrice(sym);
   }*/  
   
   useHedge(sym);
   
   if(tradeTime == iTime(sym, timeframe, 0) || OrdersTotal() > 0) {
      return;
   }
   tradeTime = iTime(sym, 0, 0);
   
   // checkSideway(sym);
   
   int checkASCTrend = checkASCTrend(sym);
   if(checkASCTrend == OP_BUY || checkASCTrend == OP_SELL) {
      lastASCTrend = checkASCTrend;
   }        
   
   tradeType = checkIchimokuAndCandle(sym);
   if(lastASCTrend < 0 || tradeType != lastASCTrend) {
      return;
   }
   int candleTradeType = checkCandle(sym);   
   if(candleTradeType != tradeType) {
      return;
   }   
   
   int checkNotTradeIchimokuV2 = checkNotTradeIchimokuV2(sym);
   if(checkNotTradeIchimokuV2 == true) {
      return;
   }
   
   int checkOverThresholdByIchimoku = checkOverThresholdByIchimoku(sym);
   if(checkOverThresholdByIchimoku == true) {
      return;
   }
   
   
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
      Alert("lot: " + lot);
   }
   
   if(entry && SL && TP) {
      // Alert(sym + " " + tradeType + " " + lot + " " + entry + " " + SL + " " + TP + " " + magic + " " + tradeColor);
      OrderSend(sym, tradeType, lot, entry, 20, 0, 0, comment, magic, 0, tradeColor);
      
      if(tradeType == OP_BUY) {
         setNextTradeStop(OP_SELLSTOP);
         setBuyStop(entry);
         setSellStop(SL);
      } else if(tradeType == OP_SELL) {
         setBuyStop(SL);
         setSellStop(entry);
         setNextTradeStop(OP_BUYSTOP);
      }
      setFirstTradeType(tradeType);
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
         && (NormalizeDouble(senKouSpanA - hightPrice, MarketInfo(sym, MODE_DIGITS)) / MarketInfo(sym, MODE_POINT)) <= 15))
      ) {
         tradeType = OP_SELL;
      } else if(senKouSpanB < senKouSpanA
         && (senKouSpanB < hightPrice
         || (senKouSpanB >= hightPrice
         && (NormalizeDouble(senKouSpanB - hightPrice, MarketInfo(sym, MODE_DIGITS)) / MarketInfo(sym, MODE_POINT)) <= 15))
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

bool checkNotTradeIchimokuV2(string sym) 
{
   bool status = false;
   
   double senKouSpanA = iIchimoku(sym, timeframe, 9, 26, 52, MODE_SENKOUSPANA, 1);
   double senKouSpanB = iIchimoku(sym, timeframe, 9, 26, 52, MODE_SENKOUSPANB, 1);
   double senKouSpanAFuture = iIchimoku(sym, timeframe, 9, 26, 52, MODE_SENKOUSPANA, -25);
   double senKouSpanBFuture = iIchimoku(sym, timeframe, 9, 26, 52, MODE_SENKOUSPANB, -25);   
   
   senKouSpanA = NormalizeDouble(senKouSpanA, MarketInfo(sym, MODE_DIGITS));
   senKouSpanB = NormalizeDouble(senKouSpanB, MarketInfo(sym, MODE_DIGITS));
   senKouSpanAFuture = NormalizeDouble(senKouSpanAFuture, MarketInfo(sym, MODE_DIGITS));
   senKouSpanBFuture = NormalizeDouble(senKouSpanBFuture, MarketInfo(sym, MODE_DIGITS));
   
   if(
   ((senKouSpanAFuture > senKouSpanBFuture && senKouSpanA > senKouSpanB)
   || (senKouSpanAFuture < senKouSpanBFuture && senKouSpanA < senKouSpanB))
   && ((NormalizeDouble(MathAbs(senKouSpanA - senKouSpanB), MarketInfo(sym, MODE_DIGITS)) / MarketInfo(sym, MODE_POINT)) >= 300)
   ) {
      status = true;
   }
   
   return status;
}

bool checkOverThresholdByIchimoku(string sym)
{
   bool status = true;
   
   for(int i = 1; i <= 36; i++) {
      double senKouSpanA = iIchimoku(sym, timeframe, 9, 26, 52, MODE_SENKOUSPANA, i);
      double senKouSpanB = iIchimoku(sym, timeframe, 9, 26, 52, MODE_SENKOUSPANB, i);   
      senKouSpanA = NormalizeDouble(senKouSpanA, MarketInfo(sym, MODE_DIGITS));
      senKouSpanB = NormalizeDouble(senKouSpanB, MarketInfo(sym, MODE_DIGITS));
      
      double senKouSpanAPre = iIchimoku(sym, timeframe, 9, 26, 52, MODE_SENKOUSPANA, i + 1);
      double senKouSpanBPre = iIchimoku(sym, timeframe, 9, 26, 52, MODE_SENKOUSPANB, i + 1);   
      senKouSpanAPre = NormalizeDouble(senKouSpanAPre, MarketInfo(sym, MODE_DIGITS));
      senKouSpanBPre = NormalizeDouble(senKouSpanBPre, MarketInfo(sym, MODE_DIGITS));
   
      if(senKouSpanA > senKouSpanB && senKouSpanAPre < senKouSpanBPre
      || senKouSpanA < senKouSpanB && senKouSpanAPre > senKouSpanBPre
      ) {
         status = false;
      }
   }
   
   return status;
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
   //Alert("getCountCurrentLossTrade: " + getCountCurrentLossTrade());
   //Alert("rewardAmount: " + rewardAmount * 10);
   
   /*
   double hightPrice = iHigh(sym, timeframe, 1);
   double lowPrice = iLow(sym, timeframe, 1);   
   hightPrice = NormalizeDouble(hightPrice, MarketInfo(sym, MODE_DIGITS));
   lowPrice = NormalizeDouble(lowPrice, MarketInfo(sym, MODE_DIGITS));
   */
     
   if(
   AccountProfit() + getCurrentLossTrade() >= rewardAmount && getCountCurrentLossTrade() < 1
   || AccountProfit() + getCurrentLossTrade() >= 0 && getCountCurrentLossTrade() >= 1
   || AccountProfit() + getCurrentLossTrade() + rewardAmount >= 0 && getCountCurrentLossTrade() >= 8
   
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
      
      resetGlobal();
      // setCurrentLossTrade(0);
      // setCountCurrentLossTrade(0);
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
         } else if(OrderType() == OP_SELLSTOP || OrderType() == OP_BUYSTOP) {
            OrderDelete(OrderTicket());
         }
         
         setCurrentLossTrade(getCurrentLossTrade() + OrderProfit());
         setCountCurrentLossTrade(getCountCurrentLossTrade() + 1);
         
         OrderClose(OrderTicket() , OrderLots(), MarketInfo(sym, closeType), 5);
      }
   }
   
   if(getCurrentLossTrade() > 0) {
      setCurrentLossTrade(0);
      setCountCurrentLossTrade(0);
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
   if(closePrice >= 1.37756 && closePrice <= 1.37796 // between 1.37777
   || closePrice >= 1.38980 && closePrice <= 1.39020 // between 1.39000
   // || closePrice >= 1.38969 && closePrice <= 1.39009 // between 1.38989
   ) { 
      return false;
   }
   
   
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
   // Alert(MathAbs(closePrice - lowPrice) + " < " + MathAbs(openPrice - closePrice));
   // Alert(MathAbs(openPrice2 - closePrice2) + " < " + MathAbs(openPrice - closePrice));
   
   return (tradeType);
}

void commentReport()
{
   Comment(
   "accountProfit: " + AccountProfit() + "(" + OrdersTotal() + ")" + "\n" +
   "currentLossTrade: " + getCurrentLossTrade() + "(" + getCountCurrentLossTrade() + ")" + "\n" +
   "checkUseAvgPrice: " + getCheckUseAvgPrice() + "\n" +
   "getAllowUseAvgPrice: " + getAllowUseAvgPrice() + "\n"
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
      Alert(hedgeType + getNextTradeStop());
      if(hedgeType != getNextTradeStop()) {
         return;
      }

      double hedgeLot = lastLot * 1.5;
      if(lastLot == 0.01) {
         hedgeLot = 0.02;
      }
      
      OrderSend(sym, hedgeType, hedgeLot, hedgeEntry, 20, 0, 0, comment, magic, 0);
      
      if(hedgeType == OP_SELLSTOP) {
         setNextTradeStop(OP_BUYSTOP);
      } else if(hedgeType == OP_BUYSTOP) {
         setNextTradeStop(OP_SELLSTOP);
      }
      
      closeTradingByTradeType(sym, closeType);
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

int getFirstTradeType()
{
   return GlobalVariableGet("firstTradeType" + globalRandom);
}

void setFirstTradeType(int value = -1)
{
   GlobalVariableSet("firstTradeType" + globalRandom, value);
}

bool getCheckUseAvgPrice()
{
   return GlobalVariableGet("checkUseAvgPrice" + globalRandom);
}

void setCheckUseAvgPrice(bool value = false)
{
   GlobalVariableSet("checkUseAvgPrice" + globalRandom, value);
}

bool getAllowUseAvgPrice()
{
   return GlobalVariableGet("allowUseAvgPrice" + globalRandom);
}

void setAllowUseAvgPrice(bool value = false)
{
   GlobalVariableSet("allowUseAvgPrice" + globalRandom, value);
}

void resetGlobal()
{
   setCurrentLossTrade();
   setCountCurrentLossTrade();
   setBuyStop();
   setSellStop();
   setNextTradeStop();
   setFirstTradeType();
   setCheckUseAvgPrice();
   setAllowUseAvgPrice();
   
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

bool useAvgPrice(string sym)
{
   if(getCountCurrentLossTrade() < 6 /*&& (getNextTradeStop() - 4) != getFirstTradeType()*/) {
      return false;
   }
   
   if(getCheckUseAvgPrice()) {
      return true;
   }
   
   int nextTradeType = -1;
   double currentPrice;
   double avgPrice = -1;      
   int closeType = -1;
   
   if(getFirstTradeType() == OP_BUY) {
      currentPrice = MarketInfo(sym, MODE_ASK);
      avgPrice = getSellStop();
      closeType = OP_SELLSTOP;
      nextTradeType = OP_BUYLIMIT;
   } else if(getFirstTradeType() == OP_SELL) {
      currentPrice = MarketInfo(sym, MODE_BID);
      avgPrice = getBuyStop();
      closeType = OP_BUYSTOP;
      nextTradeType = OP_SELLLIMIT;
   }
   
   if((currentPrice > avgPrice && nextTradeType == OP_SELLLIMIT)
   || (currentPrice < avgPrice && nextTradeType == OP_BUYLIMIT)
   ) {
      nextTradeType = nextTradeType + 2;
   }
   
   double lastLot = getLastTrading(sym) * 1.5;      
   int check = OrderSend(sym, nextTradeType, lastLot, avgPrice, 20, 0, 0, comment, magic, 0);
   
   if(check >=0) {
      closeTradingByTradeType(sym, closeType);
      closeTradingByTradeType(sym, (closeType - 4));
      setCheckUseAvgPrice(true);
   
      return true;
   }
   
   return false;
}

void checkAllowUseAvgPrice(string sym)
{
   double hightPrice1 = iHigh(sym, timeframe, 1) + MarketInfo(sym, MODE_SPREAD) * MarketInfo(sym, MODE_POINT);
   double lowPrice1 = iLow(sym, timeframe, 1);
   double hightPrice2 = iHigh(sym, timeframe, 2) + MarketInfo(sym, MODE_SPREAD) * MarketInfo(sym, MODE_POINT);
   double lowPrice2 = iLow(sym, timeframe, 2);
   
   hightPrice1 = NormalizeDouble(hightPrice1, MarketInfo(sym, MODE_DIGITS));
   lowPrice1 = NormalizeDouble(lowPrice1, MarketInfo(sym, MODE_DIGITS));
   hightPrice2 = NormalizeDouble(hightPrice2, MarketInfo(sym, MODE_DIGITS));
   lowPrice2 = NormalizeDouble(lowPrice2, MarketInfo(sym, MODE_DIGITS));
   
   if((getBuyStop() < hightPrice1 || getBuyStop() < hightPrice2)
   && (getSellStop() > lowPrice1 || getSellStop() > lowPrice2)
   ) {
      setAllowUseAvgPrice(true);
   }
}
