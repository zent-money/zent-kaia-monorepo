export const ADDR = {
  ESCROW: process.env.NEXT_PUBLIC_ZENT_ESCROW as `0x${string}`,
  PAYLINK: process.env.NEXT_PUBLIC_ZENT_PAYLINK as `0x${string}`,
  KRWS: process.env.NEXT_PUBLIC_KRWS as `0x${string}`,
  EXPL: (process.env.NEXT_PUBLIC_EXPLORER as string) || "https://kairos.kaiascan.io",
};
