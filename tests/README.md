# Focused reagent-bank regression tests

Run `python3 tests/run.py` with a C++20 compiler. `CXX`, `CXXFLAGS` and
`BUILD_DIR` select compiler, instrumentation and output directory. Sanitizer
reports are fatal. `python3 tests/mutations.py` requires all 24 representative
production mutants to compile and fail a behavioral assertion; compiler errors,
crashes and timeouts do not count as successful detections.

The runner extracts 14 explicitly selected production function definitions
**verbatim**, with their production stored-item/mode/limit definitions. `#line`
attributes execution to the original C++ file. It fails when a selected
function/dependency is missing or ambiguous. There is no runtime source change.
The shared CI retains real core-header compilation; worker validation additionally
links the complete module into pinned core `9e4a232a84d375a8906717c5139fb8d6bf2e41d6`.

Covered behaviors:

- Checked addition at zero/UINT32_MAX, failed output/map preservation, 64-bit
  totals, strict unsigned parsing, duplicate aggregation and 80-pair limit.
- Zero/one/stack/all withdrawals, request above stock, zero stock, missing
  template, zero stack-size fallback, full bags, partial bag space and item
  creation failure. Assert actual fixture inventory + remaining bank stock,
  reported totals, notifications and appended debit amounts agree.
- Deposit refusal for missing/traded/ineligible/excluded/quest-needed items,
  wrong category and zero count; stored/map overflow preserves inventory.
- Account/character key isolation, share-owner remapping and map removal.
- Relative addition/debit SQL text and arguments, saturation expression and
  zero-row cleanup, and no writes for unchanged amounts.
- Inventory save and bank statements use the same transaction, verified from a
  statement snapshot captured at commit submission; empty transactions
  do nothing; commit failure is logged. A real promise/future holds the commit
  incomplete and proves the function waits before returning.

## Coverage scope and gaps

**The gcovr denominator is only selected functions, not the entire module.**
`selection.txt` lists selected source lines. CI gates selected executable lines
at 98%, functions at 100%, filtered branch outcomes at 90%; it retains raw JSON.
Throw/unreachable compiler branches are excluded. Omitted C++ functions, loader,
Lua files and future production functions are not instrumented by this harness.
Do not describe this as whole-module or fleet coverage. Whole-module executable
line/branch coverage remains unmeasured.

`Player`, `Item`, object manager, eligibility checks, `LoadStoredItem` and database
services are explicit doubles. SQL text/argument checks do **not** execute MySQL
or prove its relative-delta, saturation, locking or durability semantics. No
realm DB, credentials, worldserver startup, installation or deployment is used.
The commit test establishes waiting and ordering at the API boundary, not real
rollback or crash recovery. The suite does not simulate persisted inventory.

Remaining: real disposable MySQL/core integration (concurrent AH deltas, repeated
commands reading committed stock, commit failure and crash recovery), full
command dispatch, Self-Found restrictions, share enable/disable/load/invite/
acceptance/ownership lifecycle, command replay, category/multi-item operations,
full deposit eligibility, addon Lua 5.1 protocol and timer lifecycle, and game
client acceptance. Key-map mutation tests do not establish sharing lifecycle.

WithdrawExact checks its output-map accumulation after creating an item. A caller
supplying a prepopulated same-item map near UINT32_MAX could reach that overflow
path after item creation. Current parser/callers constrain requests; no external
command reproducer was established. This internal-contract edge remains
unverified and is not covered by the arithmetic helper tests. No runtime fix is
bundled without an established reproducer.
