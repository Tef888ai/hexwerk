//+------------------------------------------------------------------+
//| HexWerk - example from the video                                  |
//| "Your First Trading Bot in MetaTrader 5"                          |
//| For learning only, demo account only, not investment advice.      |
//| Two moving averages (EMA 10 / EMA 50), fixed lots,                |
//| stop loss 200 and take profit 400 points. Save the file in        |
//| MQL5\Experts and compile it in MetaEditor with F7.                |
//+------------------------------------------------------------------+
#property version "1.00"
#include <Trade\Trade.mqh>

input int    FastEMA    = 10;    // Fast EMA (periods)
input int    SlowEMA    = 50;    // Slow EMA (periods)
input double Lots       = 0.10;  // Trade size (lots)
input int    StopLoss   = 200;   // Stop loss (points)
input int    TakeProfit = 400;   // Take profit (points)

CTrade   trade;
int      hFast, hSlow;
datetime lastBar = 0;

int OnInit()
{
   hFast = iMA(_Symbol, _Period, FastEMA, 0, MODE_EMA, PRICE_CLOSE);
   hSlow = iMA(_Symbol, _Period, SlowEMA, 0, MODE_EMA, PRICE_CLOSE);
   if(hFast == INVALID_HANDLE || hSlow == INVALID_HANDLE)
      return(INIT_FAILED);
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   IndicatorRelease(hFast);
   IndicatorRelease(hSlow);
}

void OnTick()
{
   // check only once per new candle
   datetime bar = iTime(_Symbol, _Period, 0);
   if(bar == lastBar) return;
   lastBar = bar;

   // EMA values of the last two closed candles
   double f[], s[];
   if(CopyBuffer(hFast, 0, 1, 2, f) < 2) return;
   if(CopyBuffer(hSlow, 0, 1, 2, s) < 2) return;

   bool buy  = f[0] <= s[0] && f[1] > s[1];  // crosses up
   bool sell = f[0] >= s[0] && f[1] < s[1];  // crosses down
   if(!buy && !sell) return;

   // close an open position in the opposite direction
   if(PositionSelect(_Symbol))
   {
      long type = PositionGetInteger(POSITION_TYPE);
      if((buy && type == POSITION_TYPE_BUY) || (sell && type == POSITION_TYPE_SELL))
         return;
      trade.PositionClose(_Symbol);
   }

   if(buy)
   {
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double sl  = NormalizeDouble(ask - StopLoss * _Point, _Digits);
      double tp  = NormalizeDouble(ask + TakeProfit * _Point, _Digits);
      trade.Buy(Lots, _Symbol, ask, sl, tp);
   }
   else
   {
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double sl  = NormalizeDouble(bid + StopLoss * _Point, _Digits);
      double tp  = NormalizeDouble(bid - TakeProfit * _Point, _Digits);
      trade.Sell(Lots, _Symbol, bid, sl, tp);
   }
}
