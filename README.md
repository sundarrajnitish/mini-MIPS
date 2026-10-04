# Final Project for course COEN 6741 Computer Architecture and Design (Winter 2023)

Team Members Include:
Nitish Sundarraj Balaji (Myself),
Nour Dekhil,
Amira Jemma,
Shu Gho

## v12

`v12/` is the final, fully verified design: a single-edge synchronous 5-stage pipeline with
branches and jumps resolved in ID, a load-use interlock, and EX and ID forwarding. It ships with a
self-checking testbench, a golden model, 1,000 random programs and mutation testing.
See [`v12/README.md`](v12/README.md).

**Interactive site:** https://sundarrajnitish.github.io/mini-MIPS/ (served from `docs/`). It has a
cycle-by-cycle pipeline simulator, a hazard tutorial, the design decisions and the verification results.
