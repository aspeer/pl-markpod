# INSTALLATION INSTRUCTIONS #

git clone https://github.com/aspeer/pl-markpod
cd pl-markpod

# If on a modern system
`cpan .`

# Or
`cpanm .`

# Failing that. Dependencies will have to be installed manaually.
```
perl Makefile.PL
make
make test
make install
```