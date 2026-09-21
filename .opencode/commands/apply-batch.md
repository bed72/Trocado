---
description: Apply or approve exactly one review-gated OpenSpec implementation batch.
agent: build
---

Load and follow the `trocado-batched-delivery` skill for `$ARGUMENTS`.

Accepted forms:

```text
/apply-batch <change>
/apply-batch <change> <batch-number>
/apply-batch <change> approve <batch-number>
```

Without `approve`, apply only the earliest eligible batch, or verify that the requested batch is the earliest eligible one. With `approve`, require that the specified batch is already `AWAITING_REVIEW`, change only its state to `APPROVED`, and stop.

Never implement more than one batch, infer human approval, approve and continue in the same execution, or exceed the 20-file budget without an explicit pre-implementation exception from the user.
