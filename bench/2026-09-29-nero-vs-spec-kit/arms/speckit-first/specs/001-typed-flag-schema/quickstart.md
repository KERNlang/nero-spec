# Validation guide

1. Instantiate each built-in flag without parsing, assert both optional interfaces and the [mapping contract](contracts/flag-schema.md).
2. Exercise inverse boolean and wrapped standard-library getters, including temporal, array, object, nil, and unsupported branches.
3. Run only targeted flag schema and nearby flag regression tests, under the assigned test lease.
4. Generate godoc with `GOMAXPROCS=2 go doc -all .`, refresh both snapshots, and check their equality.
5. Inspect diff, formatting, and task/spec coverage before handoff to independent review.
