# ripgrep (`rg`) Usage

`ripgrep` is a fast recursive search tool that respects `.gitignore` and skips hidden files and binary files by default.

## Basic Search

```bash
rg "pattern"                  # search in current directory
rg "pattern" src/             # search in specific directory
rg "pattern" file.txt         # search in specific file
```

## Common Flags

```bash
rg -i "pattern"               # case-insensitive
rg -l "pattern"               # list matching files only
rg -c "pattern"               # count matches per file
rg -n "pattern"               # show line numbers (on by default)
rg -v "pattern"               # invert match (lines that don't match)
```

## File Filtering

```bash
rg -t py "pattern"            # only Python files
rg -T js "pattern"            # exclude JavaScript files
rg -g "*.ts" "pattern"        # glob pattern
rg -g "!node_modules" "pattern"  # exclude a directory
```

## Context

```bash
rg -A 3 "pattern"             # 3 lines after match
rg -B 3 "pattern"             # 3 lines before match
rg -C 3 "pattern"             # 3 lines before and after
```

## Other Useful Flags

```bash
rg -w "word"                  # whole word match
rg -F "literal.string"        # fixed string (no regex)
rg --hidden "pattern"         # search hidden files/dirs
rg -u "pattern"               # don't respect .gitignore
rg --no-heading "pattern"     # compact output (good for piping)
```

## Replace (Preview Only)

```bash
rg -r "replacement" "pattern" # show what replacement would look like
```
