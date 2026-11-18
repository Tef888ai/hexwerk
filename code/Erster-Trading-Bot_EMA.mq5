//+------------------------------------------------------------------+
//| HexWerk – Beispiel aus dem Video                                  |
//| „Erster Trading-Bot in MetaTrader 5“                              |
//| Nur zum Lernen, nur Demokonto, keine Anlageberatung.              |
//| Zwei gleitende Durchschnitte (EMA 10 / EMA 50), feste Lots,       |
//| Stop-Loss 200 und Take-Profit 400 Punkte. Datei in MQL5\Experts   |
//| speichern, im MetaEditor mit F7 kompilieren.                      |
//+------------------------------------------------------------------+
#property version "1.00"
#include <Trade\Trade.mqh>

input int    SchnelleEMA = 10;    // Schnelle EMA (Perioden)
input int    LangsameEMA = 50;    // Langsame EMA (Perioden)
input double Lots        = 0.10;  // Handelsgröße (Lots)
input int    StopLoss    = 200;   // Stop-Loss (Punkte)
input int    TakeProfit  = 400;   // Take-Profit (Punkte)

CTrade   trade;
int      hSchnell, hLangsam;
datetime letzteKerze = 0;

int OnInit()
{
   hSchnell = iMA(_Symbol, _Period, SchnelleEMA, 0, MODE_EMA, PRICE_CLOSE);
   hLangsam = iMA(_Symbol, _Period, LangsameEMA, 0, MODE_EMA, PRICE_CLOSE);
   if(hSchnell == INVALID_HANDLE || hLangsam == INVALID_HANDLE)
      return(INIT_FAILED);
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   IndicatorRelease(hSchnell);
   IndicatorRelease(hLangsam);
}

void OnTick()
{
   // nur einmal pro neuer Kerze prüfen
   datetime kerze = iTime(_Symbol, _Period, 0);
   if(kerze == letzteKerze) return;
   letzteKerze = kerze;

   // EMA-Werte der letzten zwei geschlossenen Kerzen holen
   double s[], l[];
   if(CopyBuffer(hSchnell, 0, 1, 2, s) < 2) return;
   if(CopyBuffer(hLangsam, 0, 1, 2, l) < 2) return;

   bool kaufen    = s[0] <= l[0] && s[1] > l[1];  // kreuzt nach oben
   bool verkaufen = s[0] >= l[0] && s[1] < l[1];  // kreuzt nach unten
   if(!kaufen && !verkaufen) return;

   // offene Position in Gegenrichtung schließen
   if(PositionSelect(_Symbol))
   {
      long typ = PositionGetInteger(POSITION_TYPE);
      if((kaufen && typ == POSITION_TYPE_BUY) || (verkaufen && typ == POSITION_TYPE_SELL))
         return;
      trade.PositionClose(_Symbol);
   }

   if(kaufen)
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
