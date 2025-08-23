// client-only helpers for KAIA Wallet (window.klaytn) & Klip
import { Web3Provider, JsonRpcProvider } from "@kaiachain/ethers-ext";

export const KAIROS = {
  rpc: process.env.NEXT_PUBLIC_KAIROS_RPC || "https://public-en-kairos.node.kaia.io",
  chainId: Number(process.env.NEXT_PUBLIC_CHAIN_ID || 1001),
};

export type Connected = { type: "kaia" | "klip"; address: string; web3: Web3Provider };

function isClient() { return typeof window !== "undefined"; }

async function ensureKairos(provider:any) {
  try {
    await provider.request?.({ method: "wallet_switchKlaytnChain", params: [{ chainId: "0x3E9" }] });
  } catch {}
  try {
    const netVersion = await provider.request?.({ method: "net_version" });
    const chainId = Number(netVersion);
    if (chainId !== KAIROS.chainId) {
      console.warn("Not on Kairos. Expected 1001, got", chainId);
    }
  } catch {}
}

export async function connectKaiaWallet(): Promise<Connected> {
  if (!isClient()) throw new Error("Client only");
  const w: any = window as any;
  const provider = w.klaytn as any;
  if (!provider) throw new Error("Kaia Wallet not detected");
  let accounts: string[] = [];
  try {
    accounts = await provider.request({ method: "kaia_requestAccounts" });
  } catch {
    accounts = await provider.enable();
  }
  await ensureKairos(provider);
  const web3 = new Web3Provider(provider, "any");
  const addr = (accounts?.[0] || (await web3.getSigner().getAddress())).toLowerCase();
  provider.on?.("accountsChanged", () => { sessionStorage.removeItem("zent-wallet"); location.reload(); });
  provider.on?.("networkChanged", () => { location.reload(); });
  return { type: "kaia", address: addr, web3 };
}

export async function connectKlip(): Promise<Connected> {
  if (!isClient()) throw new Error("Client only");
  const { KlipWeb3Provider } = await import("@klaytn/klip-web3-provider");
  const klip = new KlipWeb3Provider({});
  await klip.enable();
  const web3 = new Web3Provider(klip as any, "any");
  const addr = (await web3.getSigner().getAddress()).toLowerCase();
  return { type: "klip", address: addr, web3 };
}

export function getPublicProvider() {
  return new JsonRpcProvider(KAIROS.rpc);
}
