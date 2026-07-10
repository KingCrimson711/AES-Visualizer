<div align="center">

# AES Visualizer

### A from-scratch, hardware-and-software implementation of the Advanced Encryption Standard

![AES](https://img.shields.io/badge/AES-128%2F192%2F256-1a1a40?style=for-the-badge&labelColor=0d0d2b)
![C++](https://img.shields.io/badge/Core-C%2B%2B-00274d?style=for-the-badge&labelColor=001b33)
![Verilog](https://img.shields.io/badge/Hardware-SystemVerilog-4b0082?style=for-the-badge&labelColor=2e004d)
![GF(2^8)](https://img.shields.io/badge/Math-GF(2⁸)_Field_Arithmetic-6a0dad?style=for-the-badge&labelColor=330033)
![Status](https://img.shields.io/badge/Status-Verified-2e8b57?style=for-the-badge&labelColor=1b4d3e)

**[▶ Live Demo](https://fastidious-duckanoo-d04db2.netlify.app/)** &nbsp;|&nbsp; **[📂 Source Code](https://github.com/KingCrimson711/AES-Visualizer)**

</div>

---

##  Table of Contents

1. [What This Project Is](#-what-this-project-is)
2. [What Is AES?](#-what-is-aes)
3. [The Math Behind AES: Galois Field GF(2⁸)](#-the-math-behind-aes-galois-field-gf28)
4. [Worked Example: Multiplying 0x12 × 0x11 by Hand](#-worked-example-multiplying-0x12--0x11-by-hand)
5. [How `gfmul()` Implements This in Code](#-how-gfmul-implements-this-in-code)
6. [SubBytes: The Only Non-Linear Step](#-subbytes-the-only-non-linear-step)
7. [ShiftRows & MixColumns: Diffusion](#-shiftrows--mixcolumns-diffusion)
8. [The Avalanche Effect](#-the-avalanche-effect)
9. [Key Expansion (Brief)](#-key-expansion-brief)
10. [Hardware Implementation (SystemVerilog)](#-hardware-implementation-systemverilog)
11. [Repository Structure](#-repository-structure)
12. [Building & Running](#-building--running)
13. [References & Further Reading](#-references--further-reading)
14. [Disclaimer](#-disclaimer)

---

##  What This Project Is

This repository contains **two independent implementations of AES built from first principles**, without relying on any cryptographic library:

- **`aes.cpp`** — a complete software implementation of the AES algorithm in C++, verified against known-answer test vectors.
- **`InVerilog.sv` / `ExampleTestBench.sv`** — a hardware-level (SystemVerilog) implementation of the same algorithm, simulating how AES would actually run on a digital circuit.

The goal of this project is not just to encrypt data, but to **show exactly how and why AES works** — the finite-field arithmetic underneath it, why its substitution step is non-linear, and why that non-linearity is the entire reason the cipher is secure. This README walks through that math from scratch, so no prior background in abstract algebra is assumed.

A live, interactive visualizer of the algorithm is hosted here: **https://fastidious-duckanoo-d04db2.netlify.app/**

---

##  What Is AES?

The **Advanced Encryption Standard (AES)** is a symmetric-key block cipher, standardized by NIST in 2001 (FIPS PUB 197) as the successor to DES, following an open five-year public competition won by the **Rijndael** cipher, designed by Belgian cryptographers Joan Daemen and Vincent Rijmen.

AES operates on fixed-size blocks of **128 bits (16 bytes)** of data, arranged conceptually as a **4×4 matrix of bytes**, called the **state**. Depending on the key size — **128, 192, or 256 bits** — the cipher runs the state through **10, 12, or 14 rounds** respectively. Each round (except the last, and with an extra round at the very start) applies four transformations to the state, in this order:

| Step | Purpose |
|---|---|
| **SubBytes** | Byte-wise, non-linear substitution using an S-box |
| **ShiftRows** | Cyclic left-shift of each row of the state |
| **MixColumns** | Linear mixing of each column, treated as a polynomial over GF(2⁸) |
| **AddRoundKey** | XOR the state with a round key derived from the key schedule |

AES is not "one trick" — it is a careful composition of a **non-linear** step (SubBytes) and several **linear** steps (ShiftRows, MixColumns, AddRoundKey), repeated over many rounds. This composition is what Claude Shannon, in his 1949 paper *Communication Theory of Secrecy Systems*, described as **confusion** (the relationship between key and ciphertext should be as complex as possible) and **diffusion** (each plaintext/key bit should influence many ciphertext bits). AES is essentially a textbook, very well-engineered realization of Shannon's confusion–diffusion principle.

Everything AES does — SubBytes, MixColumns, and the key schedule — is built on arithmetic in a specific finite field. To understand the algorithm at the level this project implements it, you have to understand that field first.

---

##  The Math Behind AES: Galois Field GF(2⁸)

AES does not treat a byte as an ordinary 8-bit binary number. Instead, every byte is treated as an element of the finite field **GF(2⁸)**, also called a **Galois Field** (named after Évariste Galois).

A byte such as `01010111` is interpreted as the coefficients of a **polynomial of degree ≤ 7** over GF(2) — meaning every coefficient is either 0 or 1:

```
b7 b6 b5 b4 b3 b2 b1 b0
  ↓
b7·x⁷ + b6·x⁶ + b5·x⁵ + b4·x⁴ + b3·x³ + b2·x² + b1·x¹ + b0·x⁰
```

For example:

```
0x57 = 01010111  →  x⁶ + x⁴ + x² + x + 1
```

**Addition** in GF(2⁸) is coefficient-wise addition **modulo 2**, which is exactly the same as a bitwise **XOR**. There is no carrying — a `1 + 1` simply becomes `0`, it does not roll over into the next bit.

**Multiplication** is more involved: you multiply the two polynomials the ordinary way (as you would in school), and then you **reduce the result modulo an irreducible polynomial**, because GF(2⁸) only has room for degree ≤ 7 polynomials (256 possible bytes). If you didn't reduce, the product of two degree-7 polynomials could go up to degree 14, which falls outside the field.

The polynomial AES uses for this reduction is fixed by the standard:

```
m(x) = x⁸ + x⁴ + x³ + x + 1        (in hex: 0x11B)
```

This is the **AES modulus** — an *irreducible* polynomial (it cannot be factored over GF(2)), which is exactly what guarantees that GF(2⁸) modulo m(x) forms a proper field, meaning every non-zero byte has a unique multiplicative inverse. That inverse property is precisely what SubBytes exploits (see the [SubBytes section](#-subbytes-the-only-non-linear-step) below).

**Book resource:** for a rigorous but very approachable treatment of this exact field arithmetic (including AES-specific examples), see **Christof Paar & Jan Pelzl, *Understanding Cryptography*, Chapter 4 ("The Advanced Encryption Standard") and its finite field appendix** — it is widely considered the best introductory text for this material, and the authors' companion lecture series is free on YouTube ("Introduction to Cryptography by Christof Paar"). For the canonical, original description straight from AES's designers, see Daemen & Rijmen, ***The Design of Rijndael*** (Springer), and the official standard, **NIST FIPS PUB 197**.

---

##  Worked Example: Multiplying 0x12 × 0x11 by Hand

This is the exact calculation your `gfmul()` function performs internally — done here longhand, step by step, the "simple school way" first, so you can see where every rule comes from before it gets compressed into code.

**Step 1 — Write both bytes in binary, and as polynomials.**

```
0x12 = 0001 0010  →  x⁴ + x¹              (bit 4 and bit 1 are set)
0x11 = 0001 0001  →  x⁴ + x⁰              (bit 4 and bit 0 are set)
```

**Step 2 — Multiply the two polynomials the ordinary way (like FOIL / distributing terms in school algebra).**

```
(x⁴ + 1) · (x⁴ + x)

= x⁴·x⁴  +  x⁴·x  +  1·x⁴  +  1·x
= x⁸     +  x⁵    +  x⁴    +  x
```

**Step 3 — Combine like terms, but remember: we are in GF(2), so coefficients are added modulo 2.**

Since no two terms above share the same power of `x`, there is nothing to cancel here — every term already has a coefficient of exactly 1. (If two identical powers of `x` *had* appeared, e.g. two `x⁵` terms, they would add to `1 + 1 = 0 (mod 2)` and simply vanish — this is the "remove it if it becomes 0 mod 2" rule you mentioned. It is precisely why GF(2) polynomial addition is the same operation as XOR.)

So after step 2 we're left with the intermediate polynomial:

```
x⁸ + x⁵ + x⁴ + x
```

This has degree 8, which is **too big** to be a valid byte (bytes only go up to degree 7). This is where field reduction comes in.

**Step 4 — Reduce modulo the AES modulus `m(x) = x⁸ + x⁴ + x³ + x + 1`.**

Because we are working modulo 2, and `m(x) = 0` inside the field, we can rearrange it to express `x⁸` in terms of lower powers:

```
m(x) = x⁸ + x⁴ + x³ + x + 1 = 0
   ⟹  x⁸ = x⁴ + x³ + x + 1        (mod 2, "subtracting" is the same as "adding")
```

Now substitute this in place of the `x⁸` term from Step 3:

```
  x⁸        + x⁵ + x⁴ + x
= (x⁴+x³+x+1) + x⁵ + x⁴ + x
```

Group and cancel matching powers (mod 2 — pairs of the same term cancel to 0):

```
=  x⁵  +  (x⁴ + x⁴)  +  x³  +  (x + x)  +  1
=  x⁵  +      0      +  x³  +    0      +  1
=  x⁵ + x³ + 1
```

**Step 5 — Convert back to binary / hex.**

```
x⁵ + x³ + 1  →  bits 5, 3, 0 set  →  0010 1001  →  0x29
```

###  Result

```
0x12  ⊗  0x11  =  0x29        (⊗ = multiplication in GF(2⁸))
```

You can sanity-check this using the standard "Russian peasant / shift-and-XOR" method (repeatedly doubling one operand and conditionally XOR-ing in `0x1B` whenever the top bit overflows) — it produces the exact same `0x29`, which is expected, since that shift-and-XOR method is just this same modular reduction performed one power of `x` at a time. That equivalence is exactly what the next section explains.

---

## ⚙️ How `gfmul()` Implements This in Code

Writing out full polynomial long multiplication for every byte pair, as done above, is correct but slow. Real AES implementations — including the `gfmul()` function in `aes.cpp` — use a much faster method built on one repeated primitive operation, usually called **`xtime`**, that computes "multiply by `x`" (i.e., multiply by 2) inside the field:

```cpp
uint8_t xtime(uint8_t a) {
    uint8_t result = a << 1;          // multiply by x  (shift the polynomial up one degree)
    if (a & 0x80)                     // did we overflow past degree 7 (i.e. bit 8 became set)?
        result ^= 0x1B;                // if so, reduce modulo m(x): x⁸ ≡ x⁴+x³+x+1  →  0x1B
    return result;
}
```

Every part of this mirrors a step from the hand calculation above:

- **`a << 1`** is exactly "multiply the polynomial by `x`" — it shifts every term up one power, the same as multiplying `x⁴ + x` by `x` to get `x⁵ + x²`.
- **checking the top bit (`a & 0x80`)** is checking whether that shift pushed a term into `x⁸` or beyond — exactly the situation that forced us to invoke `m(x)` in Step 4 above.
- **XOR-ing with `0x1B`** *is* the substitution `x⁸ = x⁴+x³+x+1` from Step 4, just pre-computed as a constant. `0x1B` in binary is `0001 1011`, which is literally `x⁴+x³+x+1` written as a byte. XOR-ing it in performs the modular reduction in one instruction instead of long division.

A full `gfmul(a, b)` builds on `xtime` by decomposing `b` into powers of two (its individual set bits) and adding together `a` shifted (and reduced) by each of those powers — precisely the "distribute across each term of the second polynomial" step from Step 2, except now each partial product is kept safely inside the field the entire time thanks to `xtime`'s built-in reduction:

```cpp
uint8_t gfmul(uint8_t a, uint8_t b) {
    uint8_t result = 0;
    while (b) {
        if (b & 1)
            result ^= a;       // add this partial product in (mod-2 addition = XOR)
        a = xtime(a);          // move to the next power of x for 'a'
        b >>= 1;                // move to the next bit of 'b'
    }
    return result;
}
```

Tracing `gfmul(0x12, 0x11)` through this loop reproduces the exact same `0x29` derived by hand above — the algorithm is simply the school-book polynomial multiplication and reduction from the last section, reorganized so a computer (or, in the SystemVerilog version, a combinational circuit built from XOR gates and shifts) can execute it in a handful of cycles instead of symbolic algebra.

This `gfmul` routine is what powers **MixColumns**, where each output byte is a fixed linear combination of input bytes computed with exactly this field multiplication (by the constants `0x02` and `0x03`), and it is also what computes **multiplicative inverses** for the S-box construction described next.

---

##  SubBytes: The Only Non-Linear Step

Of the four operations in an AES round — SubBytes, ShiftRows, MixColumns, AddRoundKey — **SubBytes is the only one that is not linear** over GF(2⁸).

- **AddRoundKey** is an XOR — linear.
- **ShiftRows** just permutes byte positions — linear (it doesn't even touch the values).
- **MixColumns** is a fixed matrix multiplication over GF(2⁸) — linear, by definition of matrix multiplication.
- **SubBytes**, however, replaces every byte with a value looked up in the **S-box**, and the S-box is constructed from a genuinely non-linear function: it takes the **multiplicative inverse of the byte in GF(2⁸)** (with `0x00` mapped to itself, since 0 has no inverse), and then applies a fixed affine transformation on top of that inverse.

Why does this one non-linear step matter so much? Because **if every operation in AES were linear, the entire cipher — all 10/12/14 rounds combined — would collapse into a single, giant linear (or affine) function of the plaintext and key.** A linear (or affine) system over GF(2) can be described completely by a matrix and solved with basic linear algebra — specifically Gaussian elimination — in polynomial time, regardless of how many rounds you stacked on top of each other. Adding more purely-linear rounds would not add any real security; it would just make the single equivalent linear system slightly bigger, and bigger linear systems are still trivially solvable by a computer.

More concretely, without a non-linear component, an attacker performing **linear cryptanalysis** could construct linear approximations relating plaintext bits, ciphertext bits, and key bits that hold with *certainty* rather than mere statistical bias, and simply solve for the key directly. The entire reason linear cryptanalysis against real AES is hard — and only ever succeeds with tiny, impractical statistical biases against reduced-round variants — is that the S-box breaks the linearity everywhere it's applied, forcing any linear approximation of the full cipher to accumulate error across every SubBytes application in every round, until the approximation's bias becomes so small it's operationally useless.

In short: **linear operations preserve structure, and structure is exactly what a cryptanalyst exploits.** The S-box's non-linearity is what forces an attacker back onto exhaustive search (or genuinely hard algebraic/statistical problems) instead of straightforward linear-algebra techniques. This is the whole reason SubBytes exists, and why so much design effort in Rijndael went into choosing the specific inverse-based construction of the S-box rather than an arbitrary substitution table.

---

##  ShiftRows & MixColumns: Diffusion

If SubBytes provides *confusion* (obscuring the relationship between key and ciphertext), **ShiftRows and MixColumns provide *diffusion*** — spreading the influence of any single input byte across the entire state as quickly as possible.

- **ShiftRows** cyclically shifts row *r* of the state left by *r* bytes (row 0 unshifted, row 1 shifted by 1, row 2 by 2, row 3 by 3). On its own this only moves bytes around — it doesn't mix their values — but it guarantees that bytes which started in the same column are spread across different columns for the next step.
- **MixColumns** then takes each column and multiplies it (using `gfmul`, as described above) by a fixed 4×4 matrix over GF(2⁸), so that every output byte in a column becomes a combination of *all four* input bytes in that column.

Neither step alone would do much. But because ShiftRows first scatters bytes across columns, and MixColumns then mixes every byte within a column, **repeating [ShiftRows → MixColumns] over several rounds causes a single changed input byte to influence every byte of the state** — which is the mechanical basis for the avalanche effect described next.

---

##  The Avalanche Effect

The **avalanche effect** is the property that flipping a **single bit** of the plaintext (or a single bit of the key) should, after passing through the full cipher, change **roughly half of the bits of the ciphertext**, in a way that looks essentially random and unpredictable from the outside.

Formally, for a "good" block cipher, if you flip one bit of the input, each output bit should flip with probability close to **50%**, independently of which bit you flipped and independently of the rest of the plaintext/key. Ideally the cipher behaves like a random function with respect to this property — an attacker observing the ciphertext should gain no exploitable statistical correlation back to which input bit changed.

This is not a side effect of AES — it is a **design requirement** that the confusion/diffusion structure is specifically built to satisfy:

- The **non-linear SubBytes** step ensures small input changes get transformed unpredictably rather than proportionally (a linear function, by contrast, would only ever spread a bit-flip by a small, predictable, fixed amount).
- The **diffusion layers (ShiftRows + MixColumns)** ensure that unpredictability doesn't stay localized to one byte — it is actively spread to the entire 128-bit state.
- Repeating this combination over **multiple rounds** compounds the spread until, empirically, a single flipped input bit has propagated influence to essentially every output bit.

AES's security **relies** on this property directly: if flipping one plaintext bit only changed, say, 2 output bits in a predictable pattern, an attacker could build statistical models correlating specific input and output bits and gradually recover information about the key — exactly the kind of attack (differential and linear cryptanalysis) that AES's designers explicitly evaluated the cipher against. A strong avalanche effect is what makes ciphertext appear indistinguishable from random noise to anyone without the key, which is the practical, testable signature of a cipher resisting these statistical attacks.

You can observe this directly in this project's live visualizer — flip a single input bit and compare how much of the resulting ciphertext state changes after each round.

---

##  Key Expansion (Brief)

AES does not reuse the same key for every round. A **key schedule** expands the original cipher key into a series of **round keys** (one 128-bit round key per round, plus one extra for the initial `AddRoundKey`), using a recursive process built from:

- **RotWord** — a one-byte cyclic rotation of a 4-byte word,
- **SubWord** — applying the same S-box used in SubBytes to each byte of a word,
- **XOR with round constants (`Rcon`)** — constants derived from powers of `x` in GF(2⁸), which prevent symmetry/self-similarity between round keys.

This means the same non-linear S-box that protects the data path also protects the key schedule, so that related-key attacks can't exploit a purely linear relationship between round keys either.

---

##  Hardware Implementation (SystemVerilog)

Alongside the C++ software model, this repository includes a **register-transfer-level (RTL) hardware description** of AES in SystemVerilog:

- **`InVerilog.sv`** — the synthesizable hardware implementation of the cipher's datapath (SubBytes, ShiftRows, MixColumns, AddRoundKey, and the key schedule, realized as combinational/sequential logic rather than software instructions).
- **`ExampleTestBench.sv`** — a testbench that drives known plaintext/key vectors through the design and checks the resulting ciphertext, the hardware equivalent of the C++ implementation's verification tests.

The point of including both a software and a hardware model side by side is to show that AES is not tied to any one execution model — the exact same field arithmetic (`GF(2⁸)` multiplication, the S-box's inverse-based non-linearity, the round structure) that runs as C++ instructions on a CPU can equally be expressed as combinational logic gates and clocked registers on silicon. Comparing the two implementations is a useful way to see which parts of AES are "just math" versus which parts are artifacts of a particular execution model.

---

##  Repository Structure

```
AES-Visualizer/
├── aes.cpp               # Full AES software implementation (C++)
├── InVerilog.sv           # AES hardware datapath (SystemVerilog)
├── ExampleTestBench.sv    # Testbench for the SystemVerilog implementation
└── README.md              # This file
```

---

##  Building & Running

**C++ implementation:**

```bash
g++ -std=c++17 -O2 aes.cpp -o aes
./aes
```

**SystemVerilog implementation:**

Simulate `InVerilog.sv` against `ExampleTestBench.sv` using any standard SystemVerilog simulator (e.g. Icarus Verilog, ModelSim/QuestaSim, or Verilator):

```bash
iverilog -g2012 -o aes_tb InVerilog.sv ExampleTestBench.sv
vvp aes_tb
```

---

##  References & Further Reading

- **Christof Paar & Jan Pelzl** — *Understanding Cryptography: A Textbook for Students and Practitioners* (Springer). The clearest available introduction to GF(2⁸) arithmetic and the full AES round structure; free companion lectures on YouTube.
- **Joan Daemen & Vincent Rijmen** — *The Design of Rijndael: AES — The Advanced Encryption Standard* (Springer). Written by AES's own designers; the definitive source on the design rationale behind the S-box, MixColumns matrix, and reduction polynomial.
- **NIST** — *FIPS PUB 197: Advanced Encryption Standard (AES)*, the official standard specification.
- **Dan Boneh & Victor Shoup** — *A Graduate Course in Applied Cryptography* (freely available online) — for the broader cryptanalytic context (linear/differential cryptanalysis, confusion/diffusion) referenced above.

---

---

##  Connect

<div align="center">

[![GitHub](https://img.shields.io/badge/GitHub-KingCrimson711-0d0d2b?style=for-the-badge&logo=github&logoColor=white)](https://github.com/KingCrimson711)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Srijan%20S-0a3d62?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/srijan-s-6ab127290/)
[![Email](https://img.shields.io/badge/Email-srijan23101%40iiitnr.edu.in-4b0082?style=for-the-badge&logo=gmail&logoColor=white)](mailto:srijan23101@iiitnr.edu.in)

</div>
