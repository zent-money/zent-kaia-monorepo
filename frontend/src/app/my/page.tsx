"use client";
import { useEffect, useState } from "react";
import { Header, Segment, Message } from "semantic-ui-react";
import { ensureConnected } from "@/lib/session";

export default function MyPage() {
  const [me, setMe] = useState<string>("");
  const [secret, setSecret] = useState<string>("");

  useEffect(()=>{ (async()=>{
    try {
      const c = await ensureConnected();
      setMe(c.address);
      setSecret(localStorage.getItem(`zent:pass:secret:${c.address}`) || "");
    } catch {}
  })(); }, []);

  return (
    <div className="grid gap-4">
      <Header as="h2" color="blue">My</Header>
      <Segment>
        <div>Address: {me || "지갑 미연결"}</div>
        {secret ? <Message info content={`최근 내가 만든 Toss의 secret: ${secret}`}/> : <div className="text-sm opacity-70">최근 Secret 없음</div>}
        <div className="text-sm opacity-70">* 실제 내 소유 목록은 이벤트 인덱싱 후 제공 예정</div>
      </Segment>
    </div>
  );
}
