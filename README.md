# compilers_project

### Compilation

#### Lex

```bash
flex -l flex.lex
```

#### Yacc

```bash
yacc yacc.y -d -v
```

### Program compilation

```bash
gcc y.tab.c -o program.out -ly
```

### Program execution

```bash
chmod +x program.out
./program.out
```
