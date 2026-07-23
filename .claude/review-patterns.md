# Ponytail review patterns

Recurring over-engineering findings, newest last.

- 2026-07-23 · calibre.sh · yagni · wrapper function reduced to a single stdlib/system call after its original justification (a portability shim, error handling) was simplified away, but the wrapper itself was left in place — inline the call at each site and delete the wrapper
