"use client";
import Link from "next/link";
import { Button, Container, Icon } from "semantic-ui-react";
import { ADDR } from "@/lib/addr";
import { LottieHero } from "@/components/LottieHero";

export default function Home() {
  return (
    <Container>
      <section className="hero" style={{ display:"grid", gridTemplateColumns:"1.2fr 1fr", gap:24, alignItems:"center" }}>
        <div>
          <span className="badge"><Icon name="lightning" /> Magic Link Payments</span>
          <h1>Zent — 링크만으로 KRWS를 보내고 받는 결제 · 인보이스</h1>
          <p>
            이메일/링크만으로 결제·송금이 가능한 KRW 스테이블코인(테스트: KRWS) 플랫폼.
            KYC/세무 자동화, 결제 링크(Zent Link)와 송금 패스(Zent Pass)를 지원합니다.
          </p>
          <div className="cta">
            <Button as={Link} href="/toss" color="blue" size="large">Send via Toss</Button>
            <Button as={Link} href="/invoice" basic color="blue" size="large">Create Invoice</Button>
          </div>
        </div>
        <div style={{ justifySelf:"end" }}>
          <LottieHero />
        </div>
      </section>

      <section style={{marginTop:32}}>
        <div className="features">
          <div className="feature">
            <h3><Icon name="send" /> Magic Link Transfer</h3>
            <p>주소 없이 링크로 송금/수령. 해시락 기반 안전한 에스크로(Zent Pass).</p>
          </div>
          <div className="feature">
            <h3><Icon name="file alternate" /> Magic Link Invoice</h3>
            <p>클릭 한 번으로 결제 가능한 인보이스(Zent Link). 고정/가변 금액 지원.</p>
          </div>
          <div className="feature">
            <h3><Icon name="check circle" /> Tax & Accounting</h3>
            <p>트랜잭션 기록을 바탕으로 정산 보조(추후). 리포트/다운로드 준비중.</p>
          </div>
        </div>
      </section>

      <section style={{marginTop:32}}>
        <div className="features">
          <div className="feature">
            <h3><Icon name="shield" /> KYC & Access</h3>
            <p>구글 로그인 시작 → 카카오페이 본인인증(추후 목표) → 사용권한 확장.</p>
          </div>
          <div className="feature">
            <h3><Icon name="globe" /> KAIA · Kairos Testnet</h3>
            <p>KAIA Kairos(1001)에 배포. KRWS(6d)로 승인 후 결제/송금 하세요.</p>
          </div>
          <div className="feature">
            <h3><Icon name="external" /> Open App</h3>
            <p>바로 사용하려면 상단 메뉴에서 Send via Toss / Invoice로 이동하세요.</p>
          </div>
        </div>
      </section>

      <footer className="footer">
        <div>Contact: <a href="mailto:hello@zent.money">hello@zent.money</a> · Explorer: <a href={process.env.NEXT_PUBLIC_EXPLORER || "https://kairos.kaiascan.io"} target="_blank">Kaiascan</a></div>
        <div style={{marginTop:4}}>Contracts — Escrow: {ADDR.ESCROW || "N/A"} · PayLink: {ADDR.PAYLINK || "N/A"} · KRWS: {ADDR.KRWS || "N/A"}</div>
      </footer>
    </Container>
  );
}
