# Final Project for course COEN 6741 Computer Architecture and Design (Winter 2023)

Team Members Include:
Nitish Sundarraj Balaji (Myself),
Nour Dekhil,
Amira Jemma,
Shu Gho

## v12 (2026 rework)

`v12/` is a corrected and fully verified version of the final design (`v11`):
single-edge synchronous pipeline, branches and jumps resolved in ID, a load-use interlock,
EX and ID forwarding, and a self-checking testbench with a golden model, 1,000 random programs
and mutation testing. See [`v12/README.md`](v12/README.md).

**Interactive site:** https://sundarrajnitish.github.io/mini-MIPS/ (served from `docs/`). It has a
cycle-by-cycle pipeline simulator, a hazard tutorial, the v11 design review and the verification results.
