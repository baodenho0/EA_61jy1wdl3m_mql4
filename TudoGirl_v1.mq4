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
string globalRandom = "_u6hxhs7f2p_TudoGirl";

bool uptrend = false;
bool downtrend = false;
int slippage = 0;


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
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   string sym = Symbol();
   if(tradeTime == iTime(sym, timeframe, 0)) {
      return;      
   }
   tradeTime = iTime(sym, 0, 0);
   checkRun(sym);
  }
//+------------------------------------------------------------------+

int checkHG_0001a_MTF1(string sym)
{   
   int tradeType = -1;
   
   double redM1_1 = iCustom(sym, timeframe, HG_0001a_MTF, 0, 1); // red m1
   double blueM1_1 = iCustom(sym, timeframe, HG_0001a_MTF, 1, 1); // blue m1
   double redM5_1 = iCustom(sym, timeframe, HG_0001a_MTF, 2, 1); // red m5
   double blueM5_1 = iCustom(sym, timeframe, HG_0001a_MTF, 3, 1); // blue m5
   double redM15_1 = iCustom(sym, timeframe, HG_0001a_MTF, 4, 1); // red m15
   double blueM15_1 = iCustom(sym, timeframe, HG_0001a_MTF, 5, 1); // blue m15
   double redM30_1 = iCustom(sym, timeframe, HG_0001a_MTF, 6, 1); // red m30
   double blueM30_1 = iCustom(sym, timeframe, HG_0001a_MTF, 7, 1); // blue m30
   
   double redM1_2 = iCustom(sym, timeframe, HG_0001a_MTF, 0, 2); // red m1
   double blueM1_2 = iCustom(sym, timeframe, HG_0001a_MTF, 1, 2); // blue m1
   double redM5_2 = iCustom(sym, timeframe, HG_0001a_MTF, 2, 2); // red m5
   double blueM5_2 = iCustom(sym, timeframe, HG_0001a_MTF, 3, 2); // blue m5
   double redM15_2 = iCustom(sym, timeframe, HG_0001a_MTF, 4, 2); // red m15
   double blueM15_2 = iCustom(sym, timeframe, HG_0001a_MTF, 5, 2); // blue m15
   double redM30_2 = iCustom(sym, timeframe, HG_0001a_MTF, 6, 2); // red m30
   double blueM30_2 = iCustom(sym, timeframe, HG_0001a_MTF, 7, 2); // blue m30
   
   double redM1_3 = iCustom(sym, timeframe, HG_0001a_MTF, 0, 3); // red m1
   double blueM1_3 = iCustom(sym, timeframe, HG_0001a_MTF, 1, 3); // blue m1
   double redM5_3 = iCustom(sym, timeframe, HG_0001a_MTF, 2, 3); // red m5
   double blueM5_3 = iCustom(sym, timeframe, HG_0001a_MTF, 3, 3); // blue m5
   double redM15_3 = iCustom(sym, timeframe, HG_0001a_MTF, 4, 3); // red m15
   double blueM15_3 = iCustom(sym, timeframe, HG_0001a_MTF, 5, 3); // blue m15
   double redM30_3 = iCustom(sym, timeframe, HG_0001a_MTF, 6, 3); // red m30
   double blueM30_3 = iCustom(sym, timeframe, HG_0001a_MTF, 7, 3); // blue m30
   
   double redM1_4 = iCustom(sym, timeframe, HG_0001a_MTF, 0, 4); // red m1
   double blueM1_4 = iCustom(sym, timeframe, HG_0001a_MTF, 1, 4); // blue m1
   double redM5_4 = iCustom(sym, timeframe, HG_0001a_MTF, 2, 4); // red m5
   double blueM5_4 = iCustom(sym, timeframe, HG_0001a_MTF, 3, 4); // blue m5
   double redM15_4 = iCustom(sym, timeframe, HG_0001a_MTF, 4, 4); // red m15
   double blueM15_4 = iCustom(sym, timeframe, HG_0001a_MTF, 5, 4); // blue m15
   double redM30_4 = iCustom(sym, timeframe, HG_0001a_MTF, 6, 4); // red m30
   double blueM30_4 = iCustom(sym, timeframe, HG_0001a_MTF, 7, 4); // blue m30
   
   
   if (blueM5_1 == 3 && blueM5_2 == 3 && blueM5_3 == 3) {
      uptrend = true;
      downtrend = false;  
   }
   
   if (redM15_1 == 3 && redM15_2 == 3 && redM15_3 == 3) {
      uptrend = false;
      downtrend = true;   
   }
   
   if (uptrend == true 
      && (blueM1_1 == 1 && blueM1_2 == 1 && redM1_3 == 1 && redM1_4 == 1
      || blueM5_1 == 1 && blueM5_2 == 1 && redM5_3 == 1 && redM5_4 == 1)
   ) {
      tradeType = OP_BUY;
   }
   
   if (downtrend == true 
      && (redM1_1 == 1 && redM1_2 == 1 && blueM1_3 == 1 && blueM1_3 == 1
      || redM5_1 == 1 && redM5_2 == 1 && blueM5_3 == 1 && blueM5_3 == 1)
   ) {
      tradeType = OP_SELL;
   }
   
   return (tradeType);
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

void checkRun(string sym)
{
   int tradeType = -1;
   int closeType = -1;
   tradeType = checkHG_0001a_MTF1(sym);
   
   if (tradeType == OP_BUY) {
      closeType= OP_SELL;
   } else if (tradeType == OP_SELL) {
      closeType= OP_BUY;
   }   
   closeTradingByTradeType(sym, closeType);
   runTrading(sym, tradeType);
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
   return 0.01;
}
