# compilers_project

### Compilation

#### Lex

```bash
flex -l flex.lex
```

#### Yacc

```bash
yacc yacc.y -d -v -k
```

### Program compilation

```bash
gcc y.tab.c -o program.out -ly
```

### Program execution

#### Interactive

```bash
./program.out
```

This will wait for some input, and will terminate as soon as `return <expression|/*empty*/>;` is typed.

#### File Analysis

```bash
./program.out <path_to_file>
```

See the *src/examples* directory for some demonstration files.
