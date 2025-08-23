import { Web3Provider, JsonRpcProvider } from "@kaiachain/ethers-ext";

export const KAIROS = {
  rpc: process.env.NEXT_PUBLIC_KAIROS_RPC || "https://public-en-kairos.node.kaia.io",
  chainId: Number(process.env.NEXT_PUBLIC_CHAIN_ID || 1001),
};

export type Connected = { type: "kaia" | "klip"; address: string; web3: Web3Provider };

type Eip1193Provider = {
  request?: (args: { method: string; params?: unknown[] }) => Promise<unknown>;
  enable?: () => Promise<string[]>;
};

export async function connectKaiaWallet(): Promise<Connected> {
  const win = window as Window & { klaytn?: Eip1193Provider };
  if (!win?.klaytn) throw new Error("Kaia Wallet not found");
  await win.klaytn.request?.({ method: "kaia_requestAccounts" }).catch(() => win.klaytn!.enable?.());
  const web3 = new Web3Provider(win.klaytn as unknown as { request: (args: { method: string; params?: unknown[] }) => Promise<unknown> }, "any");
  const addr = (await web3.getSigner().getAddress()).toLowerCase();
  return { type: "kaia", address: addr, web3 };
}

export async function connectKlip(): Promise<Connected> {
  // Dynamically import to avoid SSR referencing window or caver
  const { KlipWeb3Provider } = await import("@klaytn/klip-web3-provider");
  const klip = new KlipWeb3Provider({});
  await klip.enable();
  const web3 = new Web3Provider(klip as unknown as { request: (args: { method: string; params?: unknown[] }) => Promise<unknown> }, "any");
  const addr = (await web3.getSigner().getAddress()).toLowerCase();
  return { type: "klip", address: addr, web3 };
}

export function getPublicProvider() {
  return new JsonRpcProvider(KAIROS.rpc);
}
