**FREE
ctl-opt dftactgrp(*no) actgrp(*caller);

// ==========================
// Files
// ==========================
dcl-f PRODSCR   workstn;
dcl-f AXAPROD   usage(*update) keyed;

// ==========================
// State
// ==========================
dcl-s ProductKey   char(10);
dcl-s UpdateFlag   char(1) inz('N');

// ==========================
// Product record (COPY PRODUCT)
// ==========================
dcl-ds Product qualified;
   ProductId       char(10);
   ProductName     char(30);
   ProductType     char(20);
   CoverageLimit   char(15);
   Deductible      char(12);
   Premium         char(12);
   PlacementId     char(10);
   ProductStatus   char(10);
end-ds;

// ==========================
// Parameter (COMMAREA)
// ==========================
dcl-pi *n;
   pCommArea char(100) options(*varsize);
end-pi;

ProductKey = %subst(pCommArea:1:10);

// ==========================
// Read existing product
// ==========================
if %trim(ProductKey) <> '';
   chain ProductKey AXAPROD;
   if %found;
      UpdateFlag = 'Y';

      // Load screen from record
      PRODNM   = ProductName;
      PRODTYPE = ProductType;
      COVLIMIT = CoverageLimit;
      DEDUCT   = Deductible;
      PREMIUM  = Premium;
      PLCMTID  = PlacementId;
   endif;
endif;

// ==========================
// Main loop
// ==========================
dow *in03 = *off;

   exfmt PRODMAP;

   if *in12;                 // PF12 = Clear
      clear PRODNM;
      clear PRODTYPE;
      clear COVLIMIT;
      clear DEDUCT;
      clear PREMIUM;
      iter;
   endif;

   if *in02;                 // PF2 = Details
      pCommArea = ProductId;
      *inlr = *on;
      call 'PRODDET' (pCommArea);
      return;
   endif;

   if *in03;                 // PF3 = Cancel
      *inlr = *on;
      return;
   endif;

   if *in01;                 // ENTER = Save
      callp SaveProduct();
      *inlr = *on;
      return;
   endif;

enddo;

*inlr = *on;
return;

// =======================================
// Save product (insert/update)
// =======================================
dcl-proc SaveProduct;

   // Build record from screen
   ProductName   = PRODNM;
   ProductType   = PRODTYPE;
   CoverageLimit = COVLIMIT;
   Deductible    = DEDUCT;
   Premium       = PREMIUM;
   PlacementId   = PLCMTID;
   ProductStatus = 'ACTIVE';

   if UpdateFlag = 'Y';
      update AXAPROD;
   else;
      // Generate new product ID (same logic as COBOL)
      ProductId = %subst(%char(%timestamp():*ISO0):9:6);
      write AXAPROD;
   endif;

end-proc;
