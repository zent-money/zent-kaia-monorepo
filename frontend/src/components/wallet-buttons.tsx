"use client";
import { useEffect, useState } from "react";
import { Button } from "semantic-ui-react";
import { connectKaiaWallet, connectKlip, Connected } from "@/lib/kaia";

export function WalletButtons() {
  const [conn, setConn] = useState<Connected|null>(null);
  useEffect(()=>{
    const cached = sessionStorage.getItem("zent-wallet");
    if (cached==="kaia") connectKaiaWallet().then(setConn).catch(()=>{});
    if (cached==="klip") connectKlip().then(setConn).catch(()=>{});
  },[]);
  if (conn) {
    const label = `${conn.type.toUpperCase()} · ${conn.address.slice(0,6)}…${conn.address.slice(-4)}`;
    return <Button color="blue" onClick={()=>{ setConn(null); sessionStorage.removeItem("zent-wallet"); }}>{label} (disconnect)</Button>;
  }
  return (
    <>
      <Button color="blue" onClick={async()=>{ const c=await connectKaiaWallet(); setConn(c); sessionStorage.setItem("zent-wallet","kaia"); }}>Connect KAIA Wallet</Button>
      <Button color="blue" onClick={async()=>{ const c=await connectKlip(); setConn(c); sessionStorage.setItem("zent-wallet","klip"); }}>Connect Klip</Button>
    </>
  );
}
