Goal:
- A similar experience as jupyter

Features:
- Code (selected text, current line, current paragraph) can be sent to a repl
    - When a paragraph is evaluated, all result lines are stripped first
    - Then a placeholder is inserted
    - The result string is collected async
    - The placeholder is replaced with the result
- The result will be inserted below as comment
    - e.g. R inserted results are commented out as `%= RESULT`
    - The result is highlighted in the original synatx
- Support for code completion

Backends:
- vim
- R
- bash
- +++

TODO:
- Interactive repl, e.g. for debuggung in R

