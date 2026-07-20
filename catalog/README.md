# Catalog

Canonical translation sources for SComm (typically ARB or JSON keyed like the
application English catalog).

Place locale files here as they are contributed, for example:

```text
catalog/
  app_en.arb          # optional mirror of canonical English
  app_de.arb
  app_ja.arb
  …
```

Built `.scomm-langpack.zip` files must **not** be committed here; publish them
via GitHub Releases.
