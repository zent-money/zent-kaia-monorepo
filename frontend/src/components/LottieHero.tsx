"use client";
import dynamic from "next/dynamic";
import { useEffect, useState } from "react";

const Lottie = dynamic(() => import("lottie-react"), { ssr: false });

export default function LottieHero() {
  const [data, setData] = useState<any>(null);

  useEffect(() => {
    let mounted = true;
    (async () => {
      const res = await fetch("/anim/hero-pulse.json");
      if (!res.ok) return;
      const json = await res.json();
      if (mounted) setData(json);
    })();
    return () => { mounted = false; };
  }, []);

  if (!data) {
    // reduced-motion or 로딩중일 때 정적 플레이스홀더
    return (
      <div
        style={{
          width: 320, height: 320, borderRadius: 24,
          background:
            "radial-gradient(50% 50% at 50% 50%, rgba(37,99,235,0.10) 0%, rgba(37,99,235,0.04) 60%, transparent 100%)",
          border: "1px solid #e7eefc"
        }}
        aria-label="Animation placeholder"
      />
    );
  }

  return (
    <Lottie
      animationData={data}
      loop
      autoplay
      style={{ width: 320, height: 320, filter: "drop-shadow(0 12px 30px rgba(37,99,235,0.18))" }}
      rendererSettings={{ preserveAspectRatio: "xMidYMid meet" }}
    />
  );
}
