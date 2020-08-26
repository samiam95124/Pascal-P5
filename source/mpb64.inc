{******************************************************************************

64 bit Machine Parameter block (MPB)

******************************************************************************}

#ifdef LENDIAN
      lendian     =     true;   { endian mode }
#else
      lendian     =    false;   { endian mode }
#endif
      intsize     =        8;   { size of integer }
      intal       =        4;   { alignment of integer }
      intdig      =        20;  { number of decimal digits in integer }
      inthex      =        16;  { number of hex digits of integer }
      realsize    =        8;   { size of real }
      realal      =        4;   { alignment of real }
      charsize    =        1;   { size of char }
      charal      =        1;   { alignment of char }
      charmax     =        1;
      boolsize    =        1;   { size of boolean }
      boolal      =        1;   { alignment of boolean }
      ptrsize     =        8;   { size of pointer }
      adrsize     =        8;   { size of address }
      adral       =        4;   { alignment of address }
      setsize     =       32;   { size of set }
      setal       =        1;   { alignment of set }
      filesize    =        1;   { required runtime space for file (lfn) }
      fileidsize  =        1;   { size of the lfn only }
      fileal      =        1;   { alignment of file lfn }
      exceptsize  =        1;   { size of exception variable }
      exceptal    =        1;
      stackal     =        8;   { alignment of stack }
      stackelsize =        8;   { stack element size }
      maxsize     =       32;   { this is the largest type that can be on
                                  the stack }
      { Heap alignment should be either the natural word alignment of the
        machine, or the largest object needing alignment that will be allocated.
        It can also be used to enforce minimum block allocation policy. }
      heapal      =        4;   { alignment for each heap arena }
      gbsal       =        4;   { globals area alignment }
      sethigh     =      255;   { Sets are 256 values }
      setlow      =        0;
      ordmaxchar  =      255;   { Characters are 8 bit ISO/IEC 8859-1 }
      ordminchar  =        0;
      maxresult   = realsize;   { maximum size of function result }
      marksize    =       64;   { 6*ptrsize }
      maxexp      =      308;   { maximum exponent of real }
      { Value of nil is 1 because this allows checks for pointers that were
        initialized, which would be zero (since we clear all space to zero).
        In the new unified code/data space scheme, 0 and 1 are always invalid
        addresses, since the startup code is at least that long. }
      nilval      =        1;  { value of 'nil' }

      { beginning of code, offset by program preamble:

        2:    mst
        4:    cup
        1:    stp

      }
      begincode   =        10;

      { Mark element offsets

        Mark format is:

        -8:  Function value.
        -16: Static link.
        -24: Dynamic link.
        -32: Saved EP from previous frame.
        -40: Stack bottom after locals allocate. Used for interprocdural gotos.
        -48: EP from current frame. Used for interprocedural gotos.
        -56: With stack base count.
        -64: Return address.

      }
      markfv      =        -8;  { function value }
      marksl      =        -16; { static link }
      markdl      =        -24; { dynamic link }
      markep      =        -32; { (old) maximum frame size }
      marksb      =        -40; { stack bottom }
      market      =        -48; { current ep }
      markwb      =        -56; { with stack base count }
      markra      =        -64; { return address }
