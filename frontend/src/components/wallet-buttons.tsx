"use client";
import { useEffect, useState } from "react";
import { Button } from "semantic-ui-react";
import { connectKaiaWallet, connectKlip, Connected } from "@/lib/kaia";

/**
 * Header-only wallet control:
 * - Disconnected: "Connect KAIA Wallet" / "Connect Klip"
 * - Connected: shows "<TYPE> · 0x1234…abcd" as a single blue button
 *   Clicking asks confirm("Would you disconnect?") then clears session and state.
 */
export function WalletButtons() {
  const [conn, setConn] = useState<Connected | null>(null);

  // Try auto-reconnect based on last used wallet
  useEffect(() => {
    const cached = typeof window !== "undefined" ? sessionStorage.getItem("zent-wallet") : null;
    (async () => {
      try {
        if (cached === "kaia") setConn(await connectKaiaWallet());
        if (cached === "klip") setConn(await connectKlip());
      } catch {
        // ignore auto-reconnect errors
        sessionStorage.removeItem("zent-wallet");
        setConn(null);
      }
    })();
  }, []);

  const disconnect = () => {
    // Some injected providers don't expose an explicit disconnect; clear our state + cache.
    sessionStorage.removeItem("zent-wallet");
    setConn(null);
  };

  if (conn) {
    const label = `${conn.type.toUpperCase()} · ${conn.address.slice(0, 6)}…${conn.address.slice(-4)}`;
    return (
      <Button
        color="blue"
        onClick={() => {
          if (confirm("Would you disconnect?")) disconnect();
        }}
      >
        {label}
      </Button>
    );
  }

  return (
    <>
      <Button
        color="blue"
        onClick={async () => {
          try {
            const c = await connectKaiaWallet();
            setConn(c);
            sessionStorage.setItem("zent-wallet", "kaia");
          } catch (e) {
            alert((e as Error).message || "Failed to connect KAIA Wallet");
          }
        }}
      >
        Connect KAIA Wallet
      </Button>
      <Button
        color="blue"
        onClick={async () => {
          try {
            const c = await connectKlip();
            setConn(c);
            sessionStorage.setItem("zent-wallet", "klip");
          } catch (e) {
            alert((e as Error).message || "Failed to connect Klip");
          }
        }}
      >
        Connect Klip
      </Button>
    </>
  );
}
