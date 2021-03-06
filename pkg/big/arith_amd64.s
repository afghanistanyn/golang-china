// Copyright 2009 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// This file provides fast assembly versions for the elementary
// arithmetic operations on vectors implemented in arith.go.

// TODO(gri) - experiment with unrolled loops for faster execution

// func addVV(z, x, y *Word, n int) (c Word)
TEXT ·addVV(SB),7,$0
	MOVQ z+0(FP), R10
	MOVQ x+8(FP), R8
	MOVQ y+16(FP), R9
	MOVL n+24(FP), R11
	MOVQ $0, BX         // i = 0
	MOVQ $0, DX         // c = 0
	JMP E1

L1:	MOVQ (R8)(BX*8), AX
	RCRQ $1, DX
	ADCQ (R9)(BX*8), AX
	RCLQ $1, DX
	MOVQ AX, (R10)(BX*8)
	ADDL $1, BX			// i++

E1:	CMPQ BX, R11		// i < n
	JL L1

	MOVQ DX, c+32(FP)
	RET


// func subVV(z, x, y *Word, n int) (c Word)
// (same as addVV_s except for SBBQ instead of ADCQ and label names)
TEXT ·subVV(SB),7,$0
	MOVQ z+0(FP), R10
	MOVQ x+8(FP), R8
	MOVQ y+16(FP), R9
	MOVL n+24(FP), R11
	MOVQ $0, BX         // i = 0
	MOVQ $0, DX         // c = 0
	JMP E2

L2:	MOVQ (R8)(BX*8), AX
	RCRQ $1, DX
	SBBQ (R9)(BX*8), AX
	RCLQ $1, DX
	MOVQ AX, (R10)(BX*8)
	ADDL $1, BX         // i++

E2:	CMPQ BX, R11        // i < n
	JL L2

	MOVQ DX, c+32(FP)
	RET


// func addVW(z, x *Word, y Word, n int) (c Word)
TEXT ·addVW(SB),7,$0
	MOVQ z+0(FP), R10
	MOVQ x+8(FP), R8
	MOVQ y+16(FP), AX   // c = y
	MOVL n+24(FP), R11
	MOVQ $0, BX         // i = 0
	JMP E3

L3:	ADDQ (R8)(BX*8), AX
	MOVQ AX, (R10)(BX*8)
	RCLQ $1, AX
	ANDQ $1, AX
	ADDL $1, BX         // i++

E3:	CMPQ BX, R11        // i < n
	JL L3

	MOVQ AX, c+32(FP)
	RET


// func subVW(z, x *Word, y Word, n int) (c Word)
TEXT ·subVW(SB),7,$0
	MOVQ z+0(FP), R10
	MOVQ x+8(FP), R8
	MOVQ y+16(FP), AX   // c = y
	MOVL n+24(FP), R11
	MOVQ $0, BX         // i = 0
	JMP E4

L4:	MOVQ (R8)(BX*8), DX	// TODO(gri) is there a reverse SUBQ?
	SUBQ AX, DX
	MOVQ DX, (R10)(BX*8)
	RCLQ $1, AX
	ANDQ $1, AX
	ADDL $1, BX          // i++

E4:	CMPQ BX, R11         // i < n
	JL L4

	MOVQ AX, c+32(FP)
	RET


// func shlVW(z, x *Word, s Word, n int) (c Word)
TEXT ·shlVW(SB),7,$0
	MOVQ z+0(FP), R10
	MOVQ x+8(FP), R8
	MOVQ s+16(FP), CX
	MOVL n+24(FP), R11
	MOVQ $0, AX         // c = 0
	MOVQ $0, BX         // i = 0
	JMP E8

L8:	MOVQ (R8)(BX*8), DX
	MOVQ DX, R12
	SHLQ CX, DX:AX
	MOVQ DX, (R10)(BX*8)
	MOVQ R12, AX
	ADDL $1, BX          // i++

E8:	CMPQ BX, R11         // i < n
	JL L8

	MOVQ $0, DX
	SHLQ CX, DX:AX
	MOVQ DX, c+32(FP)
	RET


// func shrVW(z, x *Word, s Word, n int) (c Word)
TEXT ·shrVW(SB),7,$0
	MOVQ z+0(FP), R10
	MOVQ x+8(FP), R8
	MOVQ s+16(FP), CX
	MOVL n+24(FP), BX   // i = n
	MOVQ $0, AX         // c = 0
	JMP E9

L9:	MOVQ (R8)(BX*8), DX
	MOVQ DX, R12
	SHRQ CX, DX:AX
	MOVQ DX, (R10)(BX*8)
	MOVQ R12, AX

E9:	SUBL $1, BX         // i--
	JGE L9

	MOVQ $0, DX
	SHRQ CX, DX:AX
	MOVQ DX, c+32(FP)
	RET


// func mulAddVWW(z, x *Word, y, r Word, n int) (c Word)
TEXT ·mulAddVWW(SB),7,$0
	MOVQ z+0(FP), R10
	MOVQ x+8(FP), R8
	MOVQ y+16(FP), R9
	MOVQ r+24(FP), CX   // c = r
	MOVL n+32(FP), R11
	MOVQ $0, BX         // i = 0
	JMP E5

L5:	MOVQ (R8)(BX*8), AX
	MULQ R9
	ADDQ CX, AX
	ADCQ $0, DX
	MOVQ AX, (R10)(BX*8)
	MOVQ DX, CX
	ADDL $1, BX         // i++

E5:	CMPQ BX, R11        // i < n
	JL L5

	MOVQ CX, c+40(FP)
	RET


// func addMulVVW(z, x *Word, y Word, n int) (c Word)
TEXT ·addMulVVW(SB),7,$0
	MOVQ z+0(FP), R10
	MOVQ x+8(FP), R8
	MOVQ y+16(FP), R9
	MOVL n+24(FP), R11
	MOVQ $0, BX         // i = 0
	MOVQ $0, CX         // c = 0
	JMP E6

L6:	MOVQ (R8)(BX*8), AX
	MULQ R9
	ADDQ (R10)(BX*8), AX
	ADCQ $0, DX
	ADDQ CX, AX
	ADCQ $0, DX
	MOVQ AX, (R10)(BX*8)
	MOVQ DX, CX
	ADDL $1, BX         // i++

E6:	CMPQ BX, R11        // i < n
	JL L6

	MOVQ CX, c+32(FP)
	RET


// divWVW(z* Word, xn Word, x *Word, y Word, n int) (r Word)
TEXT ·divWVW(SB),7,$0
	MOVQ z+0(FP), R10
	MOVQ xn+8(FP), DX   // r = xn
	MOVQ x+16(FP), R8
	MOVQ y+24(FP), R9
	MOVL n+32(FP), BX   // i = n
	JMP E7

L7:	MOVQ (R8)(BX*8), AX
	DIVQ R9
	MOVQ AX, (R10)(BX*8)

E7:	SUBL $1, BX         // i--
	JGE L7              // i >= 0

	MOVQ DX, r+40(FP)
	RET
