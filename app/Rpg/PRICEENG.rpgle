**FREE
ctl-opt dftactgrp(*no)
        actgrp(*caller)
        option(*srcstmt:*nodebugio);

/*----------------------------------------------------------------*/
/* Files                                                          */
/*----------------------------------------------------------------*/
dcl-f AXAQUOTE  usage(*update) keyed;
dcl-f AXAPRICING usage(*input)  keyed;

/*----------------------------------------------------------------*/
/* Copy books (COBOL COPY PRICING / QUOTE / PRODUCT)               */
/*----------------------------------------------------------------*/
 /copy PRICING
 /copy QUOTE
 /copy PRODUCT

/*----------------------------------------------------------------*/
/* Entry parameter (DFHCOMMAREA equivalent)                        */
/*----------------------------------------------------------------*/
dcl-pi *n;
   pCommArea char(100);
end-pi;

/*----------------------------------------------------------------*/
/* Working storage                                                */
/*----------------------------------------------------------------*/
dcl-s wsBaseCalc       packed(14:2) inz(0);
dcl-s wsRiskCalc       packed(14:2) inz(0);
dcl-s wsTotalCalc      packed(14:2) inz(0);
dcl-s wsCommissionCalc packed(12:2) inz(0);

/*----------------------------------------------------------------*/
/* Main logic                                                      */
/*----------------------------------------------------------------*/
Quote_ID = %subst(pCommArea:1:10);

readQuoteData();
readPricingRules();
calculatePricing();
updateQuotePricing();

return;

/*----------------------------------------------------------------*/
/* Read quote data                                                 */
/*----------------------------------------------------------------*/
dcl-proc readQuoteData;

   chain Quote_ID AXAQUOTE;

   if not %found(AXAQUOTE);
      return;
   endif;

end-proc;

/*----------------------------------------------------------------*/
/* Read pricing rules                                              */
/*----------------------------------------------------------------*/
dcl-proc readPricingRules;

   chain Product_Type AXAPRICING;

   if not %found(AXAPRICING);
      return;
   endif;

end-proc;

/*----------------------------------------------------------------*/
/* Calculate pricing                                               */
/*----------------------------------------------------------------*/
dcl-proc calculatePricing;

   wsBaseCalc =
      (Limit * Base_Rate) / 100;

   wsRiskCalc =
      wsBaseCalc * Risk_Multiplier;

   wsTotalCalc =
      wsBaseCalc + wsRiskCalc;

   wsCommissionCalc =
      (wsTotalCalc * Commission_Rate) / 100;

   if wsTotalCalc < Min_Premium;
      wsTotalCalc = Min_Premium;
   endif;

   if wsTotalCalc > Max_Premium;
      wsTotalCalc = Max_Premium;
   endif;

   Calc_Base_Premium = wsBaseCalc;
   Calc_Risk_Premium = wsRiskCalc;
   Calc_Total_Premium = wsTotalCalc;
   Calc_Commission   = wsCommissionCalc;

   determineCompetitiveness();

end-proc;

/*----------------------------------------------------------------*/
/* Determine competitiveness                                      */
/*----------------------------------------------------------------*/
dcl-proc determineCompetitiveness;

   if wsTotalCalc < 100000;
      Calc_Competitiveness = 'COMPETITIVE';
   elseif wsTotalCalc < 500000;
      Calc_Competitiveness = 'MODERATE';
   else;
      Calc_Competitiveness = 'PREMIUM';
   endif;

end-proc;

/*----------------------------------------------------------------*/
/* Update quote pricing                                            */
/*----------------------------------------------------------------*/
dcl-proc updateQuotePricing;

   Base_Premium       = Calc_Base_Premium;
   Risk_Premium       = Calc_Risk_Premium;
   Total_Premium      = Calc_Total_Premium;
   Commission_Amount  = Calc_Commission;
   Competitiveness    = Calc_Competitiveness;
   Pricing_Method     = 'CALCULATED';

   update AXAQUOTE;

end-proc;
