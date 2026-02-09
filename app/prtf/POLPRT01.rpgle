ctl-opt dftactgrp(*no) actgrp('INSURANCE');

dcl-f POLICY   usage(*input) keyed;
dcl-f CLIENT   usage(*input) keyed;
dcl-f PRODUCT  usage(*input) keyed;
dcl-f POLPRTF  printer;

dcl-pi *n;
   pPolicyNo char(15);
end-pi;

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

PolicyNo = pPolicyNo;

exsr Initialize;
exsr ReadPolicy;
exsr ReadClient;
exsr ReadProduct;
exsr CalculateAmounts;
exsr PrintPolicy;

*inlr = *on;
return;

begsr Initialize;

   PrintDate = %char(%date():*iso0);
   PrintTime = %char(%time():*hms0);

endsr;

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

begsr ReadClient;

   chain ClientId CLIENT;
   if %found(CLIENT);
      ClientName = CLIENT.CLIENT_NAME;
   else;
      ClientName = 'UNKNOWN CLIENT';
   endif;

endsr;

begsr ReadProduct;

   chain ProductId PRODUCT;
   if %found(PRODUCT);
      ProductName = PRODUCT.PRODUCT_NAME;
   else;
      ProductName = 'UNKNOWN PRODUCT';
   endif;

endsr;

begsr CalculateAmounts;

   TaxAmount    = Premium * 0.18;
   TotalPremium = Premium + TaxAmount;

endsr;

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
