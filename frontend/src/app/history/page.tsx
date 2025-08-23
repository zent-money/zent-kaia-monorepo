"use client";
import { useEffect, useState } from "react";
import { Header, Segment, Message } from "semantic-ui-react";

export default function History() {
  const [actor, setActor] = useState<string>("");
  useEffect(()=>{ setActor(localStorage.getItem("zent:lastActor") || ""); }, []);
  return (
    <div className="grid gap-4">
      <Header as="h2" color="blue">History</Header>
      <Segment>
        <Message info content={actor ? `최근 작업 지갑: ${actor}` : "최근 로컬 기록이 없습니다."}/>
        <div className="text-sm opacity-70">* 추후 이벤트 인덱싱으로 대체 예정</div>
      </Segment>
    </div>
  );
}
