"use client";
import { useEffect, useState } from "react";
import { useParams } from "next/navigation";
import { Contract, utils } from "ethers";
import { Button, Segment, Header, Message } from "semantic-ui-react";
import { ADDR } from "@/lib/addr";
import { ABI_ESCROW, ABI_ERC20 } from "@/lib/abi";
import { ensureConnected } from "@/lib/session";

export default function TossDetail() {
  const { id } = useParams<{id:string}>();
  const [me, setMe] = useState<string>("");
  const [data, setData] = useState<any>(null);
  const [decimals, setDecimals] = useState<number>(6);
  const [secret, setSecret] = useState<string>("");

  useEffect(()=>{ (async()=>{
    try {
      const c = await ensureConnected();
      setMe(c.address);
      const erc20 = new Contract(ADDR.KRWS, ABI_ERC20, c.web3);
      setDecimals(await erc20.decimals());
      const esc = new Contract(ADDR.ESCROW, ABI_ESCROW, c.web3);
      setData(await esc.getPass(id));
      const s = localStorage.getItem(`zent:pass:secret:${c.address}`) || "";
      setSecret(s);
    } catch (e:any) { alert(e?.message || "Init failed"); }
  })(); }, [id]);

  if (!data) return null;

  const isOwner = data.sender?.toLowerCase() === me.toLowerCase();
  const expired = Number(data.expiry) < Math.floor(Date.now()/1000);
  const claimed = data.claimedBy && data.claimedBy !== "0x0000000000000000000000000000000000000000";
  const refunded = !!data.refunded;

  const claim = async () => {
    if (!secret) return alert("Secret 필요");
    const c = await ensureConnected();
    const esc = new Contract(ADDR.ESCROW, ABI_ESCROW, c.web3.getSigner());
    const recv = "0x0000000000000000000000000000000000000000";
    await esc.claimPass(id, utils.toUtf8Bytes(secret), recv);
    alert("Claim sent");
  };

  const refund = async () => {
    if (!isOwner) return alert("Creator only");
    if (!expired) return alert("만료 후 환불 가능");
    const c = await ensureConnected();
    const esc = new Contract(ADDR.ESCROW, ABI_ESCROW, c.web3.getSigner());
    await esc.refundPass(id);
    alert("Refund sent");
  };

  return (
    <div className="z-card grid gap-4">
      <Header as="h2" color="blue">Toss #{id}</Header>
      <Segment>
        <div>Sender: {data.sender}</div>
        <div>Amount: {Number(data.amount)/10**decimals} KRWS</div>
        <div>Expiry: {new Date(Number(data.expiry)*1000).toLocaleString()}</div>
        <div>ClaimedBy: {data.claimedBy}</div>
        <div>Refunded: {refunded ? "Yes" : "No"}</div>
      </Segment>
      {!claimed && !refunded && (
        <Segment>
          {!isOwner && (
            <>
              <Header as="h4">받기(Claim)</Header>
              <Button color="blue" onClick={claim}>Claim with my secret</Button>
            </>
          )}
          {isOwner && (
            <>
              <Header as="h4">환불(만료 후)</Header>
              <Button color="blue" disabled={!expired} onClick={refund}>Refund</Button>
            </>
          )}
        </Segment>
      )}
      {(claimed || refunded) && <Message info content="이미 처리된 Toss 입니다."/>}
    </div>
  );
}
