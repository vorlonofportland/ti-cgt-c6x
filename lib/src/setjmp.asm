;******************************************************************************
;* SETJMP  v8.0.0B4                                                           *
;*                                                                            *
;* Copyright (c) 1996-2014 Texas Instruments Incorporated                     *
;* http://www.ti.com/                                                         *
;*                                                                            *
;*  Redistribution and  use in source  and binary forms, with  or without     *
;*  modification,  are permitted provided  that the  following conditions     *
;*  are met:                                                                  *
;*                                                                            *
;*     Redistributions  of source  code must  retain the  above copyright     *
;*     notice, this list of conditions and the following disclaimer.          *
;*                                                                            *
;*     Redistributions in binary form  must reproduce the above copyright     *
;*     notice, this  list of conditions  and the following  disclaimer in     *
;*     the  documentation  and/or   other  materials  provided  with  the     *
;*     distribution.                                                          *
;*                                                                            *
;*     Neither the  name of Texas Instruments Incorporated  nor the names     *
;*     of its  contributors may  be used to  endorse or  promote products     *
;*     derived  from   this  software  without   specific  prior  written     *
;*     permission.                                                            *
;*                                                                            *
;*  THIS SOFTWARE  IS PROVIDED BY THE COPYRIGHT  HOLDERS AND CONTRIBUTORS     *
;*  "AS IS"  AND ANY  EXPRESS OR IMPLIED  WARRANTIES, INCLUDING,  BUT NOT     *
;*  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR     *
;*  A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT     *
;*  OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,     *
;*  SPECIAL,  EXEMPLARY,  OR CONSEQUENTIAL  DAMAGES  (INCLUDING, BUT  NOT     *
;*  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,     *
;*  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY     *
;*  THEORY OF  LIABILITY, WHETHER IN CONTRACT, STRICT  LIABILITY, OR TORT     *
;*  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE     *
;*  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.      *
;*                                                                            *
;******************************************************************************
        .include c60asm.i
 
;*---------------------------------------------------------------------------
;*   setjmp
;*
;*     C syntax  :   int setjmp(env)
;*                      jmp_buf *env;
;*
;*     Function  : Save callers current environment for a subsequent
;*                 call to longjmp.  Return 0.
;*---------------------------------------------------------------------------
;*
;*  NOTE : ANSI specifies that "setjmp.h" declare "setjmp" as a macro.
;*
;*         In the TIABI implementation, the setjmp macro calls a function
;*         "_setjmp".  However, since the user may not include "setjmp.h",
;*         we provide two entry-points to this function.
;*
;*         In the EABI implementation, the setjmp macro calls a function
;*         "setjmp".  No alternate entry point is provided.
;*
;*---------------------------------------------------------------------------
	.if	__TI_EABI__
	.sect	".text:setjmp"
	.else
	.sect	".text:_setjmp"
	.endif

	.clink

	.if	__TI_EABI__
        .global  setjmp
setjmp:	.asmfunc
	.else
        .global  _setjmp, __setjmp
__setjmp:
_setjmp: .asmfunc
	.endif

;*---------------------------------------------------------------------------
;* Registers stored to env_buf[] during TESLA-specific setjmp ...
;*
;* env_buf[0]  = A10
;* env_buf[1]  = A11
;* env_buf[2]  = A12
;* env_buf[3]  = A13
;* env_buf[4]  = A14
;* env_buf[5]  = A15
;* env_buf[6]  = B10
;* env_buf[7]  = B11
;* env_buf[8]  = B12
;* env_buf[9]  = B13
;* env_buf[10] = B14
;* env_buf[11] = B15
;* env_buf[12] = B3
;*
;*---------------------------------------------------------------------------
        .if     .TI_C6X_TESLA

         STW.D    B12, *A4(32)
         STW.D    B11, *A4(28)
         STW.D    B10, *A4(24)
         STW.D    A14, *A4(16)
         STW.D    A13, *A4(12)
         STW.D    A12, *A4(8)
         STW.D    A11, *A4(4)

         RET.S    B3
||       STW.D    B13, *A4(36)

         STW.D    A10, *A4(0)
         STW.D    B15, *A4(44)
         STW.D    B14, *A4(40)
         STW.D    A15, *A4(20)

         ZERO.L   A4
||       STW.D    B3,  *A4(48)

;*---------------------------------------------------------------------------
;* Registers stored to env_buf[] during non-TESLA setjmp ...
;*
;* env_buf[0]  = A10
;* env_buf[1]  = B10
;* env_buf[2]  = A11
;* env_buf[3]  = B11
;* env_buf[4]  = A12
;* env_buf[5]  = B12
;* env_buf[6]  = A13
;* env_buf[7]  = B13
;* env_buf[8]  = A14
;* env_buf[9]  = B14
;* env_buf[10] = A15
;* env_buf[11] = B15
;* env_buf[12] = B3
;*
;*---------------------------------------------------------------------------
        .else		; NON-TESLA

         MV     A4,  B4
||	 STW    B3,  *+A4(48)

         STW    A10, *+A4(0)
||       STW    B10, *+B4(4)
||       RET    B3

         STW    A11, *+A4(8)
||       STW    B11, *+B4(12)

         STW    A12, *+A4(16)
||       STW    B12, *+B4(20)

         STW    A13, *+A4(24)
||       STW    B13, *+B4(28)

         STW    A14, *+A4(32)
||       STW    B14, *+B4(36)

         STW    A15, *+A4(40)
||       STW    B15, *+B4(44)
||	 ZERO   A4

        .endif
        .endasmfunc

;*---------------------------------------------------------------------------
;*   longjmp
;*
;*     C syntax  :   int longjmp(env, returnvalue)
;*                      jmp_buf *env;
;*                      int     returnvalue;
;*
;*     Function  : Restore the context contained in the jump buffer.
;*                 This causes an apparent "2nd return" from the
;*                 setjmp invocation which built the "env" buffer.
;*                 This return appears to return "returnvalue".
;*                 NOTE: This function may not return 0.
;*---------------------------------------------------------------------------
	.if	    __TI_EABI__
	.sect    ".text:longjmp"
	.else
	.sect    ".text:_longjmp"
	.endif

	.clink

	.if	    __TI_EABI__
	.global longjmp
longjmp: .asmfunc
	.else
	.global _longjmp
_longjmp: .asmfunc
	.endif

;*---------------------------------------------------------------------------
;* Registers loaded from env_buf[] during TESLA-specific longjmp ...
;*
;* A10 = env_buf[0]
;* A11 = env_buf[1]
;* A12 = env_buf[2]
;* A13 = env_buf[3]
;* A14 = env_buf[4]
;* A15 = env_buf[5]
;* B10 = env_buf[6]
;* B11 = env_buf[7]
;* B12 = env_buf[8]
;* B13 = env_buf[9]
;* B14 = env_buf[10]
;* B15 = env_buf[11]
;* B3  = env_buf[12]
;*
;*---------------------------------------------------------------------------
        .if       .TI_C6X_TESLA

         LDW.D      *A4(48), B3
         LDW.D      *A4(40), B14
         LDW.D      *A4(4), A11
         LDW.D      *A4(8), A12
         LDW.D      *A4(12), A13
         LDW.D      *A4(16), A14
         LDW.D      *A4(24), B10
         LDW.D      *A4(28), B11
         LDW.D      *A4(32), B12
         LDW.D      *A4(36), B13
         LDW.D      *A4(20), A15

    	 CALLRET.S  B3
||       LDW.D      *A4(0), A10

         LDW.D      *A4(44), B15

         MV.L       B4, A0
   [!A0] MVK.L      1, B4
         MV.L       B4, A4

	 NOP        1

;*---------------------------------------------------------------------------
;* Registers loaded from env_buf[] during non-TESLA longjmp ...
;*
;* A10 = env_buf[0]
;* B10 = env_buf[1]
;* A11 = env_buf[2]
;* B11 = env_buf[3]
;* A12 = env_buf[4]
;* B12 = env_buf[5]
;* A13 = env_buf[6]
;* B13 = env_buf[7]
;* A14 = env_buf[8]
;* B14 = env_buf[9]
;* A15 = env_buf[10]
;* B15 = env_buf[11]
;* B3  = env_buf[12]
;*
;*---------------------------------------------------------------------------
        .else		; NON-TESLA

        ;  Start parallel loads

	 LDW    *+A4(48), A3

         MV     A4, B6
||	 MV     A4, A6
||       MV     B4, B2

         LDW    *+A6(0), A10
||       LDW    *+B6(4), B10
|| [B2]  MV     B4, A4
|| [!B2] MVK    1, A4

         LDW    *+A6(8), A11
||       LDW    *+B6(12), B11 

	 LDW    *+A6(16), A12
||	 LDW    *+B6(20), B12
 
	 LDW    *+A6(24), A13
||	 LDW    *+B6(28), B13
 
	 LDW    *+A6(32), A14
||	 LDW    *+B6(36), B14
 
	 LDW    *+A6(40), A15
||	 LDW    *+B6(44), B15
||	 RET    A3
	 NOP    5

         ; End parallel loads

        .endif
        .endasmfunc

