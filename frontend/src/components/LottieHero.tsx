"use client";
import dynamic from "next/dynamic";
import { CSSProperties, useEffect, useMemo, useState } from "react";
import { useReducedMotion } from "./useReducedMotion";

// lottie-react is client-only; load dynamically
const Lottie = dynamic(() => import("lottie-react"), { ssr: false });

export function LottieHero({
  className,
  style
}: { className?: string; style?: CSSProperties }) {
  const reduced = useReducedMotion();

  // Avoid loading JSON until client
  const animSrc = useMemo(() => "/anim/hero-pulse.json", []);
  const [data, setData] = useState<any>(null);

  useEffect(() => {
    if (reduced) return;
    let active = true;
    (async () => {
      try {
        const res = await fetch(animSrc);
        if (!res.ok) return;
        const json = await res.json();
        if (active) setData(json);
      } catch {}
    })();
    return () => { active = false; };
  }, [animSrc, reduced]);

  return (
    <div className={className} style={{ width: 320, height: 320, ...style }}>
      {!reduced ? (
        data ? (
          <Lottie
            animationData={data}
            loop
            autoplay
            style={{ width: "100%", height: "100%", filter: "drop-shadow(0 12px 30px rgba(37,99,235,0.18))" }}
            rendererSettings={{ preserveAspectRatio: "xMidYMid meet" }}
          />
        ) : (
          <div
            style={{
              width: "100%", height: "100%", borderRadius: 24,
              background: "radial-gradient(50% 50% at 50% 50%, rgba(37,99,235,0.12) 0%, rgba(37,99,235,0.04) 60%, transparent 100%)",
              border: "1px solid #e7eefc"
            }}
            aria-label="Loading animation"
          />
        )
      ) : (
        <div
          style={{
            width: "100%", height: "100%", borderRadius: 24,
            background: "radial-gradient(50% 50% at 50% 50%, rgba(37,99,235,0.12) 0%, rgba(37,99,235,0.04) 60%, transparent 100%)",
            border: "1px solid #e7eefc"
          }}
          aria-label="Animation disabled due to reduced motion preference"
        />
      )}
    </div>
  );
}
