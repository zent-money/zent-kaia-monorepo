# Zent Dashboard (frontend)

```
cp .env.local.example .env.local
# Fill NEXT_PUBLIC_* addresses (KRWS, ESCROW, PAYLINK)
pnpm -C frontend dev
```

Flow:
- Link: faucet → approve → createInvoice → (ID 확인) → pay/close
- Pass: decimals → secret/hash → approve → createPass → claim/refund
