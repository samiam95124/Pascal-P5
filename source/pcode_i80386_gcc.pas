(*$c+,t-,d-,l-*)
{*******************************************************************************
*                                                                              *
*                           Portable Pascal compiler                           *
*                           ************************                           *
*                                                                              *
*                                 Pascal P5                                    *
*                                                                              *
*                                 ETH May 76                                   *
*                                                                              *
* Authors:                                                                     *
*                                                                              *
*    Urs Ammann                                                                *
*    Kesav Nori                                                                *
*    Christian Jacobi                                                          *
*    K. Jensen                                                                 *
*    N. Wirth                                                                  *
*                                                                              *
* Address:                                                                     *
*                                                                              *
*    Institut Fuer Informatik                                                  *
*    Eidg. Technische Hochschule                                               *
*    CH-8096 Zuerich                                                           *
*                                                                              *
*  This code is fully documented in the book                                   *
*        "Pascal Implementation"                                               *
*   by Steven Pemberton and Martin Daniels                                     *
* published by Ellis Horwood, Chichester, UK                                   *
*         ISBN: 0-13-653-0311                                                  *
*       (also available in Japanese)                                           *
*                                                                              *
* Steven Pemberton, CWI/AA,                                                    *
* Kruislaan 413, 1098 SJ Amsterdam, NL                                         *
* Steven.Pemberton@cwi.nl                                                      *
*                                                                              *
* This module generates code for the following machine conventions:            *
*                                                                              *
* Machine type:       I80386 (Intel 80386 32 bit)                              *
* Assembler:          gas (GNU Assembler)                                      *
* Calling convention: gcc (GNU C Compiler)                                     *
*                                                                              *
* The program is based on pint.pas as a skeleton. Instead of generating and    *
* interpreting intermediate codes, it generates an assembly language module    *
* that is designed to be linked together with a small support library in C     *
* that implements its system interface.                                        *
*                                                                              *
* The layout of the final program in memory is:                                *
*                                                                              *
*              ---------------------                                           *
*              | Stack             |                                           *
*       esp -> ---------------------                                           *
*              | Unused space      |                                           *
*              ---------------------                                           *
*              | Heap              |                                           *
*              ---------------------                                           *
*              | Constants         |                                           *
*              ---------------------                                           *
*              | Pascal Code       |                                           *
*              ---------------------                                           *
*              | C support library |                                           *
*              ---------------------                                           *
*                                                                              *
* Ie., pretty conventional. The calls from the generated code to the C support *
* library are performed to implement things like read and write, and they are  *
* preceeded by "__" (two underscores) to differentiate them from standard      *
* routines. The routine names in Pascal are all generated with a leading "_"   *
* (single underscore). This is the standard convention in GCC. See the         *
* documentation for the exact format and naming of the C library support       *
* routines.                                                                    *
*                                                                              *
* The GCC calling convention (everything on the stack, returns in edx/eax) is  *
* followed in routine calls, but in this version that is incidental, since     *
* there is no facility to directly call C programs from Pascal. The system/    *
* library calls also use the convention, but they are custom constructed in    *
* any cause. This ability may be used to create a Pascal to C and/or C to      *
* Pascal call facility later.                                                  *
*                                                                              *
* The generated program does not have a "main" per sey. Instead, it leaves     *
* that to the support library. The main program is marked with a label         *
* "__pascal_main" to allow the support library to call it. This arrangement    *
* allows the support library to initialize itself without needing a pragma.    *
*                                                                              *
* The code is generated using substantially the same data formats and runtime  *
* methods as the interpreter. It uses stack based display information and      *
* level climbing. Instead of collecting labels as the interpreter does, we     *
* generate labels on the spot and let the assembler track and link them. For   *
* the constant table, we generate coined labels on the first pass, then rewind *
* the intermediate and perform another pass to collect and output the          *
* constants. We don't weave constants into the code between the routines, as   *
* is a common gcc convention. Rather, we dump them at the end of the file.     *
*                                                                              *
* The input intermediate code is stack oriented. We encode by using a "stack", *
* which is used to track what results are being processed, rather than         *
* carrying the actual results themselves. Each entry tracks the registered/    *
* on stack status of each argument. Entries are created and retired according  *
* to the rules for intermediate code.                                          *
*                                                                              *
* The program as output is designed to be compiled and linked with a line      *
* like:                                                                        *
*                                                                              *
* gcc -o myprogram pascal_support.c myprogram.s                                *
*                                                                              *
* Thus the support library is compiled and linked from C, and the Pascal       *
* target program is simply an assembly language module after that.             *
*                                                                              *
* Naming convention                                                            *
*                                                                              *
* The naming convention of the code generator modules is as follows:           *
*                                                                              *
* pcode_<machine>_<calling convention>                                         *
*                                                                              *
* The major tree branch is the target machine, followed by the type of         *
* compiler we are working with. We don't use just pcode_i80386_gas because     *
* both the assembly conventions of gas are used along with the calling         *
* convention. This changes with the machine. For example, pcode_arm_gcc        *
* would be both an assembly language change and a calling convention change.   *
*                                                                              *
* Finally, it is not the purpose of this module to create a complete and       *
* general purpose compiler. It was included in Pascal-P5 because the choices   *
* of available ISO 7185 true compilers is shrinking (as indeed happened before *
* in the early 1990's). Thus it seems better to allow Pascal-P5 to self        *
* bootstrap now rather than later.                                             *
*                                                                              *
* For those who are interested in a full, general purpose ISO 7185 Pascal      *
* compiler, I recommend you look to the Pascal-P6 project.                     *
*                                                                              *
*******************************************************************************}

program pcodei8036gcc(input,output,prd,prr);

label 1;

const

      { ************************************************************************

      Program object sizes and characteristics, sync with pint. These define
      the machine specific characteristics of the target.

      The configurations are as follows:

      type                  #bits 32  #bits 64
      ===========================================================
      integer               32        64
      real                  64        64
      char                  8         8
      boolean               8         8
      set                   256       256
      pointers              32        64
      marks                 32        64
      File logical number   8         8

      Both endian types are supported. There is no alignment needed, but you
      may wish to use alignment to tune the runtime speed.

      The machine characteristics dependent on byte accessable machines. This
      table is all you should need to adapt to any byte addressable machine.

      }

      { type               #32 #64 }
      intsize     =        4   {8};  { size of integer }
      intal       =        4;        { alignment of integer }
      intdig      =        11  {20}; { number of decimal digits in integer }
      inthex      =        8   {16}; { number of hex digits of integer }
      realsize    =        8;        { size of real }
      realal      =        4;        { alignment of real }
      charsize    =        1;        { size of char }
      charal      =        1;        { alignment of char }
      charmax     =        1;
      boolsize    =        1;        { size of boolean }
      boolal      =        1;        { alignment of boolean }
      ptrsize     =        4   {8};  { size of pointer }
      adrsize     =        4   {8};  { size of address }
      adral       =        4;        { alignment of address }
      setsize     =       32;        { size of set }
      setal       =        1;        { alignment of set }
      filesize    =        1;        { required runtime space for file (lfn) }
      fileidsize  =        1;        { size of the lfn only }
      stackal     =        4;        { alignment of stack }
      stackelsize =        4   {8};  { stack element size }
      maxsize     =       32;        { this is the largest type that can be on
                                       the stack }
      { Heap alignment should be either the natural word alignment of the
        machine, or the largest object needing alignment that will be allocated.
        It can also be used to enforce minimum block allocation policy. }
      heapal      =        4;        { alignment for each heap arena }
      sethigh     =      255;        { Sets are 256 values }
      setlow      =        0;
      ordmaxchar  =      255;        { Characters are 8 bit ISO/IEC 8859-1 }
      ordminchar  =        0;
      maxresult   = realsize;        { maximum size of function result }
      marksize    =       32   {56}; { maxresult+6*ptrsize }
      { Value of nil is 1 because this allows checks for pointers that were
        initialized, which would be zero (since we clear all space to zero).
        In the new unified code/data space scheme, 0 and 1 are always invalid
        addresses, since the startup code is at least that long. }
      nilval      =        1;  { value of 'nil' }
      { beginning of code, offset by program preamble:

        2:    mst
        6/10: cup
        1:    stp

      }
      begincode   =        9   {13};

      { Mark element offsets

        Mark format is:

        0:  Function return value, 64 bits, enables a full real result.
        8:  Static link.
        12: Dynamic link.
        16: Saved EP from previous frame.
        20: Stack bottom after locals allocate. Used for interprocdural gotos.
        24: EP from current frame. Used for interprocedural gotos.
        28: Return address

      }
      markfv      =        0   {0};  { function value }
      marksl      =        8   {8};  { static link }
      markdl      =        12  {16}; { dynamic link }
      markep      =        16  {24}; { (old) maximum frame size }
      marksb      =        20  {32}; { stack bottom }
      market      =        24  {40}; { current ep }
      markra      =        28  {48}; { return address }

      { ******************* end of pcom and pint common parameters *********** }

      { internal constants }

      { !!! Need to use the small size memory to self compile, otherwise, by
        definition, pint cannot fit into its own memory. }
      {elide}maxstr      = 16777215;{noelide}  { maximum size of addressing for program/var }
      {remove maxstr     =  2000000; remove}  { maximum size of addressing for program/var }
      maxdef      = 2097152; { maxstr / 8 for defined bits }
      maxdigh     = 6;       { number of digits in hex representation of maxstr }
      maxdigd     = 8;       { number of digits in decimal representation of maxstr }

      codemax     = maxstr;  { set size of code store to maximum possible }
      pcmax       = codemax; { set size of pc as same }

      maxlabel = 5000;       { total possible labels in intermediate }
      resspc   = 0;          { reserve space in heap (if you want) }

      { locations of header files after program block mark, each header
        file is two values, a file number and a single character buffer }
      inputoff  = 0;         { 'input' file address }
      outputoff = 2;         { 'output' file address }
      prdoff    = 4;         { 'prd' file address }
      prroff    = 6;         { 'prr' file address }

      { assigned logical channels for header files }
      inputfn    = 1;        { 'input' file no. }
      outputfn   = 2;        { 'output' file no. }
      prdfn      = 3;        { 'prd' file no. }
      prrfn      = 4;        { 'prr' file no. }

      stringlgth  = 1000;    { longest string length we can buffer }
      maxsp       = 44;      { number of predefined procedures/functions }
      maxins      = 255;     { maximum instruction code, 0-255 or byte }
      maxfil      = 100;     { maximum number of general (temp) files }
      maxalfa     = 10;      { maximum number of characters in alfa type }
      ujplen      = 5;       { length of ujp instruction (used for case jumps) }
      
      stkmax      = 1000;    { depth of evaluation stack }

      { check flags: these turn on runtime checks }
      dochkovf    = true;    { check arithmetic overflow }

      { debug flags: turn these on for various dumps and traces }

      dodmpins    = false;    { dump instructions after assembly }
      dodmplab    = false;    { dump label definitions }
      dodmpsto    = false;    { dump storage area specs }
      dotrcrot    = false;    { trace routine executions }
      dotrcins    = false;    { trace instruction executions }
      dopmd       = true{false};    { perform post-mortem dump on error }
      dosrclin    = true;     { add source line sets to code }
      dotrcsrc    = false;    { trace source line executions (requires dosrclin) }
      dodmpspc    = false;    { dump heap space after execution }
      dorecycl    = true;     { obey heap space recycle requests }
      { invoke a special recycle mode that creates single word entries on
        recycle of any object, breaking off and recycling the rest. Once
        allocated, each entry exists forever, and accesses to it can be
        checked. }
      dochkrpt    = true{false};    { check reuse of freed entry (automatically
                                invokes dorecycl = false }
      dochkdef    = true;     { check undefined accesses }

      { version numbers }

      majorver   = 1; { major version number }
      minorver   = 2; { minor version number }

type
      { These equates define the instruction layout. I have choosen a 32 bit
        layout for the instructions defined by (4 bit) digit:

           byte 0:   Instruction code
           byte 1:   P parameter
           byte 2-5: Q parameter

        This means that there are 256 instructions, 256 procedure levels,
        and 2gb of total addressing. This could be 4gb if we get rid of the
        need for negatives. }
      lvltyp      = 0..255;     { procedure/function level }
      instyp      = 0..maxins;  { instruction }
      address     = -maxstr..maxstr; { address }

      datatype    = (undef,int,reel,bool,sett,adr,mark,car);
      beta        = packed array[1..25] of char; (*error message*)
      settype     = set of setlow..sethigh;
      alfainx     = 1..maxalfa; { index for alfa type }
      alfa        = packed array[alfainx] of char;
      byte        = 0..255; { 8-bit byte }
      bytfil      = packed file of byte; { untyped file of bytes }
      fileno      = 0..maxfil; { logical file number }
      { general purpose registers}
      register    = (rgnone, rgstack, rgeax, rgebx, rgecx, rgedx, rgesi, rgedi);
      datatrack   = record { data tracking stack entry }
                      r: register; { register it occupies }
                    end;
      stkinx      = 1..stkmax; { index for data stack }

var   pc          : address;   (*program address register*)
      pctop,lsttop: address;   { top of code store }
      op : instyp; p : lvltyp; q : address;  (*instruction register*)
      q1: address; { extra parameter }
      store       : packed array [0..maxstr] of byte; { complete program storage }
      storedef    : packed array [0..maxdef] of byte; { defined bits }
      cp          : address;  (* pointer to next free constant position *)
      mp,sp,np,ep : address;  (* address registers *)
      (*mp  points to beginning of a data segment
        sp  points to top of the stack
        ep  points to the maximum extent of the stack
        np  points to top of the dynamically allocated area*)
      bitmsk      : packed array [0..7] of byte; { bits in byte }

      interpreting: boolean;

      { !!! remove this next statement for self compile }
      {elide}prd,prr     : text;{noelide}(*prd for read only, prr for write only *)

      instr       : array[instyp] of alfa; (* mnemonic instruction codes *)
      sptable     : array[0..maxsp] of alfa; (*standard functions and procedures*)
      insp        : array[instyp] of boolean; { instruction includes a p parameter }
      insq        : array[instyp] of 0..16; { length of q parameter }
      srclin      : integer; { current source line executing }

      filtable    : array [1..maxfil] of text; { general (temp) text file holders }
      { general (temp) binary file holders }
      bfiltable   : array [1..maxfil] of bytfil;
      { file state holding }
      filstate    : array [1..maxfil] of (fclosed, fread, fwrite);
      { file buffer full status }
      filbuff     : array [1..maxfil] of boolean;
      
      datstk      : array 1..stkmax] of datatrack; { data tracking stack }
      stktop      : 1..stkmax; { stack top }
      regfre      : array [register] of boolean; { free register tracking }

      (*locally used for interpreting one instruction*)
      ad,ad1,ad2,
      ad3         : address;
      b           : boolean;
      i,j,k,i1,i2 : integer;
      c           : char;
      i3, i4      : integer;
      pa          : integer;
      r1, r2      : real;
      b1, b2      : boolean;
      s1, s2      : settype;
      c1, c2      : char;
      a1, a2, a3  : address;
      fn          : fileno;
      pcs         : address;
      bai         : integer;

(*--------------------------------------------------------------------*)

{ Low level error check and handling }

{ print in hex (carefull, it chops high digits freely!) }

procedure wrthex(v: integer; { value } f: integer { field });
var p,i,d: integer;
begin
   p := 1;
   for i := 1 to f-1 do p := p*16;
   while p > 0 do begin
      d := v div p mod 16; { extract digit }
      if d < 10 then write(chr(d+ord('0')))
      else write(chr(d-10+ord('A')));
      p := p div 16
   end
end;

{ align address, upwards }

procedure alignu(algn: address; var flc: address);
  var l: integer;
begin
  l := flc-1;
  flc := l + algn  -  (algn+l) mod algn
end (*align*);

{ align address, downwards }

procedure alignd(algn: address; var flc: address);
  var l: integer;
begin
  l := flc+1;
  flc := l - algn  +  (algn-l) mod algn
end (*align*);

(*--------------------------------------------------------------------*)

{ generate code }

procedure genprg;
   type  labelst  = (entered,defined); (*label situation*)
         labelrg  = 0..maxlabel;       (*label range*)
         labelrec = record
                          val: address;
                           st: labelst
                    end;
   var  word : array[alfainx] of char; ch  : char;
        labeltab: array[labelrg] of labelrec;
        labelvalue: address;
        iline: integer; { line number of intermediate file }

   procedure init;
      var i: integer;
   begin for i := 0 to maxins do instr[i] := '          ';
         {

           Notes:

           1. Instructions marked with "*" are for internal use only.
              The "*" mark both shows in the listing, and also prevents
              their use in the intermediate file, since only alpha
              characters are allowed as opcode labels.

           2. "---" entries are no longer used, but left here to keep the
              original instruction numbers from P4. They could be safely
              assigned to other instructions if the space is needed.

         }
         instr[  0]:='lodi      '; insp[  0] := true;  insq[  0] := intsize;
         instr[  1]:='ldoi      '; insp[  1] := false; insq[  1] := intsize;
         instr[  2]:='stri      '; insp[  2] := true;  insq[  2] := intsize;
         instr[  3]:='sroi      '; insp[  3] := false; insq[  3] := intsize;
         instr[  4]:='lda       '; insp[  4] := true;  insq[  4] := intsize;
         instr[  5]:='lao       '; insp[  5] := false; insq[  5] := intsize;
         instr[  6]:='stoi      '; insp[  6] := false; insq[  6] := 0;
         instr[  7]:='ldcs      '; insp[  7] := false; insq[  7] := intsize;
         instr[  8]:='---       '; insp[  8] := false; insq[  8] := 0;
         instr[  9]:='indi      '; insp[  9] := false; insq[  9] := intsize;
         instr[ 10]:='inci      '; insp[ 10] := false; insq[ 10] := intsize;
         instr[ 11]:='mst       '; insp[ 11] := true;  insq[ 11] := 0;
         instr[ 12]:='cup       '; insp[ 12] := true;  insq[ 12] := intsize;
         instr[ 13]:='ents      '; insp[ 13] := false; insq[ 13] := intsize;
         instr[ 14]:='retp      '; insp[ 14] := false; insq[ 14] := 0;
         instr[ 15]:='csp       '; insp[ 15] := false; insq[ 15] := 1;
         instr[ 16]:='ixa       '; insp[ 16] := false; insq[ 16] := intsize;
         instr[ 17]:='equa      '; insp[ 17] := false; insq[ 17] := 0;
         instr[ 18]:='neqa      '; insp[ 18] := false; insq[ 18] := 0;
         instr[ 19]:='---       '; insp[ 19] := false; insq[ 19] := 0;
         instr[ 20]:='---       '; insp[ 20] := false; insq[ 20] := 0;
         instr[ 21]:='---       '; insp[ 21] := false; insq[ 21] := 0;
         instr[ 22]:='---       '; insp[ 22] := false; insq[ 22] := 0;
         instr[ 23]:='ujp       '; insp[ 23] := false; insq[ 23] := intsize;
         instr[ 24]:='fjp       '; insp[ 24] := false; insq[ 24] := intsize;
         instr[ 25]:='xjp       '; insp[ 25] := false; insq[ 25] := intsize;
         instr[ 26]:='chki      '; insp[ 26] := false; insq[ 26] := intsize;
         instr[ 27]:='---       '; insp[ 27] := false; insq[ 27] := 0;
         instr[ 28]:='adi       '; insp[ 28] := false; insq[ 28] := 0;
         instr[ 29]:='adr       '; insp[ 29] := false; insq[ 29] := 0;
         instr[ 30]:='sbi       '; insp[ 30] := false; insq[ 30] := 0;
         instr[ 31]:='sbr       '; insp[ 31] := false; insq[ 31] := 0;
         instr[ 32]:='sgs       '; insp[ 32] := false; insq[ 32] := 0;
         instr[ 33]:='flt       '; insp[ 33] := false; insq[ 33] := 0;
         instr[ 34]:='flo       '; insp[ 34] := false; insq[ 34] := 0;
         instr[ 35]:='trc       '; insp[ 35] := false; insq[ 35] := 0;
         instr[ 36]:='ngi       '; insp[ 36] := false; insq[ 36] := 0;
         instr[ 37]:='ngr       '; insp[ 37] := false; insq[ 37] := 0;
         instr[ 38]:='sqi       '; insp[ 38] := false; insq[ 38] := 0;
         instr[ 39]:='sqr       '; insp[ 39] := false; insq[ 39] := 0;
         instr[ 40]:='abi       '; insp[ 40] := false; insq[ 40] := 0;
         instr[ 41]:='abr       '; insp[ 41] := false; insq[ 41] := 0;
         instr[ 42]:='not       '; insp[ 42] := false; insq[ 42] := 0;
         instr[ 43]:='and       '; insp[ 43] := false; insq[ 43] := 0;
         instr[ 44]:='ior       '; insp[ 44] := false; insq[ 44] := 0;
         instr[ 45]:='dif       '; insp[ 45] := false; insq[ 45] := 0;
         instr[ 46]:='int       '; insp[ 46] := false; insq[ 46] := 0;
         instr[ 47]:='uni       '; insp[ 47] := false; insq[ 47] := 0;
         instr[ 48]:='inn       '; insp[ 48] := false; insq[ 48] := 0;
         instr[ 49]:='mod       '; insp[ 49] := false; insq[ 49] := 0;
         instr[ 50]:='odd       '; insp[ 50] := false; insq[ 50] := 0;
         instr[ 51]:='mpi       '; insp[ 51] := false; insq[ 51] := 0;
         instr[ 52]:='mpr       '; insp[ 52] := false; insq[ 52] := 0;
         instr[ 53]:='dvi       '; insp[ 53] := false; insq[ 53] := 0;
         instr[ 54]:='dvr       '; insp[ 54] := false; insq[ 54] := 0;
         instr[ 55]:='mov       '; insp[ 55] := false; insq[ 55] := intsize;
         instr[ 56]:='lca       '; insp[ 56] := false; insq[ 56] := intsize;
         instr[ 57]:='deci      '; insp[ 57] := false; insq[ 57] := intsize;
         instr[ 58]:='stp       '; insp[ 58] := false; insq[ 58] := 0;
         instr[ 59]:='ordi      '; insp[ 59] := false; insq[ 59] := 0;
         instr[ 60]:='chr       '; insp[ 60] := false; insq[ 60] := 0;
         instr[ 61]:='ujc       '; insp[ 61] := false; insq[ 61] := intsize;
         instr[ 62]:='rnd       '; insp[ 62] := false; insq[ 62] := 0;
         instr[ 63]:='pck       '; insp[ 63] := false; insq[ 63] := intsize*2;
         instr[ 64]:='upk       '; insp[ 64] := false; insq[ 64] := intsize*2;
         instr[ 65]:='ldoa      '; insp[ 65] := false; insq[ 65] := intsize;
         instr[ 66]:='ldor      '; insp[ 66] := false; insq[ 66] := intsize;
         instr[ 67]:='ldos      '; insp[ 67] := false; insq[ 67] := intsize;
         instr[ 68]:='ldob      '; insp[ 68] := false; insq[ 68] := intsize;
         instr[ 69]:='ldoc      '; insp[ 69] := false; insq[ 69] := intsize;
         instr[ 70]:='stra      '; insp[ 70] := true;  insq[ 70] := intsize;
         instr[ 71]:='strr      '; insp[ 71] := true;  insq[ 71] := intsize;
         instr[ 72]:='strs      '; insp[ 72] := true;  insq[ 72] := intsize;
         instr[ 73]:='strb      '; insp[ 73] := true;  insq[ 73] := intsize;
         instr[ 74]:='strc      '; insp[ 74] := true;  insq[ 74] := intsize;
         instr[ 75]:='sroa      '; insp[ 75] := false; insq[ 75] := intsize;
         instr[ 76]:='sror      '; insp[ 76] := false; insq[ 76] := intsize;
         instr[ 77]:='sros      '; insp[ 77] := false; insq[ 77] := intsize;
         instr[ 78]:='srob      '; insp[ 78] := false; insq[ 78] := intsize;
         instr[ 79]:='sroc      '; insp[ 79] := false; insq[ 79] := intsize;
         instr[ 80]:='stoa      '; insp[ 80] := false; insq[ 80] := 0;
         instr[ 81]:='stor      '; insp[ 81] := false; insq[ 81] := 0;
         instr[ 82]:='stos      '; insp[ 82] := false; insq[ 82] := 0;
         instr[ 83]:='stob      '; insp[ 83] := false; insq[ 83] := 0;
         instr[ 84]:='stoc      '; insp[ 84] := false; insq[ 84] := 0;
         instr[ 85]:='inda      '; insp[ 85] := false; insq[ 85] := intsize;
         instr[ 86]:='indr      '; insp[ 86] := false; insq[ 86] := intsize;
         instr[ 87]:='inds      '; insp[ 87] := false; insq[ 87] := intsize;
         instr[ 88]:='indb      '; insp[ 88] := false; insq[ 88] := intsize;
         instr[ 89]:='indc      '; insp[ 89] := false; insq[ 89] := intsize;
         instr[ 90]:='inca      '; insp[ 90] := false; insq[ 90] := intsize;
         instr[ 91]:='---       '; insp[ 91] := false; insq[ 91] := intsize;
         instr[ 92]:='---       '; insp[ 92] := false; insq[ 92] := intsize;
         instr[ 93]:='incb      '; insp[ 93] := false; insq[ 93] := intsize;
         instr[ 94]:='incc      '; insp[ 94] := false; insq[ 94] := intsize;
         instr[ 95]:='chka      '; insp[ 95] := false; insq[ 95] := intsize;
         instr[ 96]:='---       '; insp[ 96] := false; insq[ 96] := intsize;
         instr[ 97]:='chks      '; insp[ 97] := false; insq[ 97] := intsize;
         instr[ 98]:='chkb      '; insp[ 98] := false; insq[ 98] := intsize;
         instr[ 99]:='chkc      '; insp[ 99] := false; insq[ 99] := intsize;
         instr[100]:='---       '; insp[100] := false; insq[100] := intsize;
         instr[101]:='---       '; insp[101] := false; insq[101] := intsize;
         instr[102]:='---       '; insp[102] := false; insq[102] := intsize;
         instr[103]:='decb      '; insp[103] := false; insq[103] := intsize;
         instr[104]:='decc      '; insp[104] := false; insq[104] := intsize;
         instr[105]:='loda      '; insp[105] := true;  insq[105] := intsize;
         instr[106]:='lodr      '; insp[106] := true;  insq[106] := intsize;
         instr[107]:='lods      '; insp[107] := true;  insq[107] := intsize;
         instr[108]:='lodb      '; insp[108] := true;  insq[108] := intsize;
         instr[109]:='lodc      '; insp[109] := true;  insq[109] := intsize;
         instr[110]:='rgs       '; insp[110] := false; insq[110] := 0;
         instr[111]:='---       '; insp[111] := false; insq[111] := 0;
         instr[112]:='ipj       '; insp[112] := true;  insq[112] := intsize;
         instr[113]:='cip       '; insp[113] := true;  insq[113] := 0;
         instr[114]:='lpa       '; insp[114] := true;  insq[114] := intsize;
         instr[115]:='---       '; insp[115] := false; insq[115] := 0;
         instr[116]:='---       '; insp[116] := false; insq[116] := 0;
         instr[117]:='dmp       '; insp[117] := false; insq[117] := intsize;
         instr[118]:='swp       '; insp[118] := false; insq[118] := intsize;
         instr[119]:='tjp       '; insp[119] := false; insq[119] := intsize;
         instr[120]:='lip       '; insp[120] := true;  insq[120] := intsize;
         instr[121]:='---       '; insp[121] := false; insq[121] := 0;
         instr[122]:='---       '; insp[122] := false; insq[122] := 0;
         instr[123]:='ldci      '; insp[123] := false; insq[123] := intsize;
         instr[124]:='ldcr      '; insp[124] := false; insq[124] := intsize;
         instr[125]:='ldcn      '; insp[125] := false; insq[125] := 0;
         instr[126]:='ldcb      '; insp[126] := false; insq[126] := boolsize;
         instr[127]:='ldcc      '; insp[127] := false; insq[127] := charsize;
         instr[128]:='reti      '; insp[128] := false; insq[128] := 0;
         instr[129]:='retr      '; insp[129] := false; insq[129] := 0;
         instr[130]:='retc      '; insp[130] := false; insq[130] := 0;
         instr[131]:='retb      '; insp[131] := false; insq[131] := 0;
         instr[132]:='reta      '; insp[132] := false; insq[132] := 0;
         instr[133]:='---       '; insp[133] := false; insq[133] := 0;
         instr[134]:='ordb      '; insp[134] := false; insq[134] := 0;
         instr[135]:='---       '; insp[135] := false; insq[135] := 0;
         instr[136]:='ordc      '; insp[136] := false; insq[136] := 0;
         instr[137]:='equi      '; insp[137] := false; insq[137] := 0;
         instr[138]:='equr      '; insp[138] := false; insq[138] := 0;
         instr[139]:='equb      '; insp[139] := false; insq[139] := 0;
         instr[140]:='equs      '; insp[140] := false; insq[140] := 0;
         instr[141]:='equc      '; insp[141] := false; insq[141] := 0;
         instr[142]:='equm      '; insp[142] := false; insq[142] := intsize;
         instr[143]:='neqi      '; insp[143] := false; insq[143] := 0;
         instr[144]:='neqr      '; insp[144] := false; insq[144] := 0;
         instr[145]:='neqb      '; insp[145] := false; insq[145] := 0;
         instr[146]:='neqs      '; insp[146] := false; insq[146] := 0;
         instr[147]:='neqc      '; insp[147] := false; insq[147] := 0;
         instr[148]:='neqm      '; insp[148] := false; insq[148] := intsize;
         instr[149]:='geqi      '; insp[149] := false; insq[149] := 0;
         instr[150]:='geqr      '; insp[150] := false; insq[150] := 0;
         instr[151]:='geqb      '; insp[151] := false; insq[151] := 0;
         instr[152]:='geqs      '; insp[152] := false; insq[152] := 0;
         instr[153]:='geqc      '; insp[153] := false; insq[153] := 0;
         instr[154]:='geqm      '; insp[154] := false; insq[154] := intsize;
         instr[155]:='grti      '; insp[155] := false; insq[155] := 0;
         instr[156]:='grtr      '; insp[156] := false; insq[156] := 0;
         instr[157]:='grtb      '; insp[157] := false; insq[157] := 0;
         instr[158]:='grts      '; insp[158] := false; insq[158] := 0;
         instr[159]:='grtc      '; insp[159] := false; insq[159] := 0;
         instr[160]:='grtm      '; insp[160] := false; insq[160] := intsize;
         instr[161]:='leqi      '; insp[161] := false; insq[161] := 0;
         instr[162]:='leqr      '; insp[162] := false; insq[162] := 0;
         instr[163]:='leqb      '; insp[163] := false; insq[163] := 0;
         instr[164]:='leqs      '; insp[164] := false; insq[164] := 0;
         instr[165]:='leqc      '; insp[165] := false; insq[165] := 0;
         instr[166]:='leqm      '; insp[166] := false; insq[166] := intsize;
         instr[167]:='lesi      '; insp[167] := false; insq[167] := 0;
         instr[168]:='lesr      '; insp[168] := false; insq[168] := 0;
         instr[169]:='lesb      '; insp[169] := false; insq[169] := 0;
         instr[170]:='less      '; insp[170] := false; insq[170] := 0;
         instr[171]:='lesc      '; insp[171] := false; insq[171] := 0;
         instr[172]:='lesm      '; insp[172] := false; insq[172] := intsize;
         instr[173]:='ente      '; insp[173] := false; insq[173] := intsize;
         instr[174]:='mrkl*     '; insp[174] := false; insq[174] := intsize;
         instr[175]:='ckvi      '; insp[175] := false; insq[175] := intsize;
         instr[176]:='---       '; insp[176] := false; insq[176] := intsize;
         instr[177]:='---       '; insp[177] := false; insq[177] := intsize;
         instr[178]:='---       '; insp[178] := false; insq[178] := intsize;
         instr[179]:='ckvb      '; insp[179] := false; insq[179] := intsize;
         instr[180]:='ckvc      '; insp[180] := false; insq[180] := intsize;
         instr[181]:='dupi      '; insp[181] := false; insq[181] := 0;
         instr[182]:='dupa      '; insp[182] := false; insq[182] := 0;
         instr[183]:='dupr      '; insp[183] := false; insq[183] := 0;
         instr[184]:='dups      '; insp[184] := false; insq[184] := 0;
         instr[185]:='dupb      '; insp[185] := false; insq[185] := 0;
         instr[186]:='dupc      '; insp[186] := false; insq[186] := 0;
         instr[187]:='cks       '; insp[187] := false; insq[187] := 0;
         instr[188]:='cke       '; insp[188] := false; insq[188] := 0;
         instr[189]:='inv       '; insp[189] := false; insq[189] := 0;
         instr[190]:='ckla      '; insp[190] := false; insq[190] := intsize;
         instr[191]:='cta       '; insp[191] := false; insq[191] := intsize*2;
         instr[192]:='ivt       '; insp[192] := false; insq[192] := intsize*2;

         { sav (mark) and rst (release) were removed }
         sptable[ 0]:='get       ';     sptable[ 1]:='put       ';
         sptable[ 2]:='---       ';     sptable[ 3]:='rln       ';
         sptable[ 4]:='new       ';     sptable[ 5]:='wln       ';
         sptable[ 6]:='wrs       ';     sptable[ 7]:='eln       ';
         sptable[ 8]:='wri       ';     sptable[ 9]:='wrr       ';
         sptable[10]:='wrc       ';     sptable[11]:='rdi       ';
         sptable[12]:='rdr       ';     sptable[13]:='rdc       ';
         sptable[14]:='sin       ';     sptable[15]:='cos       ';
         sptable[16]:='exp       ';     sptable[17]:='log       ';
         sptable[18]:='sqt       ';     sptable[19]:='atn       ';
         sptable[20]:='---       ';     sptable[21]:='pag       ';
         sptable[22]:='rsf       ';     sptable[23]:='rwf       ';
         sptable[24]:='wrb       ';     sptable[25]:='wrf       ';
         sptable[26]:='dsp       ';     sptable[27]:='wbf       ';
         sptable[28]:='wbi       ';     sptable[29]:='wbr       ';
         sptable[30]:='wbc       ';     sptable[31]:='wbb       ';
         sptable[32]:='rbf       ';     sptable[33]:='rsb       ';
         sptable[34]:='rwb       ';     sptable[35]:='gbf       ';
         sptable[36]:='pbf       ';     sptable[37]:='rib       ';
         sptable[38]:='rcb       ';     sptable[39]:='nwl       ';
         sptable[40]:='dsl       ';     sptable[41]:='eof       ';
         sptable[42]:='efb       ';     sptable[43]:='fbv       ';
         sptable[44]:='fvb       ';

         pc := begincode;
         cp := maxstr; { set constants pointer to top of storage }
         for i:= 1 to 10 do word[i]:= ' ';
         for i:= 0 to maxlabel do
             with labeltab[i] do begin val:=-1; st:= entered end;
         { initalize file state }
         for i := 1 to maxfil do filstate[i] := fclosed;

         { !!! remove this next statement for self compile }
         {elide}reset(prd);{noelide}

         iline := 1 { set 1st line of intermediate }
   end;(*init*)

   procedure errorl(string: beta); (*error in loading*)
   begin writeln;
      writeln('*** Program load error: [', iline:1, '] ', string);
      goto 1
   end; (*errorl*)

   procedure dmplabs; { dump label table }

   var i: labelrg;

   begin

      writeln;
      writeln('Label table');
      writeln;
      for i := 1 to maxlabel do if labeltab[i].val <> -1 then begin

         write('Label: ', i:5, ' value: ', labeltab[i].val, ' ');
         if labeltab[i].st = entered then writeln('Entered')
         else writeln('Defined')

      end;
      writeln

   end;

   procedure update(x: labelrg); (*when a label definition lx is found*)
      var curr,succ,ad: address; (*resp. current element and successor element
                               of a list of future references*)
          endlist: boolean;
          op: instyp; q : address;  (*instruction register*)
   begin
      if labeltab[x].st=defined then errorl('duplicated label         ')
      else begin
             if labeltab[x].val<>-1 then (*forward reference(s)*)
             begin curr:= labeltab[x].val; endlist:= false;
                while not endlist do begin
                      ad := curr;
                      op := store[ad]; { get instruction }
                      q := getadr(ad+1+ord(insp[op]));
                      succ:= q; { get target address from that }
                      q:= labelvalue; { place new target address }
                      ad := curr;
                      putadr(ad+1+ord(insp[op]), q);
                      if succ=-1 then endlist:= true
                                 else curr:= succ
                 end
             end;
             labeltab[x].st := defined;
             labeltab[x].val:= labelvalue;
      end
   end;(*update*)

   procedure getnxt; { get next character }
   begin
      ch := ' ';
      if not eoln(prd) then read(prd,ch)
   end;

   procedure skpspc; { skip spaces }
   begin
     while (ch = ' ') and not eoln(prd) do getnxt
   end;

   procedure getlin; { get next line }
   begin
     readln(prd);
     iline := iline+1 { next intermediate line }
   end;

   procedure assemble; forward;

   procedure generate;(*generate segment of code*)
      var x: integer; (* label number *)
          again: boolean;
   begin
      again := true;
      while again do
            begin if eof(prd) then errorl('unexpected eof on input  ');
                  getnxt;(* first character of line*)
                  if not (ch in ['i', 'l', 'q', ' ', '!', ':']) then
                    errorl('unexpected line start    ');
                  case ch of
                       'i': getlin;
                       'l': begin read(prd,x);
                                  getnxt;
                                  if ch='=' then read(prd,labelvalue)
                                            else labelvalue:= pc;
                                  update(x); getlin
                            end;
                       'q': begin again := false; getlin end;
                       ' ': begin getnxt; assemble end;
                       ':': begin { source line }

                               read(prd,x); { get source line number }
                               if dosrclin then begin

                                  { pass source line register instruction }
                                  store[pc] := 174; pc := pc+1;
                                  putint(pc, x); pc := pc+intsize

                               end;
                               { skip the rest of the line, which would be the
                                 contents of the source line if included }
                               while not eoln(prd) do
                                  read(prd, c); { get next character }
                               getlin { source line }

                            end
                  end;
            end
   end; (*generate*)

   procedure assemble;
      var name :alfa; r :real; s :settype;
          i,x,s1,lb,ub,l:integer; c: char;
          str: packed array [1..stringlgth] of char; { buffer for string constants }
          t: integer; { [sam] temp for compiler bug }
          r: register;

      procedure lookup(x: labelrg); (* search in label table*)
      begin case labeltab[x].st of
                entered: begin q := labeltab[x].val;
                           labeltab[x].val := pc
                         end;
                defined: q:= labeltab[x].val
            end(*case label..*)
      end;(*lookup*)

      procedure labelsearch;
         var x: labelrg;
      begin while (ch<>'l') and not eoln(prd) do read(prd,ch);
            read(prd,x); lookup(x)
      end;(*labelsearch*)

      procedure getname;
      var i: alfainx;
      begin
        if eof(prd) then errorl('unexpected eof on input  ');
        for i := 1 to maxalfa do word[i] := ' ';
        i := 1; { set 1st character of word }
        while ch in ['a'..'z'] do begin
          if i = maxalfa then errorl('Opcode label is too long ');
          word[i] := ch;
          i := i+1; ch := ' ';
          if not eoln(prd) then read(prd,ch); { next character }
        end;
        pack(word,1,name)
      end; (*getname*)
      
      procedure prtreg(r: register);
      begin
        case r of { register }
          rgnone: write(prr, '*');
          rgstack: write(prr, 'S');
          rgeax:   write(prr, '%eax');
          rgebx:   write(prr, '%ebx');
          rgecx:   write(prr, '%ecx');
          rgedx:   write(prr, '%edx');
          rgesi:   write(prr, '%esi');
          rgedi:   write(prr, '%edi')
        end
      end;
      
      procedure getreg(var r: register);
      var sr: register; si: 1..
      begin
        r := rgnone;
        for sr := rgeax to rgedi if regfre[sr] then r := sr;
        if r = rgnone then begin
          si := 1;
          while (r = rgnone) and (si < stktop) do 
            if datstk[si].r > rgstack then begin
              write(prr, ' pushl %'); prtreg(datstk[si].r); writeln(prr);
              r := datstk[si].r; datstk[si].r := rgstack
            end else si := si+1
          end;
          if r = rgnone then errorl('Compiler error           ')
          regfre[r] := false
      end;
      
      procedure putreg(var r: register);
      begin
        regfre[r] := true
      end;
      
      procedure loaddsp(p: lvltyp; r: register);
      begin
        write(prr, p*ptrsize:1, 'movl (%ebp),');
        prtreg(r); writeln(prr)
      end

   begin { assemble }
      for r := rgnone to rgedi do regfre[r] := true; { set all registers free } 
      getname;
      { note this search removes the top instruction from use }
      while (instr[op]<>name) and (op < maxins) do op := op+1;
      if op = maxins then errorl('illegal instruction      ');

      case op of  (* get parameters p,q *)

        0   { lodi }
        105 { loda }
        193 { lodx },
        108 { lodb },
        109 { lodc }: begin read(prd,p,q); 
                          with datstk[stktop] do begin
                            if dsi >= stkmax then errorl('Program code overflow    ');
                            getreg(r); stktop := stktop+1;
                            if p = 1 then begin 
                              if (op = 0) or (op = 105) then 
                                write(prr, q:1, 'movl (%ebp),')
                              else write(prr, q:1, 'movzxb (%ebp),');
                              prtreg(r); writeln(prr)
                            end else begin
                              loaddsp(r);
                              if (op = 0) or (op = 105) then 
                                write(prr, 'movl ', q:1, '(')
                              else write(prr, 'movzxb ', q:1, '('); 
                              prtreg(r);
                              writeln(prr, '),'); prtreg(r)
                            end
                          end
                    end; 

*********************************************************** 
          (*lod,str,lda,lip*)
          0, 105, 106, 107, 108, 109,
          2, 70, 71, 72, 73, 74,4,120: begin read(prd,p,q); storeop; storep;
                                             storeq
                                       end;

          { [sam] There is a compiler bug with reads to restricted range
            variables in IP Pascal here. }
          12(*cup*): begin read(prd,t{p}); p := t; labelsearch; storeop;
                           storep; storeq
                     end;

          11,113(*mst,cip*): begin read(prd,p); storeop; storep end;

          { equm,neqm,geqm,grtm,leqm,lesm take a parameter }
          142, 148, 154, 160, 166, 172,

          (*lao,ixa,mov,dmp,swp*)
          5,16,55,117,118,

          (*ldo,sro,ind,inc,dec*)
          1, 65, 66, 67, 68, 69,
          3, 75, 76, 77, 78, 79,
          9, 85, 86, 87, 88, 89,
          10, 90, 91, 92, 93, 94,
          57, 100, 101, 102, 103, 104,
          175, 176, 177, 178, 179, 180: begin read(prd,q); storeop; storeq end;

          (*pck,upk,cta,ivt*)
          63, 64, 191, 192: begin read(prd,q); read(prd,q1); storeop; storeq;
                                  storeq1 end;

          (*ujp,fjp,xjp,tjp*)
          23,24,25,119,

          (*ents,ente*)
          13, 173: begin labelsearch; storeop; storeq end;

          (*ipj,lpa*)
          112,114: begin read(prd,p); labelsearch; storeop; storep; storeq end;

          15 (*csp*): begin skpspc; getname;
                           while name<>sptable[q] do
                           begin q := q+1; if q > maxsp then
                                 errorl('std proc/func not found  ')
                           end; storeop;
                           if pc+1 > cp then
                             errorl('Program code overflow    ');
                           store[pc] := q; pc := pc+1
                      end;

          7, 123, 124, 125, 126, 127 (*ldc*): begin case op of  (*get q*)
                           123: begin read(prd,i); storeop;
                                      if pc+intsize > cp then
                                         errorl('Program code overflow    ');
                                      putint(pc, i); pc := pc+intsize
                                end;

                           124: begin read(prd,r);
                                      cp := cp-realsize;
                                      alignd(realal, cp);
                                      if cp <= 0 then
                                         errorl('constant table overflow  ');
                                      putrel(cp, r); q := cp;
                                      storeop; storeq
                                end;

                           125: storeop; (*p,q = 0*)

                           126: begin read(prd,q); storeop;
                                      if pc+1 > cp then
                                        errorl('Program code overflow    ');
                                      putbol(pc, q <> 0); pc := pc+1 end;

                           127: begin
                                  skpspc;
                                  if ch <> '''' then
                                    errorl('illegal character        ');
                                  getnxt;  c := ch;
                                  getnxt;
                                  if ch <> '''' then
                                    errorl('illegal character        ');
                                  storeop;
                                  if pc+1 > cp then
                                    errorl('Program code overflow    ');
                                  putchr(pc, c); pc := pc+1
                                end;
                           7: begin skpspc;
                                   if ch <> '(' then
                                     errorl('ldcs() expected          ');
                                   s := [ ];  getnxt;
                                   while ch<>')' do
                                   begin read(prd,s1); getnxt; s := s + [s1]
                                   end;
                                   cp := cp-setsize;
                                   alignd(setal, cp);
                                   if cp <= 0 then
                                      errorl('constant table overflow  ');
                                   putset(cp, s);
                                   q := cp;
                                   storeop; storeq
                                end
                           end (*case*)
                     end;

           26, 95, 96, 97, 98, 99, 190 (*chk*): begin
                         read(prd,lb,ub);
                         if (op = 95) or (op = 190) then q := lb
                         else
                         begin
                           cp := cp-intsize;
                           alignd(intal, cp);
                           if cp <= 0 then errorl('constant table overflow  ');
                           putint(cp, ub);
                           cp := cp-intsize;
                           alignd(intal, cp);
                           if cp <= 0 then errorl('constant table overflow  ');
                           putint(cp, lb); q := cp
                         end;
                         storeop; storeq
                       end;

           56 (*lca*): begin read(prd,l); skpspc;
                         for i := 1 to stringlgth do str[i] := ' ';
                         if ch <> '''' then errorl('bad string format        ');
                         i := 0;
                         repeat
                           if eoln(prd) then errorl('unterminated string      ');
                           getnxt;
                           c := ch; if (ch = '''') and (prd^ = '''') then begin
                             getnxt; c := ' '
                           end;
                           if c <> '''' then begin
                             if i >= stringlgth then errorl('string overflow          ');
                             str[i+1] := ch; { accumulate string }
                             i := i+1
                           end
                         until c = '''';
                         { place in storage }
                         cp := cp-l;
                         if cp <= 0 then errorl('constant table overflow  ');
                         q := cp;
                         for x := 1 to l do putchr(q+x-1, str[x]);
                         { this should have worked, the for loop is faulty
                           because the calculation for end is done after the i
                           set
                         for i := 0 to i-1 do putchr(q+i, str[i+1]);
                         }
                         storeop; storeq
                       end;

          14, 128, 129, 130, 131, 132, (*ret*)

          { equ,neq,geq,grt,leq,les with no parameter }
          17, 137, 138, 139, 140, 141,
          18, 143, 144, 145, 146, 147,
          19, 149, 150, 151, 152, 153,
          20, 155, 156, 157, 158, 159,
          21, 161, 162, 163, 164, 165,
          22, 167, 168, 169, 170, 171,

          59, 133, 134, 135, 136, (*ord*)

          6, 80, 81, 82, 83, 84, (*sto*)

          { eof,adi,adr,sbi,sbr,sgs,flt,flo,trc,ngi,ngr,sqi,sqr,abi,abr,not,and,
            ior,dif,int,uni,inn,mod,odd,mpi,mpr,dvi,dvr,stp,chr,rnd,rgs,fbv,
            fvb }
          27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,
          48,49,50,51,52,53,54,58,60,62,110,111,
          115, 116,

          { dupi, dupa, dupr, dups, dupb, dupc, cks, cke, inv }
          181, 182, 183, 184, 185, 186,187,188,189: storeop;

                      (*ujc must have same length as ujp, so we output a dummy
                        q argument*)
          61 (*ujc*): begin storeop; q := 0; storeq end

      end; (*case*)

      getlin { next intermediate line }

   end; (*assemble*)

begin (*load*)

   init;
   generate;
   pctop := pc; { save top of code store }
   lsttop := pctop; { save as top of listing }
   pc := 0;
   generate;
   alignu(stackal, pctop); { align the end of code for stack bottom }
   alignd(heapal, cp); { align the start of cp for heap top }

   if dodmpsto then begin { dump storage overview }

      writeln;
      writeln('Storage areas occupied');
      writeln;
      write('Program     '); wrthex(0, maxdigh); write('-'); wrthex(pctop-1, maxdigh);
      writeln(' (',pctop:maxdigd,')');
      write('Stack/Heap  '); wrthex(pctop, maxdigh); write('-'); wrthex(cp-1, maxdigh);
      writeln(' (',cp-pctop+1:maxdigd,')');
      write('Constants   '); wrthex(cp, maxdigh); write('-'); wrthex(maxstr, maxdigh);
      writeln(' (',maxstr-(cp):maxdigd,')');
      writeln

   end;
   if dodmpins then dmpins; { Debug: dump instructions from store }
   if dodmplab then dmplabs { Debug: dump label definitions }

end; (*load*)

(*------------------------------------------------------------------------*)

{ runtime handlers }

function base(ld :integer):address;
   var ad :address;
begin ad := mp;
   while ld>0 do begin ad := getadr(ad+marksl); ld := ld-1 end;
   base := ad
end; (*base*)

procedure compare;
(*comparing is only correct if result by comparing integers will be*)
begin
  popadr(a2);
  popadr(a1);
  i := 0; b := true;
  while b and (i<q) do begin
    chkdef(a1+i); chkdef(a2+i);
    if store[a1+i] = store[a2+i] then i := i+1
    else b := false
  end;
  if i = q then i := i-1 { point at last location }
end; (*compare*)

procedure valfil(fa: address); { attach file to file entry }
var i,ff: integer;
begin
   if store[fa] = 0 then begin { no file }
     if fa = pctop+marksize+inputoff then ff := inputfn
     else if fa = pctop+marksize+outputoff then ff := outputfn
     else if fa = pctop+marksize+prdoff then ff := prdfn
     else if fa = pctop+marksize+prroff then ff := prrfn
     else begin
       i := 5; { start search after the header files }
       ff := 0;
       while i <= maxfil do begin
         if filstate[i] = fclosed then begin ff := i; i := maxfil end;
         i := i+1
       end;
       if ff = 0 then errori('To many files            ');
     end;
     store[fa] := ff
   end
end;

procedure valfilwm(fa: address); { validate file write mode }
begin
   valfil(fa); { validate file address }
   if filstate[store[fa]] <> fwrite then errori('File not in write mode   ')
end;

procedure valfilrm(fa: address); { validate file read mode }
begin
   valfil(fa); { validate file address }
   if filstate[store[fa]] <> fread then errori('File not in read mode    ')
end;

procedure getop; { get opcode }

begin

   op := store[pc]; pc := pc+1

end;

procedure getp; { get p parameter }

begin

   p := store[pc]; pc := pc+1

end;

procedure getq; { get q parameter }

begin

   q := getadr(pc); pc := pc+adrsize

end;

procedure getq1; { get q1 parameter }

begin

   q1 := getadr(pc); pc := pc+adrsize

end;

{

   Blocks in the heap are dead simple. The block begins with a length, including
   the length itself. If the length is positive, the block is free. If negative,
   the block is allocated. This means that AddressOfBLock+abs(lengthOfBlock) is
   address of the next block, and RequestedSize <= LengthOfBLock+adrsize is a
   reasonable test for if a free block fits the requested size, since it will
   never be true of occupied blocks.

}

{ report all space in heap }

procedure repspc;
var l, ad: address;
begin
   writeln;
   writeln('Heap space breakdown');
   writeln;
   ad := np; { index the bottom of heap }
   while ad < cp do begin
      l := getadr(ad); { get next block length }
      write('addr: '); wrthex(ad, maxdigh); write(': ', abs(l):6, ': ');
      if l >= 0 then writeln('free') else writeln('alloc');
      ad := ad+abs(l)
   end
end;

{ find free block using length }

procedure fndfre(len: address; var blk: address);
var l, b: address;
begin
  b := 0; { set no block found }
  blk := np; { set to bottom of heap active }
  while blk < cp do begin { search blocks in heap }
     l := getadr(blk); { get length }
     if l >= len+adrsize then begin b := blk; blk := cp end { found }
     else blk := blk+abs(l) { go next block }
  end;
  if b > 0 then begin { block was found }
     putadr(b, -(len+adrsize)); { allocate block }
     blk := b+adrsize; { set base address }
     if l > len+adrsize+adrsize+resspc then begin
        { If there is enough room for the block, header, and another header,
          then a reserve factor if desired. }
        b := b+len+adrsize; { go to top of allocated block }
        putadr(b, l-(len+adrsize)) { set length of stub space }
     end
  end else blk := 0 { set no block found }
end;

{ coalesce space in heap }

procedure cscspc;
var done: boolean;
    ad, ad1, l, l1: address;
begin
   { first, colapse all free blocks at the heap bottom }
   done := false;
   while not done and (np < cp) do begin
      l := getadr(np); { get header length }
      if l >= 0 then np := np+getadr(np) { free, skip block }
      else done := true { end }
   end;
   { now, walk up and collapse adjacent free blocks }
   ad := np; { index bottom }
   while ad < cp do begin
      l := getadr(ad); { get header length }
      if l >= 0 then begin { free }
         ad1 := ad+l; { index next block }
         if ad1 < cp then begin { not against end }
            l1 := getadr(ad1); { get length next }
            if l1 >=0 then
               putadr(ad, l+l1) { both blocks are free, combine the blocks }
            else ad := ad+l+abs(l1) { skip both blocks }
         end else ad := ad+l+abs(l1) { skip both blocks }
      end else ad := ad+abs(l) { skip this block }
   end
end;

{ allocate space in heap }

procedure newspc(len: address; var blk: address);
var ad,ad1: address;
begin
  alignu(adrsize, len); { align to units of address }
  fndfre(len, blk); { try finding an existing free block }
  if blk = 0 then begin { allocate from heap bottom }
     ad := np-(len+adrsize); { find new heap bottom }
     ad1 := ad; { save address }
     alignd(heapal, ad); { align to arena }
     len := len+(ad1-ad); { adjust length upwards for alignment }
     if ad <= ep then errori('Store overflow: dynamic  ');
     np:= ad;
     putadr(ad, -(len+adrsize)); { allocate block }
     blk := ad+adrsize { index start of block }
  end;
  { clear block and set undefined }
  for ad := blk to blk+len-1 do begin store[ad] := 0; putdef(ad, false) end
end;

{ dispose of space in heap }

procedure dspspc(len, blk: address);
var ad: address;
begin
   len := len; { shut up compiler check }
   if blk = 0 then errori('Dispose uninit pointer   ')
   else if blk = nilval then errori('Dispose nil pointer      ')
   else if (blk < np) or (blk >= cp) then errori('Bad pointer value        ');
   ad := blk-adrsize; { index header }
   if getadr(ad) >= 0 then errori('Block already freed      ');
   if dorecycl and not dochkrpt then begin { obey recycling requests }
      putadr(ad, abs(getadr(ad))); { set block free }
      cscspc { coalesce free space }
   end else if dochkrpt then begin { perform special recycle }
      { check can break off top block }
      len := abs(getadr(ad)); { get length }
      if len >= adrsize*2 then putadr(ad+adrsize, abs(getadr(ad))-adrsize);
      { the "marker" is a block with a single address. Since it can't
        hold more than that, it will never be reused }
      putadr(ad, adrsize) { indicate freed but fixed block }
   end
end;

{ check pointer indexes free entry }

function isfree(blk: address): boolean;
begin
   isfree := getadr(blk-adrsize) = adrsize
end;

{ system routine call}

procedure callsp;
   var line: boolean;
       i, j, w, l, f: integer;
       c: char;
       b: boolean;
       ad,ad1: address;
       r: real;
       fn: fileno;
       mn,mx: integer;

   procedure readi(var f: text; var i: integer);

   var s: integer;
       d: integer;

   begin

      s := +1; { set sign }
      { skip leading spaces }
      while (f^ = ' ') and not eoln(f) do get(f);
      if not (f^ in ['+', '-', '0'..'9']) then
        errori('Invalid integer format   ');
      if f^ = '+' then get(f)
      else if f^ = '-' then begin get(f); s := -1 end;
      if not (f^ in ['0'..'9']) then errori('Invalid integer format   ');
      i := 0; { clear initial value }
      while (f^ in ['0'..'9']) do begin { parse digit }

         d := ord(f^)-ord('0');
         if (i+d) > maxint div 10 then errori('Input value overflows    ');
         i := i*10+d; { add in new digit }
         get(f)

      end;
      i := i*s { place sign }

   end;

   procedure readr(var f: text; var r: real);

   var i: integer; { integer holding }
       e: integer; { exponent }
       d: integer; { digit }
       s: boolean; { sign }

   { find power of ten }

   function pwrten(e: integer): real;

   var t: real; { accumulator }
       p: real; { current power }

   begin

      p := 1.0e+1; { set 1st power }
      t := 1.0; { initalize result }
      repeat

         if odd(e) then t := t*p; { if bit set, add this power }
         e := e div 2; { index next bit }
         p := sqr(p) { find next power }

      until e = 0;
      pwrten := t

   end;

   begin

      e := 0; { clear exponent }
      s := false; { set sign }
      r := 0.0; { clear result }
      { skip leading spaces }
      while (f^ = ' ') and not eoln(f) do get(f);
      { get any sign from number }
      if f^ = '-' then begin get(f); s := true end;
      if not (f^ in ['0'..'9']) then errori('Invalid real format      ');
      while (f^ in ['0'..'9']) do begin { parse digit }

         d := ord(f^)-ord('0');
         r := r*10+d; { add in new digit }
         get(f)

      end;
      if f^ in ['.', 'e', 'E'] then begin { it's a real }

         if f^ = '.' then begin { decimal point }

            get(f); { skip '.' }
            if not (f^ in ['0'..'9']) then errori('Invalid real format      ');
            while (f^ in ['0'..'9']) do begin { parse digit }

               d := ord(f^)-ord('0');
               r := r*10+d; { add in new digit }
               get(f);
               e := e-1 { count off right of decimal }

            end;

         end;
         if f^ in ['e', 'E'] then begin { exponent }

            get(f); { skip 'e' }
            if not (f^ in ['0'..'9', '+', '-']) then
               errori('Invalid real format      ');
            readi(f, i); { get exponent }
            { find with exponent }
            e := e+i

         end;
         if e < 0 then r := r/pwrten(e) else r := r*pwrten(e)

      end;
      if s then r := -r

   end;

   procedure readc(var f: text; var c: char);
   begin if eof(f) then errori('End of file              ');
         read(f,c);
   end;(*readc*)

   procedure writestr(var f: text; ad: address; w: integer; l: integer);
      var i: integer;
   begin (* l and w are numbers of characters *)
         if w>l then for i:=1 to w-l do write(f,' ')
                else l := w;
         for i := 0 to l-1 do write(f, getchr(ad+i))
   end;(*writestr*)

   procedure getfile(var f: text);
   begin if eof(f) then errori('End of file              ');
         get(f);
   end;(*getfile*)

   procedure putfile(var f: text; var ad: address; fn: fileno);
   begin if not filbuff[fn] then errori('File buffer undefined    ');
         f^:= getchr(ad+fileidsize); put(f);
         filbuff[fn] := false
   end;(*putfile*)

begin (*callsp*)
      if q > maxsp then errori('Invalid std proc/func    ');

      { trace routine executions }
      if dotrcrot then writeln(pc:6, '/', sp:6, '-> ', q:2);

      case q of
           0 (*get*): begin popadr(ad); valfil(ad); fn := store[ad];
                           if fn <= prrfn then case fn of
                              inputfn: getfile(input);
                              outputfn: errori('Get on output file       ');
                              prdfn: getfile(prd);
                              prrfn: errori('Get on prr file          ')
                           end else begin
                                if filstate[fn] <> fread then
                                   errori('File not in read mode    ');
                                getfile(filtable[fn])
                           end
                      end;
           1 (*put*): begin popadr(ad); valfil(ad); fn := store[ad];
                           if fn <= prrfn then case fn of
                              inputfn: errori('Put on read file         ');
                              outputfn: putfile(output, ad, fn);
                              prdfn: errori('Put on prd file          ');
                              prrfn: putfile(prr, ad, fn)
                           end else begin
                                if filstate[fn] <> fwrite then
                                   errori('File not in write mode   ');
                                putfile(filtable[fn], ad, fn)
                           end
                      end;
           { unused placeholder for "release" }
           2 (*rst*): errori('Invalid std proc/func    ');
           3 (*rln*): begin popadr(ad); pshadr(ad); valfil(ad); fn := store[ad];
                           if fn <= prrfn then case fn of
                              inputfn: begin
                                 if eof(input) then errori('End of file              ');
                                 readln(input)
                              end;
                              outputfn: errori('Readln on output file    ');
                              prdfn: begin
                                 if eof(prd) then errori('End of file              ');
                                 readln(prd)
                              end;
                              prrfn: errori('Readln on prr file       ')
                           end else begin
                                if filstate[fn] <> fread then
                                   errori('File not in read mode    ');
                                if eof(filtable[fn]) then errori('End of file              ');
                                readln(filtable[fn])
                           end
                      end;
           4 (*new*): begin popadr(ad1); newspc(ad1, ad);
                      (*top of stack gives the length in units of storage *)
                            popadr(ad1); putadr(ad1, ad)
                      end;
           39 (*nwl*): begin popadr(ad1); popint(i);
                            newspc(ad1+(i+1)*intsize, ad);
                            ad1 := ad+i*intsize; putint(ad1, i+adrsize+1);
                            k := i;
                            while k > 0 do
                              begin ad1 := ad1-intsize; popint(j);
                                    putint(ad1, j); k := k-1
                              end;
                            popadr(ad1); putadr(ad1, ad+(i+1)*intsize)
                      end;
           5 (*wln*): begin popadr(ad); pshadr(ad); valfil(ad); fn := store[ad];
                           if fn <= prrfn then case fn of
                              inputfn: errori('Writeln on input file    ');
                              outputfn: writeln(output);
                              prdfn: errori('Writeln on prd file      ');
                              prrfn: writeln(prr)
                           end else begin
                                if filstate[fn] <> fwrite then
                                   errori('File not in write mode   ');
                                writeln(filtable[fn])
                           end
                      end;
           6 (*wrs*): begin popint(l); popint(w); popadr(ad1);
                           popadr(ad); pshadr(ad); valfil(ad); fn := store[ad];
                           if w < 1 then errori('Width cannot be < 1      ');
                           if fn <= prrfn then case fn of
                              inputfn: errori('Write on input file      ');
                              outputfn: writestr(output, ad1, w, l);
                              prdfn: errori('Write on prd file        ');
                              prrfn: writestr(prr, ad1, w, l)
                           end else begin
                                if filstate[fn] <> fwrite then
                                   errori('File not in write mode   ');
                                writestr(filtable[fn], ad1, w, l)
                           end;
                      end;
          41 (*eof*): begin popadr(ad); valfil(ad); fn := store[ad];
                        if fn <= prrfn then case fn of
                          inputfn: pshint(ord(eof(input)));
                          prdfn: pshint(ord(eof(prd)));
                          outputfn,
                          prrfn: errori('Eof test on output file  ')
                        end else begin
                          if filstate[fn] = fwrite then pshint(ord(true))
                          else if filstate[fn] = fread then
                            pshint(ord(eof(filtable[fn]) and not filbuff[fn]))
                          else errori('File is not open         ')
                        end
                      end;
          42 (*efb*): begin
                        popadr(ad); valfilrm(ad); fn := store[ad];
                        { eof is file eof, and buffer not full }
                        pshint(ord(eof(bfiltable[fn]) and not filbuff[fn]))
                      end;
           7 (*eln*): begin popadr(ad); valfil(ad); fn := store[ad];
                           if fn <= prrfn then case fn of
                                 inputfn: line:= eoln(input);
                                 outputfn: errori('Eoln output file         ');
                                 prdfn: line:=eoln(prd);
                                 prrfn: errori('Eoln on prr file         ')
                              end
                           else begin
                                if filstate[fn] <> fread then
                                   errori('File not in read mode    ');
                                line:=eoln(filtable[fn])
                           end;
                           pshint(ord(line))
                      end;
           8 (*wri*): begin popint(w); popint(i); popadr(ad); pshadr(ad);
                            valfil(ad); fn := store[ad];
                            if w < 1 then errori('Width cannot be < 1      ');
                            if fn <= prrfn then case fn of
                                 inputfn: errori('Write on input file      ');
                                 outputfn: write(output, i:w);
                                 prdfn: errori('Write on prd file        ');
                                 prrfn: write(prr, i:w)
                              end
                            else begin
                                if filstate[fn] <> fwrite then
                                   errori('File not in write mode   ');
                                write(filtable[fn], i:w)
                            end
                      end;
           9 (*wrr*): begin popint(w); poprel(r); popadr(ad); pshadr(ad);
                            valfil(ad); fn := store[ad];
                            if w < 1 then errori('Width cannot be < 1      ');
                            if fn <= prrfn then case fn of
                                 inputfn: errori('Write on input file      ');
                                 outputfn: write(output, r: w);
                                 prdfn: errori('Write on prd file        ');
                                 prrfn: write(prr, r:w)
                              end
                            else begin
                                if filstate[fn] <> fwrite then
                                   errori('File not in write mode   ');
                                write(filtable[fn], r:w)
                            end;
                      end;
           10(*wrc*): begin popint(w); popint(i); c := chr(i); popadr(ad);
                            pshadr(ad); valfil(ad); fn := store[ad];
                            if w < 1 then errori('Width cannot be < 1      ');
                            if fn <= prrfn then case fn of
                                 inputfn: errori('Write on input file      ');
                                 outputfn: write(output, c:w);
                                 prdfn: errori('Write on prd file        ');
                                 prrfn: write(prr, c:w)
                              end
                            else begin
                                if filstate[fn] <> fwrite then
                                   errori('File not in write mode   ');
                                write(filtable[fn], c:w)
                            end
                      end;
           11(*rdi*): begin popadr(ad1); popadr(ad); pshadr(ad); valfil(ad);
                            fn := store[ad];
                           if fn <= prrfn then case fn of
                                 inputfn: begin readi(input, i); putint(ad1, i);
                                          end;
                                 outputfn: errori('Read on output file      ');
                                 prdfn: begin readi(prd, i); putint(ad1, i) end;
                                 prrfn: errori('Read on prr file         ')
                              end
                           else begin
                                if filstate[fn] <> fread then
                                   errori('File not in read mode    ');
                                readi(filtable[fn], i);
                                putint(ad1, i)
                           end
                      end;
           37(*rib*): begin popint(mx); popint(mn); popadr(ad1); popadr(ad);
                            pshadr(ad); valfil(ad); fn := store[ad];
                           if fn <= prrfn then case fn of
                                 inputfn: begin readi(input, i);
                                   if (i < mn) or (i > mx) then
                                     errori('Value read out of range  ');
                                   putint(ad1, i);
                                 end;
                                 outputfn: errori('Read on output file      ');
                                 prdfn: begin readi(prd, i);
                                   if (i < mn) or (i > mx) then
                                     errori('Value read out of range  ');
                                   putint(ad1, i)
                                 end;
                                 prrfn: errori('Read on prr file         ')
                              end
                           else begin
                                if filstate[fn] <> fread then
                                  errori('File not in read mode    ');
                                readi(filtable[fn], i);
                                if (i < mn) or (i > mx) then
                                  errori('Value read out of range  ');
                                putint(ad1, i)
                           end
                      end;
           12(*rdr*): begin popadr(ad1); popadr(ad); pshadr(ad); valfil(ad);
                            fn := store[ad];
                           if fn <= prrfn then case fn of
                                 inputfn: begin readr(input, r); putrel(ad1, r);
                                          end;
                                 outputfn: errori('Read on output file      ');
                                 prdfn: begin readr(prd, r); putrel(ad1, r) end;
                                 prrfn: errori('Read on prr file         ')
                              end
                           else begin
                                if filstate[fn] <> fread then
                                   errori('File not in read mode    ');
                                readr(filtable[fn], r);
                                putrel(ad1, r)
                           end
                      end;
           13(*rdc*): begin popadr(ad1); popadr(ad); pshadr(ad); valfil(ad);
                            fn := store[ad];
                           if fn <= prrfn then case fn of
                                 inputfn: begin readc(input, c); putchr(ad1, c);
                                          end;
                                 outputfn: errori('Read on output file      ');
                                 prdfn: begin readc(prd, c); putchr(ad1, c);
                                        end;
                                 prrfn: errori('Read on prr file         ')
                              end
                           else begin
                                if filstate[fn] <> fread then
                                   errori('File not in read mode    ');
                                readc(filtable[fn], c);
                                putchr(ad1, c)
                           end
                      end;
           38(*rcb*): begin popint(mx); popint(mn); popadr(ad1); popadr(ad);
                            pshadr(ad); valfil(ad);
                            fn := store[ad];
                           if fn <= prrfn then case fn of
                                 inputfn: begin readc(input, c);
                                   if (ord(c) < mn) or (ord(c) > mx) then
                                     errori('Value read out of range  ');
                                   putchr(ad1, c)
                                 end;
                                 outputfn: errori('Read on output file      ');
                                 prdfn: begin readc(prd, c);
                                   if (ord(c) < mn) or (ord(c) > mx) then
                                     errori('Value read out of range  ');
                                   putchr(ad1, c)
                                 end;
                                 prrfn: errori('Read on prr file         ')
                              end
                           else begin
                                if filstate[fn] <> fread then
                                   errori('File not in read mode    ');
                                readc(filtable[fn], c);
                                if (ord(c) < mn) or (ord(c) > mx) then
                                  errori('Value read out of range  ');
                                putchr(ad1, c)
                           end
                      end;
           14(*sin*): begin poprel(r1); pshrel(sin(r1)) end;
           15(*cos*): begin poprel(r1); pshrel(cos(r1)) end;
           16(*exp*): begin poprel(r1); pshrel(exp(r1)) end;
           17(*log*): begin poprel(r1);
                            if r1 <= 0 then errori('Cannot find ln <= 0      ');
                            pshrel(ln(r1)) end;
           18(*sqt*): begin poprel(r1);
                            if r1 <= 0 then errori('Cannot find sqrt < 0     ');
                            pshrel(sqrt(r1)) end;
           19(*atn*): begin poprel(r1); pshrel(arctan(r1)) end;
           { placeholder for "mark" }
           20(*sav*): errori('Invalid std proc/func    ');
           21(*pag*): begin popadr(ad); valfil(ad); fn := store[ad];
                           if fn <= prrfn then case fn of
                                inputfn: errori('Page on read file        ');
                                outputfn: page(output);
                                prdfn: errori('Page on prd file         ');
                                prrfn: page(prr)
                              end
                           else begin
                                if filstate[fn] <> fwrite then
                                   errori('File not in write mode   ');
                                page(filtable[fn])
                           end
                      end;
           22(*rsf*): begin popadr(ad); valfil(ad); fn := store[ad];
                           if fn <= prrfn then case fn of
                                inputfn: errori('Reset on input file      ');
                                outputfn: errori('Reset on output file     ');
                                prdfn: reset(prd);
                                prrfn: errori('Reset on prr file        ')
                              end
                           else begin
                                filstate[fn] := fread;
                                reset(filtable[fn]);
                           end
                      end;
           23(*rwf*): begin popadr(ad); valfil(ad); fn := store[ad];
                           if fn <= prrfn then case fn of
                                inputfn: errori('Rewrite on input file    ');
                                outputfn: errori('Rewrite on output file   ');
                                prdfn: errori('Rewrite on prd file      ');
                                prrfn: rewrite(prr)
                              end
                           else begin
                                filstate[fn] := fwrite;
                                rewrite(filtable[fn]);
                           end
                      end;
           24(*wrb*): begin popint(w); popint(i); b := i <> 0; popadr(ad);
                            pshadr(ad); valfil(ad); fn := store[ad];
                            if w < 1 then errori('Width cannot be < 1      ');
                            if fn <= prrfn then case fn of
                                 inputfn: errori('Write on input file      ');
                                 outputfn: write(output, b:w);
                                 prdfn: errori('Write on prd file        ');
                                 prrfn: write(prr, b:w)
                              end
                            else begin
                                if filstate[fn] <> fwrite then
                                   errori('File not in write mode   ');
                                write(filtable[fn], b:w)
                            end
                      end;
           25(*wrf*): begin popint(f); popint(w); poprel(r); popadr(ad); pshadr(ad);
                            valfil(ad); fn := store[ad];
                            if w < 1 then errori('Width cannot be < 1      ');
                            if f < 1 then errori('Fraction cannot be < 1   ');
                            if fn <= prrfn then case fn of
                                 inputfn: errori('Write on input file      ');
                                 outputfn: write(output, r:w:f);
                                 prdfn: errori('Write on prd file        ');
                                 prrfn: write(prr, r:w:f)
                              end
                            else begin
                                if filstate[fn] <> fwrite then
                                   errori('File not in write mode   ');
                                write(filtable[fn], r:w:f)
                            end
                      end;
           26(*dsp*): begin
                           popadr(ad1); popadr(ad); dspspc(ad1, getadr(ad))
                      end;
           40(*dsl*): begin
                           popadr(ad1); popint(i);
                           ad := getadr(sp-(i+1)*intsize); ad := getadr(ad);
                           ad := ad-intsize; ad3 := ad;
                           if getint(ad) <= adrsize then
                             errori('Block already freed      ');
                           if i <> getint(ad)-adrsize-1 then
                             errori('New/dispose tags mismatch');
                           ad := ad-intsize; ad2 := sp-intsize;
                           { ad = top of tags in dynamic, ad2 = top of tags in
                             stack }
                           k := i;
                           while k > 0 do
                             begin
                               if getint(ad) <> getint(ad2) then
                                 errori('New/dispose tags mismatch');
                               ad := ad-intsize; ad2 := ad2-intsize; k := k-1
                             end;
                           dspspc(ad1+(i+1)*intsize, ad+intsize);
                           while i > 0 do popint(i)
                      end;
           27(*wbf*): begin popint(l); popadr(ad1); popadr(ad); pshadr(ad);
                           valfilwm(ad); fn := store[ad];
                           for i := 1 to l do begin
                              chkdef(ad1); write(bfiltable[fn], store[ad1]);
                              ad1 := ad1+1
                           end
                      end;
           28(*wbi*): begin popint(i); popadr(ad); pshadr(ad); pshint(i);
                            valfilwm(ad); fn := store[ad];
                            for i := 1 to intsize do
                               write(bfiltable[fn], store[sp-intsize+i-1]);
                            popint(i)
                      end;
           29(*wbr*): begin poprel(r); popadr(ad); pshadr(ad); pshrel(r);
                            valfilwm(ad); fn := store[ad];
                            for i := 1 to realsize do
                               write(bfiltable[fn], store[sp-realsize+i-1]);
                            poprel(r)
                      end;
           30(*wbc*): begin popint(i); c := chr(i); popadr(ad); pshadr(ad); pshint(i);
                            valfilwm(ad); fn := store[ad];
                            for i := 1 to charsize do
                               write(bfiltable[fn], store[sp-intsize+i-1]);
                            popint(i)
                      end;
           31(*wbb*): begin popint(i); popadr(ad); pshadr(ad); pshint(i);
                            valfilwm(ad); fn := store[ad];
                            for i := 1 to boolsize do
                               write(bfiltable[fn], store[sp-intsize+i-1]);
                            popint(i)
                      end;
           32(*rbf*): begin popint(l); popadr(ad1); popadr(ad); pshadr(ad);
                            valfilrm(ad); fn := store[ad];
                            if filbuff[fn] then { buffer data exists }
                            for i := 1 to l do
                              store[ad1+i-1] := store[ad+fileidsize+i-1]
                            else begin
                              if eof(bfiltable[fn]) then
                                errori('End of file              ');
                              for i := 1 to l do begin
                                read(bfiltable[fn], store[ad1]);
                                putdef(ad1, true);
                                ad1 := ad1+1
                              end
                            end
                      end;
           33(*rsb*): begin popadr(ad); valfil(ad); fn := store[ad];
                           if filstate[fn] = fclosed then
                             errori('Cannot reset closed file ');
                           filstate[fn] := fread;
                           reset(bfiltable[fn]);
                           filbuff[fn] := false
                      end;
           34(*rwb*): begin popadr(ad); valfil(ad); fn := store[ad];
                           filstate[fn] := fwrite;
                           rewrite(bfiltable[fn]);
                           filbuff[fn] := false
                      end;
           35(*gbf*): begin popint(i); popadr(ad); valfilrm(ad);
                           fn := store[ad];
                           if filbuff[fn] then filbuff[fn] := false
                           else
                             for j := 1 to i do
                                read(bfiltable[fn], store[ad+fileidsize+j-1])
                      end;
           36(*pbf*): begin popint(i); popadr(ad); valfilwm(ad);
                        fn := store[ad];
                        if not filbuff[fn] then
                          errori('File buffer undefined    ');
                        for j := 1 to i do
                          write(bfiltable[fn], store[ad+fileidsize+j-1]);
                        filbuff[fn] := false;
                      end;
           43 (*fbv*): begin popadr(ad); pshadr(ad); valfil(ad);
                          fn := store[ad];
                          if fn = inputfn then putchr(ad+fileidsize, input^)
                          else if fn = prdfn then putchr(ad+fileidsize, prd^)
                          else begin
                            if filstate[fn] = fread then
                            putchr(ad+fileidsize, filtable[fn]^)
                          end
                        end;
           44 (*fvb*): begin popint(i); popadr(ad); pshadr(ad); valfil(ad);
                          fn := store[ad];
                          { load buffer only if in read mode, and buffer is
                            empty }
                          if (filstate[fn] = fread) and not filbuff[fn] then
                            begin
                              for j := 1 to i do begin
                                read(bfiltable[fn], store[ad+fileidsize+j-1]);
                                putdef(ad+fileidsize+j-1, true)
                              end
                            end;
                          filbuff[fn] := true
                        end;
      end;(*case q*)
end;(*callsp*)

begin (* main *)

  writeln('P5 Pascal generator for I80386/gcc vs. ', majorver:1, '.', minorver:1);
  writeln;

  rewrite(prr);

  { construct bit equivalence table }
  i := 1;
  for bai := 0 to 7 do begin bitmsk[bai] := i; i := i*2 end;

  writeln('Generating program');
  genprg; (* assembles and stores code *)

  dsi := 0; { reset data stack }

  1 : { abort program }

  writeln;
  writeln('program complete');

end.
