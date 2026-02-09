**--------------------------------------------------------------
** Program : POLPRT01
** Purpose : Policy Document Printing
** Type    : Printer Program
**--------------------------------------------------------------

ctl-opt dftactgrp(*no) actgrp('INSURANCE');

**--------------------------------------------------------------
** Files
**--------------------------------------------------------------
dcl-f POLICY   usage(*input) keyed;
dcl-f CLIENT   usage(*input) keyed;
dcl-f PRODUCT  usage(*input) keyed;
dcl-f POLPRTF  printer;

**--------------------------------------------------------------
** Program Parameters
**--------------------------------------------------------------
dcl-pi *n;
   pPolicyNo char(15);
end-pi;

**--------------------------------------------------------------
** Working Variables
**--------------------------------------------------------------
dcl-s PolicyNo      char(15);
dcl-s ClientId      char(10);
dcl-s ProductId     char(10);
dcl-s PolicyStatus  char(15);

dcl-s ClientName    char(30);
dcl-s ProductName   char(30);

dcl-s StartDate     char(10);
dcl-s EndDate       char(10);

dcl-s CoverageLimit packed(11:2);
dcl-s Deductible    packed(9:2);
dcl-s Premium       packed(11:2);
dcl-s TaxAmount     packed(9:2);
dcl-s TotalPremium  packed(11:2);

dcl-s PrintDate     char(8);
dcl-s PrintTime     char(6);

**--------------------------------------------------------------
** Main Flow
**--------------------------------------------------------------
PolicyNo = pPolicyNo;

exsr Initialize;
exsr ReadPolicy;
exsr ReadClient;
exsr ReadProduct;
exsr CalculateAmounts;
exsr PrintPolicy;

*inlr = *on;
return;

**==============================================================
** Initialize
**==============================================================
begsr Initialize;

   PrintDate = %char(%date():*iso0);
   PrintTime = %char(%time():*hms0);

endsr;

**==============================================================
** Read Policy Master
**==============================================================
begsr ReadPolicy;

   chain PolicyNo POLICY;
   if %notfound(POLICY);
      dsply ('Policy not found: ' + PolicyNo);
      *inlr = *on;
      return;
   endif;

   ClientId     = POLICY.CLIENT_ID;
   ProductId    = POLICY.PRODUCT_ID;
   PolicyStatus = POLICY.POLICY_STATUS;
   StartDate    = POLICY.START_DATE;
   EndDate      = POLICY.END_DATE;

   CoverageLimit = POLICY.COVERAGE_LIMIT;
   Deductible    = POLICY.DEDUCTIBLE;
   Premium       = POLICY.PREMIUM;

endsr;

**==============================================================
** Read Client Details
**==============================================================
begsr ReadClient;

   chain ClientId CLIENT;
   if %found(CLIENT);
      ClientName = CLIENT.CLIENT_NAME;
   else;
      ClientName = 'UNKNOWN CLIENT';
   endif;

endsr;

**==============================================================
** Read Product Details
**==============================================================
begsr ReadProduct;

   chain ProductId PRODUCT;
   if %found(PRODUCT);
      ProductName = PRODUCT.PRODUCT_NAME;
   else;
      ProductName = 'UNKNOWN PRODUCT';
   endif;

endsr;

**==============================================================
** Calculate Financial Amounts
**==============================================================
begsr CalculateAmounts;

   TaxAmount    = Premium * 0.18;
   TotalPremium = Premium + TaxAmount;

endsr;

**==============================================================
** Print Policy Document
**==============================================================
begsr PrintPolicy;

   write HEADER;

   POLICYNO  = PolicyNo;
   CLIENTNM  = ClientName;
   PRODUCTNM = ProductName;
   STATUS    = PolicyStatus;
   write POLICYHDR;

   STARTDT   = StartDate;
   ENDDT     = EndDate;
   LIMITAMT = %char(CoverageLimit);
   DEDUCTAMT= %char(Deductible);
   write POLICYDET;

   PREMIUM   = %char(Premium);
   TAX       = %char(TaxAmount);
   TOTALPREM= %char(TotalPremium);
   write FINANCIAL;

   write FOOTER;

endsr;
