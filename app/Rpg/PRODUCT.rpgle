**FREE
ctl-opt dftactgrp(*no)
        actgrp(*caller)
        option(*srcstmt:*nodebugio);

/*----------------------------------------------------------------*/
/* Copy books (COBOL COPY equivalents)                             */
/*----------------------------------------------------------------*/
 /copy product

/*----------------------------------------------------------------*/
/* File declarations                                              */
/*----------------------------------------------------------------*/
dcl-f AXAPROD usage(*update:*input) keyed;

/*----------------------------------------------------------------*/
/* Entry parameters (DFHCOMMAREA equivalent)                       */
/*----------------------------------------------------------------*/
dcl-pi *n;
   pCommArea char(100);
end-pi;

/*----------------------------------------------------------------*/
/* Working storage                                                */
/*----------------------------------------------------------------*/
dcl-s wsProductKey char(10);
dcl-s wsUpdateFlag char(1) inz('N');

/*----------------------------------------------------------------*/
/* Main logic                                                      */
/*----------------------------------------------------------------*/
wsProductKey = %subst(pCommArea:1:10);

if wsProductKey <> *blanks;
   readProduct();
endif;

sendMap();

return;

/*----------------------------------------------------------------*/
/* Read product                                                   */
/*----------------------------------------------------------------*/
dcl-proc readProduct;
   chain wsProductKey AXAPROD;
   if %found(AXAPROD);
      wsUpdateFlag = 'Y';
   else;
      newProduct();
   endif;
end-proc;

/*----------------------------------------------------------------*/
/* Initialize new product                                         */
/*----------------------------------------------------------------*/
dcl-proc newProduct;
   clear PRODUCT_RECORD;
   wsUpdateFlag = 'N';
end-proc;

/*----------------------------------------------------------------*/
/* Save product (ENTER key equivalent)                             */
/*----------------------------------------------------------------*/
dcl-proc saveProduct;

   /* Screen RECEIVE already populated via DSPF */

   buildProductRecord();

   if wsUpdateFlag = 'Y';
      update AXAPROD;
   else;
      write AXAPROD;
   endif;

   returnPlacement();

end-proc;

/*----------------------------------------------------------------*/
/* Build product record                                           */
/*----------------------------------------------------------------*/
dcl-proc buildProductRecord;

   Product_Name     = PRODNMI;
   Product_Type     = PRODTYPEI;
   Coverage_Limit   = COVLIMITI;
   Deductible       = DEDUCTI;
   Premium          = PREMIUMI;
   Placement_ID     = PLCMTIDI;
   Product_Status   = 'ACTIVE';

   if wsUpdateFlag = 'N';
      Product_ID = %subst(%char(%date()):9:6);
   endif;

end-proc;

/*----------------------------------------------------------------*/
/* Send map                                                       */
/*----------------------------------------------------------------*/
dcl-proc sendMap;

   if wsUpdateFlag = 'Y';
      PRODNMO     = Product_Name;
      PRODTYPEO   = Product_Type;
      COVLIMITO   = Coverage_Limit;
      DEDUCTO     = Deductible;
      PREMIUMO    = Premium;
   endif;

   /* EXFMT would normally be used here in real DSPF programs */

end-proc;

/*----------------------------------------------------------------*/
/* Navigate to product details                                    */
/*----------------------------------------------------------------*/
dcl-proc productDetails;
   pCommArea = Product_ID + %subst(pCommArea:11);
   callp ProdDet(pCommArea);
end-proc;

/*----------------------------------------------------------------*/
/* Return                                                         */
/*----------------------------------------------------------------*/
dcl-proc returnPlacement;
   return;
end-proc;
