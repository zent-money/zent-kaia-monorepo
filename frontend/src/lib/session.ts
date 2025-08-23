import { connectKaiaWallet, connectKlip, Connected } from "@/lib/kaia";

export async function ensureConnected(): Promise<Connected> {
  const cached = typeof window !== "undefined" ? sessionStorage.getItem("zent-wallet") : null;
  if (cached === "kaia") return await connectKaiaWallet();
  if (cached === "klip") return await connectKlip();
  throw new Error("지갑이 연결되어 있지 않습니다. 우측 상단에서 연결해주세요.");
}
