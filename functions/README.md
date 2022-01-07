Shell functions template:

```sh
function() {
  # function args can be accessed using
  # $1, $2, $3, etc. or $@ (for all)
  for arg in "$@"
  do
    "print $arg"
  done
}
```
