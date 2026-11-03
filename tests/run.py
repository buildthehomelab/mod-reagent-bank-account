#!/usr/bin/env python3
"""Execute verbatim production functions with isolated service doubles.

Extraction is deliberately explicit: this is partial C++ coverage, not a full-TU
or command-dispatch test. Fail closed if selected definitions move/disappear.
"""
import os
from pathlib import Path
import re
import shlex
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
FUNCTIONS = ['ToLower', 'TryParseUInt32', 'AddAmountChecked',
             'AddToItemAmountMapChecked', 'SumItemAmountMap',
             'TryParseItemAmountPairs', 'GetStorageKeys', 'GetShareKey',
             'AppendStoredItemChange', 'CommitStoredItemChanges', 'DepositFromSlot', 'WithdrawExact',
             'WithdrawItem', 'ParseWithdrawMode']


def extract(source, name):
    matches = list(re.finditer(r'^    static [^\n]+\b' + name + r'\([^\n]*\)\n    \{', source, re.M))
    if len(matches) != 1:
        raise RuntimeError(f'Expected exactly one definition: {name}, got {len(matches)}')
    start = matches[0].start()
    # The module consistently closes functions at namespace indentation. Nested
    # blocks and SQL strings cannot close a function at this indentation.
    end = source.index('\n    }', matches[0].end()) + len('\n    }')
    return start, end


def run(build):
    path = Path(os.environ.get('REAGENT_SOURCE', ROOT / 'src/ReagentBankAccount.cpp')).resolve()
    source = path.read_text()
    definitions = []
    patterns = [r'    struct StoredItem\n    \{.*?\n    \};',
                r'    enum class WithdrawMode : uint8\n    \{.*?\n    \};',
                r'    static constexpr uint32 MAX_REAGENT_BANK_STORED_AMOUNT = [^;]+;',
                r'    static constexpr std::size_t MAX_REAGENT_BANK_ITEM_AMOUNT_PAIRS = [^;]+;',
                r'    using ItemAmountMap = [^;]+;']
    for pattern in patterns:
        matches = list(re.finditer(pattern, source, re.S))
        if len(matches) != 1:
            raise RuntimeError(f'Expected one dependency definition: {pattern}')
        definitions.append(matches[0].group() + '\n')
    (build / 'definitions.inc').write_text(''.join(definitions))
    generated = ['// Generated from production; do not edit.\n']
    selected_lines = set()
    for name in FUNCTIONS:
        start, end = extract(source, name)
        line = source.count('\n', 0, start) + 1
        generated += [f'#line {line} "{path}"\n', source[start:end], '\n']
        selected_lines.update(range(line, line + source[start:end].count('\n') + 1))
    (build / 'production.inc').write_text(''.join(generated))
    (build / 'selection.txt').write_text('\n'.join(map(str, sorted(selected_lines))) + '\n')
    compiler = shlex.split(os.environ.get('CXX', 'c++'))
    flags = shlex.split(os.environ.get('CXXFLAGS', ''))
    if any(x.startswith('-fsanitize=') for x in flags):
        flags += ['-fno-sanitize-recover=all']
    for pattern in ('*.gcda', '*.gcno'):
        for profile in build.glob(pattern):
            profile.unlink()
    exe = build / 'reagent-tests'
    subprocess.run(compiler + ['-std=c++20', '-Wall', '-Wextra', '-Werror', '-pthread'] + flags +
                   ['-I', str(build), str(ROOT / 'tests/test_reagent.cpp'), '-o', str(exe)], check=True)
    subprocess.run([str(exe)], check=True, timeout=30)


if __name__ == '__main__':
    if os.environ.get('BUILD_DIR'):
        directory = Path(os.environ['BUILD_DIR']).resolve()
        directory.mkdir(parents=True, exist_ok=True)
        run(directory)
    else:
        with tempfile.TemporaryDirectory(prefix='reagent-tests-') as tmp:
            run(Path(tmp))
